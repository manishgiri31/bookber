import { SOCKET_SYNC_DEFAULT_LIMIT } from "./socket.config.js";
import { socketAuthMiddleware } from "./socket.auth.js";
import { getMetrics } from "../../infrastructure/metrics/prometheus.js";
import { socketRooms } from "./socket.rooms.js";
const NODE_ID = `node-${process.pid}`;
export function attachSocketHandlers(app, nsp, journal, registry) {
    nsp.use((socket, next) => socketAuthMiddleware(app, socket, next));
    nsp.on("connection", (socket) => {
        void onConnect(app, socket, journal, registry);
        socket.on("room:subscribe", (payload) => {
            try {
                subscribeRooms(socket, payload);
                socket.emit("connection.state", { connected: true, reason: "subscribed" });
            }
            catch (error) {
                socket.emit("connection.state", {
                    connected: false,
                    reason: error instanceof Error ? error.message : "subscribe_failed"
                });
            }
        });
        socket.on("room:unsubscribe", (payload) => {
            unsubscribeRooms(socket, payload);
        });
        socket.on("sync:recover", (payload) => {
            void onSyncRecover(socket, journal, payload).catch((error) => {
                socket.emit("connection.state", {
                    connected: false,
                    reason: error instanceof Error ? error.message : "sync_failed"
                });
            });
        });
        socket.on("ping", () => {
            socket.data.lastPing = Date.now();
            void registry.touch(socket.id);
            socket.emit("heartbeat", {
                timestamp: Date.now(),
                serverTime: new Date().toISOString()
            });
        });
        socket.on("disconnect", (reason) => {
            void registry.unregister(socket.id, socket.data.user.userId);
            app.log.info({ socketId: socket.id, userId: socket.data.user.userId, reason }, "realtime socket disconnected");
        });
    });
}
async function onConnect(app, socket, journal, registry) {
    const user = socket.data.user;
    socket.data.lastPing = Date.now();
    socket.data.subscribedShops = new Set();
    socket.data.shopLastSeq = new Map();
    await registry.register({
        socketId: socket.id,
        userId: user.userId,
        namespace: socket.nsp.name,
        nodeId: NODE_ID
    });
    socket.join(socketRooms.user(user.userId));
    if (user.role === "ADMIN") {
        socket.join(socketRooms.admin());
    }
    for (const shopId of user.shopIds) {
        socket.join(socketRooms.shop(shopId));
        socket.data.subscribedShops.add(shopId);
    }
    socket.emit("socket.ready", {
        socketId: socket.id,
        userId: user.userId,
        serverTime: new Date().toISOString()
    });
    socket.emit("connection.state", { connected: true, reason: "connected" });
    app.log.info({ socketId: socket.id, userId: user.userId }, "realtime socket connected");
    getMetrics().socketConnections.set({ namespace: socket.nsp.name }, socket.nsp.server.engine.clientsCount);
}
function subscribeRooms(socket, payload) {
    const user = socket.data.user;
    const joined = [];
    if (payload.shopId) {
        assertShopAccess(user, payload.shopId);
        const room = socketRooms.shop(payload.shopId);
        void socket.join(room);
        socket.data.subscribedShops.add(payload.shopId);
        joined.push(room);
    }
    if (payload.barberId) {
        const room = socketRooms.barber(payload.barberId);
        void socket.join(room);
        joined.push(room);
    }
    if (payload.userId) {
        if (user.role !== "ADMIN" && payload.userId !== user.userId) {
            return;
        }
        const room = socketRooms.user(payload.userId);
        void socket.join(room);
        joined.push(room);
    }
}
function unsubscribeRooms(socket, payload) {
    if (payload.shopId) {
        void socket.leave(socketRooms.shop(payload.shopId));
        socket.data.subscribedShops.delete(payload.shopId);
    }
    if (payload.barberId)
        void socket.leave(socketRooms.barber(payload.barberId));
    if (payload.userId)
        void socket.leave(socketRooms.user(payload.userId));
}
async function onSyncRecover(socket, journal, payload) {
    const user = socket.data.user;
    assertShopAccess(user, payload.shopId);
    const shopRoom = socketRooms.shop(payload.shopId);
    await socket.join(shopRoom);
    socket.data.subscribedShops.add(payload.shopId);
    const [shopEvents, userEvents, currentShopSeq, currentUserSeq] = await Promise.all([
        journal.getShopEventsSince(payload.shopId, payload.lastEventSeq, SOCKET_SYNC_DEFAULT_LIMIT),
        payload.includeUserEvents
            ? journal.getUserEventsSince(user.userId, payload.lastUserEventSeq ?? 0, SOCKET_SYNC_DEFAULT_LIMIT)
            : Promise.resolve([]),
        journal.currentShopSeq(payload.shopId),
        journal.currentUserSeq(user.userId)
    ]);
    const merged = dedupeEnvelopes([...shopEvents, ...userEvents]).slice(0, SOCKET_SYNC_DEFAULT_LIMIT);
    for (const event of merged) {
        socket.emit(event.event, event);
    }
    socket.data.shopLastSeq.set(payload.shopId, currentShopSeq);
    socket.emit("sync.complete", {
        shopId: payload.shopId,
        currentShopSeq,
        currentUserSeq,
        missed: merged,
        resubscribedRooms: [shopRoom, socketRooms.user(user.userId)],
        serverTime: new Date().toISOString()
    });
    socket.emit("connection.state", { connected: true, reason: "reconnected" });
    socket.data.lastPing = Date.now();
}
function assertShopAccess(user, shopId) {
    if (user.role === "ADMIN" || user.role === "CLIENT")
        return;
    if (user.shopIds.includes(shopId))
        return;
    throw new Error("FORBIDDEN_SHOP");
}
function dedupeEnvelopes(events) {
    const map = new Map();
    for (const e of events) {
        map.set(e.eventId, e);
    }
    return [...map.values()].sort((a, b) => a.seq - b.seq);
}
