import type { UserRole } from "@prisma/client";

export type AuthUser = {
  id: string;
  fullName: string;
  email: string;
  phoneNumber: string | null;
  role: UserRole;
  profileImage: string | null;
};

export type TokenPair = {
  accessToken: string;
  refreshToken: string;
  refreshJti: string;
  refreshFamilyId: string;
  sessionId: string;
};

export type AccessTokenClaims = {
  sub: string;
  role: UserRole;
  jti: string;
  sid: string;
};

export type RefreshTokenClaims = {
  sub: string;
  jti: string;
  sid: string;
  fam: string;
};

export type AuthSession = {
  userId: string;
  familyId: string;
  refreshJti: string;
  role: UserRole;
};
