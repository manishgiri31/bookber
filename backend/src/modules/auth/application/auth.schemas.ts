import { z } from "zod";

const COMMON_PASSWORDS = new Set([
  "password", "1234", "12345", "123456", "1234567", "12345678", "12345678",
  "password1", "qwerty", "abc123", "letmein", "welcome", "monkey",
  "dragon", "master", "admin", "login", "pass", "test", "guest",
  "iloveyou", "sunshine", "princess", "football", "charlie", "donald",
  "superman", "batman", "shadow", "baseball", "access", "hello",
]);

export const registerSchema = z.object({
  fullName: z.string().min(2).max(100),
  email: z.string().email(),
  phoneNumber: z.string().regex(/^\+?[1-9]\d{1,14}$/).optional(),
  password: z.string()
    .refine(p => p.trim().length > 0, "Password cannot be empty or whitespace")
    .refine(p => !COMMON_PASSWORDS.has(p.toLowerCase()), "Password is too common, please choose another"),
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

export const updateProfileSchema = z.object({
  phoneNumber: z.string().regex(/^\+?[1-9]\d{1,14}$/).optional().nullable(),
  fullName: z.string().min(2).max(100).optional(),
});

export type RegisterDto = z.infer<typeof registerSchema>;
export type LoginDto = z.infer<typeof loginSchema>;
export type RefreshDto = z.infer<typeof refreshSchema>;
export type LogoutDto = z.infer<typeof logoutSchema>;
export type UpdateProfileDto = z.infer<typeof updateProfileSchema>;
