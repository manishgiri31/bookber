export async function socketAuthMiddleware(app, socket, next) {
    try {
        const token = socket.handshake.auth?.["token"] ??
            socket.handshake.headers.authorization?.replace("Bearer ", "");
        if (!token) {
            throw new Error("UNAUTHENTICATED");
        }
        const payload = app.jwt.verify(token);
        const shopIdsHeader = socket.handshake.auth?.["shopIds"];
        let shopIds = Array.isArray(shopIdsHeader)
            ? shopIdsHeader.map(String)
            : typeof shopIdsHeader === "string"
                ? shopIdsHeader.split(",").map((item) => item.trim()).filter(Boolean)
                : [];
        if (payload.role === "BARBER" && shopIds.length === 0) {
            const barber = await app.prisma.barber.findUnique({
                where: { userId: payload.sub },
                select: { shopId: true }
            });
            if (barber)
                shopIds = [barber.shopId];
        }
        const data = {
            user: {
                userId: payload.sub,
                role: payload.role,
                shopIds
            },
            lastPing: Date.now(),
            subscribedShops: new Set(),
            shopLastSeq: new Map()
        };
        socket.data = data;
        next();
    }
    catch (error) {
        next(error instanceof Error ? error : new Error("UNAUTHENTICATED"));
    }
}
