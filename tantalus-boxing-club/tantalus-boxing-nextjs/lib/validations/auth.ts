import { z } from 'zod'

export const loginSchema = z.object({
  email: z.string().email('Invalid email address').min(1, 'Email is required'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
})

export const registerSchema = z.object({
  fullName: z.string().min(2, 'Full name must be at least 2 characters').max(100, 'Full name too long'),
  email: z.string().email('Invalid email address'),
  password: z.string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, 'Password must contain at least one lowercase letter, one uppercase letter, and one number'),
  confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ["confirmPassword"],
})

export const fighterProfileSchema = z.object({
  name: z.string().min(2, 'Fighter name must be at least 2 characters').max(50, 'Fighter name too long'),
  handle: z.string().min(2, 'Handle must be at least 2 characters').max(30, 'Handle too long').regex(/^[a-zA-Z0-9_]+$/, 'Handle can only contain letters, numbers, and underscores'),
  birthday: z.string().refine((date) => {
    const birthDate = new Date(date)
    const today = new Date()
    const age = today.getFullYear() - birthDate.getFullYear()
    return age >= 16 && age <= 50
  }, 'Age must be between 16 and 50 years'),
  hometown: z.string().min(2, 'Hometown must be at least 2 characters').max(100, 'Hometown too long'),
  stance: z.enum(['orthodox', 'southpaw', 'switch'], {
    message: 'Stance must be orthodox, southpaw, or switch'
  }),
  heightFeet: z.number().min(4, 'Height must be at least 4 feet').max(7, 'Height cannot exceed 7 feet'),
  heightInches: z.number().min(0, 'Inches must be 0 or more').max(11, 'Inches cannot exceed 11'),
  reach: z.number().min(50, 'Reach must be at least 50 inches').max(100, 'Reach cannot exceed 100 inches'),
  weight: z.number().min(100, 'Weight must be at least 100 lbs').max(400, 'Weight cannot exceed 400 lbs'),
  weightClass: z.enum([
    'strawweight', 'flyweight', 'bantamweight', 'super_bantamweight', 'featherweight',
    'super_featherweight', 'lightweight', 'super_lightweight', 'welterweight', 'super_welterweight',
    'middleweight', 'super_middleweight', 'light_heavyweight', 'cruiserweight', 'heavyweight'
  ]),
  trainer: z.string().min(2, 'Trainer name must be at least 2 characters').max(100, 'Trainer name too long').optional(),
  gym: z.string().min(2, 'Gym name must be at least 2 characters').max(100, 'Gym name too long').optional(),
})

export const passwordResetSchema = z.object({
  email: z.string().email('Invalid email address'),
})

export const passwordUpdateSchema = z.object({
  currentPassword: z.string().min(1, 'Current password is required'),
  newPassword: z.string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, 'Password must contain at least one lowercase letter, one uppercase letter, and one number'),
  confirmPassword: z.string(),
}).refine((data) => data.newPassword === data.confirmPassword, {
  message: "Passwords don't match",
  path: ["confirmPassword"],
})

export type LoginInput = z.infer<typeof loginSchema>
export type RegisterInput = z.infer<typeof registerSchema>
export type FighterProfileInput = z.infer<typeof fighterProfileSchema>
export type PasswordResetInput = z.infer<typeof passwordResetSchema>
export type PasswordUpdateInput = z.infer<typeof passwordUpdateSchema>

