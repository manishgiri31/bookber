import type { FastifyInstance } from "fastify";
import type { Socket } from "socket.io";
import { env } from "../config/env.js";
import type { SocketData, SocketUser } from "./socket.types.js";

export async function socketAuthMiddleware(
  app: FastifyInstance,
  socket: Socket,
  next: (err?: Error) => void
) {
  try {
    const token =
      socket.handshake.auth?.["token"] ??
      socket.handshake.headers.authorization?.replace("Bearer ", "");
    if (!token) {
      throw new Error("UNAUTHENTICATED");
    }

    const payload = app.jwt.verify(token) as {
      sub: string;
      role: SocketUser["role"];
    };

    const shopIdsHeader = socket.handshake.auth?.["shopIds"];
    let shopIds =
      Array.isArray(shopIdsHeader)
        ? shopIdsHeader.map(String)
        : typeof shopIdsHeader === "string"
          ? shopIdsHeader.split(",").map((item: string) => item.trim()).filter(Boolean)
          : [];

    if (payload.role === "BARBER" && shopIds.length === 0) {
      const barber = await app.prisma.barber.findUnique({
        where: { userId: payload.sub },
        select: { shopId: true }
      });
      if (barber) shopIds = [barber.shopId];
    }

    const data: SocketData = {
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
  } catch (error) {
    next(error instanceof Error ? error : new Error("UNAUTHENTICATED"));
  }
}
