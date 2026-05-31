import { z } from "zod";
export const registerSchema = z.object({
    fullName: z.string().min(2).max(100),
    email: z.string().email(),
    phoneNumber: z.string().regex(/^\+?[1-9]\d{1,14}$/).optional(),
    password: z.string().min(8).max(72).regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, "Password must contain at least one uppercase letter, one lowercase letter, and one number"),
    role: z.enum(["CLIENT", "BARBER", "ADMIN"]).default("CLIENT")
});
export const loginSchema = z.object({
    identifier: z.string().min(3),
    password: z.string().min(1)
});
export const refreshSchema = z.object({
    refreshToken: z.string().min(20).optional()
});
export const logoutSchema = z.object({
    refreshToken: z.string().min(20).optional()
});
export const refreshCookiesSchema = z.object({
    refreshToken: z.string().min(20)
});
export const authHeaderSchema = z.object({
    authorization: z.string().startsWith("Bearer ").optional()
});
