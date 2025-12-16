import { z } from 'zod';

// Email validation schema
export const emailSchema = z
  .string()
  .min(1, 'Email is required')
  .email('Invalid email format')
  .max(255, 'Email is too long');

// Password validation schema
export const passwordSchema = z
  .string()
  .min(8, 'Password must be at least 8 characters long')
  .max(128, 'Password is too long')
  .regex(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/,
    'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'
  );

// MFA code validation schema
export const mfaCodeSchema = z
  .string()
  .length(6, 'MFA code must be exactly 6 digits')
  .regex(/^\d{6}$/, 'MFA code must contain only digits');

// Login form validation schema
export const loginSchema = z.object({
  email: emailSchema,
  password: z.string().min(1, 'Password is required'),
  mfaCode: mfaCodeSchema.optional(),
});

// Register form validation schema
export const registerSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  confirmPassword: z.string(),
  firstName: z
    .string()
    .min(1, 'First name is required')
    .max(100, 'First name is too long')
    .regex(/^[a-zA-Z\s-']+$/, 'First name contains invalid characters'),
  lastName: z
    .string()
    .min(1, 'Last name is required')
    .max(100, 'Last name is too long')
    .regex(/^[a-zA-Z\s-']+$/, 'Last name contains invalid characters'),
  phone: z
    .string()
    .optional()
    .refine(
      (val) => !val || /^\+?[\d\s\-\(\)]{10,15}$/.test(val),
      'Invalid phone number format'
    ),
}).refine(
  (data) => data.password === data.confirmPassword,
  {
    message: "Passwords don't match",
    path: ["confirmPassword"],
  }
);

// Password reset request schema
export const passwordResetRequestSchema = z.object({
  email: emailSchema,
});

// Password reset confirmation schema
export const passwordResetConfirmSchema = z.object({
  token: z.string().min(1, 'Reset token is required'),
  password: passwordSchema,
  confirmPassword: z.string(),
}).refine(
  (data) => data.password === data.confirmPassword,
  {
    message: "Passwords don't match",
    path: ["confirmPassword"],
  }
);

// Change password schema
export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, 'Current password is required'),
  newPassword: passwordSchema,
  confirmPassword: z.string(),
}).refine(
  (data) => data.newPassword === data.confirmPassword,
  {
    message: "Passwords don't match",
    path: ["confirmPassword"],
  }
);

// Type exports
export type LoginFormData = z.infer<typeof loginSchema>;
export type RegisterFormData = z.infer<typeof registerSchema>;
export type PasswordResetRequestData = z.infer<typeof passwordResetRequestSchema>;
export type PasswordResetConfirmData = z.infer<typeof passwordResetConfirmSchema>;
export type ChangePasswordData = z.infer<typeof changePasswordSchema>;