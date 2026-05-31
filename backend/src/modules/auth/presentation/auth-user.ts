import type { FastifyRequest } from "fastify";
import type { UserRole } from "@prisma/client";
import type { AuthUser } from "../domain/auth.types.js";

export type AccessTokenPayload = {
  sub: string;
  role: UserRole;
  jti: string;
  sid?: string;
};

export function getAuthUser(request: FastifyRequest): AuthUser {
  const tokenUser = request.user as AccessTokenPayload;
  return {
    id: tokenUser.sub,
    fullName: "",
    email: "",
    phoneNumber: null,
    role: tokenUser.role,
    profileImage: null
  };
}

export function getAuthUserFromDb(
  tokenUser: AccessTokenPayload,
  user: Pick<AuthUser, "fullName" | "email" | "phoneNumber" | "profileImage">
): AuthUser {
  return {
    id: tokenUser.sub,
    fullName: user.fullName,
    email: user.email,
    phoneNumber: user.phoneNumber,
    role: tokenUser.role,
    profileImage: user.profileImage
  };
}
