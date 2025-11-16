import { z } from 'zod'

export const userRoleUpdateSchema = z.object({
  userId: z.string().uuid('Invalid user ID'),
  role: z.enum(['user', 'moderator', 'admin'], {
    message: 'Role must be user, moderator, or admin'
  }),
})

export const userSuspensionSchema = z.object({
  userId: z.string().uuid('Invalid user ID'),
  reason: z.string().min(10, 'Reason must be at least 10 characters').max(500, 'Reason cannot exceed 500 characters'),
  duration: z.number().min(1, 'Duration must be at least 1 day').max(365, 'Duration cannot exceed 365 days').optional(),
})

export const disputeSchema = z.object({
  title: z.string().min(5, 'Title must be at least 5 characters').max(200, 'Title cannot exceed 200 characters'),
  description: z.string().min(20, 'Description must be at least 20 characters').max(2000, 'Description cannot exceed 2000 characters'),
  category: z.enum(['fight_result', 'points', 'behavior', 'technical', 'other'], {
    message: 'Category must be fight_result, points, behavior, technical, or other'
  }),
  relatedFightId: z.string().uuid('Invalid fight ID').optional(),
})

export const disputeResolutionSchema = z.object({
  disputeId: z.string().uuid('Invalid dispute ID'),
  resolution: z.enum(['upheld', 'dismissed', 'partial', 'pending_investigation'], {
    message: 'Resolution must be upheld, dismissed, partial, or pending_investigation'
  }),
  adminNotes: z.string().max(1000, 'Admin notes cannot exceed 1000 characters').optional(),
})

export const systemSettingsSchema = z.object({
  maintenanceMode: z.boolean(),
  registrationEnabled: z.boolean(),
  maxFightersPerTournament: z.number().min(4, 'Minimum 4 fighters').max(64, 'Maximum 64 fighters'),
  pointsPerWin: z.number().min(1, 'Minimum 1 point').max(100, 'Maximum 100 points'),
  maxFileSize: z.number().min(1, 'Minimum 1MB').max(100, 'Maximum 100MB').optional(),
  allowedFileTypes: z.array(z.string()).optional(),
})

export const mediaUploadSchema = z.object({
  title: z.string().min(3, 'Title must be at least 3 characters').max(100, 'Title cannot exceed 100 characters'),
  description: z.string().max(500, 'Description cannot exceed 500 characters').optional(),
  category: z.enum(['highlight', 'training', 'interview', 'promo'], {
    message: 'Category must be highlight, training, interview, or promo'
  }),
  file: z.instanceof(File, { message: 'File is required' })
    .refine((file) => file.size <= 50 * 1024 * 1024, 'File size must be less than 50MB')
    .refine((file) => {
      const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'video/mp4', 'video/webm', 'video/quicktime']
      return allowedTypes.includes(file.type)
    }, 'File type not supported'),
})

export const interviewSchema = z.object({
  interviewer: z.string().min(2, 'Interviewer name must be at least 2 characters').max(100, 'Interviewer name too long'),
  title: z.string().min(3, 'Title must be at least 3 characters').max(200, 'Title cannot exceed 200 characters'),
  description: z.string().max(1000, 'Description cannot exceed 1000 characters').optional(),
  scheduledDate: z.string().refine((date) => {
    const interviewDate = new Date(date)
    const today = new Date()
    return interviewDate >= today
  }, 'Interview date must be in the future'),
  durationMinutes: z.number().min(15, 'Minimum 15 minutes').max(120, 'Maximum 120 minutes'),
})

export type UserRoleUpdateInput = z.infer<typeof userRoleUpdateSchema>
export type UserSuspensionInput = z.infer<typeof userSuspensionSchema>
export type DisputeInput = z.infer<typeof disputeSchema>
export type DisputeResolutionInput = z.infer<typeof disputeResolutionSchema>
export type SystemSettingsInput = z.infer<typeof systemSettingsSchema>
export type MediaUploadInput = z.infer<typeof mediaUploadSchema>
export type InterviewInput = z.infer<typeof interviewSchema>

