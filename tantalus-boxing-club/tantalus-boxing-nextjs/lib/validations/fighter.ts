import { z } from 'zod'

export const matchmakingRequestSchema = z.object({
  preferredWeightClass: z.enum([
    'strawweight', 'flyweight', 'bantamweight', 'super_bantamweight', 'featherweight',
    'super_featherweight', 'lightweight', 'super_lightweight', 'welterweight', 'super_welterweight',
    'middleweight', 'super_middleweight', 'light_heavyweight', 'cruiserweight', 'heavyweight'
  ]).optional(),
  preferredTier: z.enum(['bronze', 'silver', 'gold', 'platinum', 'diamond']).optional(),
  maxDistance: z.number().min(0, 'Distance must be positive').max(1000, 'Distance cannot exceed 1000 miles').optional(),
  notes: z.string().max(500, 'Notes cannot exceed 500 characters').optional(),
})

export const fightRecordSchema = z.object({
  opponentName: z.string().min(2, 'Opponent name must be at least 2 characters').max(100, 'Opponent name too long'),
  result: z.enum(['Win', 'Loss', 'Draw'], {
    errorMap: () => ({ message: 'Result must be Win, Loss, or Draw' })
  }),
  method: z.enum([
    'Decision', 'TKO', 'KO', 'Submission', 'DQ', 'No Contest', 'Technical Decision'
  ]),
  round: z.number().min(1, 'Round must be at least 1').max(15, 'Round cannot exceed 15').optional(),
  date: z.string().refine((date) => {
    const fightDate = new Date(date)
    const today = new Date()
    return fightDate <= today
  }, 'Fight date cannot be in the future'),
  location: z.string().min(2, 'Location must be at least 2 characters').max(100, 'Location too long').optional(),
  weightClass: z.enum([
    'strawweight', 'flyweight', 'bantamweight', 'super_bantamweight', 'featherweight',
    'super_featherweight', 'lightweight', 'super_lightweight', 'welterweight', 'super_welterweight',
    'middleweight', 'super_middleweight', 'light_heavyweight', 'cruiserweight', 'heavyweight'
  ]),
  notes: z.string().max(1000, 'Notes cannot exceed 1000 characters').optional(),
})

export const tournamentSchema = z.object({
  name: z.string().min(3, 'Tournament name must be at least 3 characters').max(100, 'Tournament name too long'),
  description: z.string().max(1000, 'Description cannot exceed 1000 characters').optional(),
  weightClass: z.enum([
    'strawweight', 'flyweight', 'bantamweight', 'super_bantamweight', 'featherweight',
    'super_featherweight', 'lightweight', 'super_lightweight', 'welterweight', 'super_welterweight',
    'middleweight', 'super_middleweight', 'light_heavyweight', 'cruiserweight', 'heavyweight'
  ]),
  tier: z.enum(['bronze', 'silver', 'gold', 'platinum', 'diamond']),
  maxParticipants: z.number().min(4, 'Minimum 4 participants').max(64, 'Maximum 64 participants'),
  startDate: z.string().refine((date) => {
    const startDate = new Date(date)
    const today = new Date()
    return startDate >= today
  }, 'Start date must be in the future'),
  endDate: z.string().refine((date) => {
    const endDate = new Date(date)
    const today = new Date()
    return endDate >= today
  }, 'End date must be in the future'),
}).refine((data) => {
  const startDate = new Date(data.startDate)
  const endDate = new Date(data.endDate)
  return endDate > startDate
}, {
  message: 'End date must be after start date',
  path: ['endDate'],
})

export const trainingCampSchema = z.object({
  name: z.string().min(3, 'Camp name must be at least 3 characters').max(100, 'Camp name too long'),
  description: z.string().max(1000, 'Description cannot exceed 1000 characters').optional(),
  location: z.string().min(2, 'Location must be at least 2 characters').max(100, 'Location too long'),
  startDate: z.string().refine((date) => {
    const startDate = new Date(date)
    const today = new Date()
    return startDate >= today
  }, 'Start date must be in the future'),
  endDate: z.string().refine((date) => {
    const endDate = new Date(date)
    const today = new Date()
    return endDate >= today
  }, 'End date must be in the future'),
  maxParticipants: z.number().min(2, 'Minimum 2 participants').max(50, 'Maximum 50 participants'),
}).refine((data) => {
  const startDate = new Date(data.startDate)
  const endDate = new Date(data.endDate)
  return endDate > startDate
}, {
  message: 'End date must be after start date',
  path: ['endDate'],
})

export const trainingLogSchema = z.object({
  activity: z.string().min(2, 'Activity must be at least 2 characters').max(200, 'Activity too long'),
  durationMinutes: z.number().min(1, 'Duration must be at least 1 minute').max(300, 'Duration cannot exceed 300 minutes'),
  date: z.string().refine((date) => {
    const logDate = new Date(date)
    const today = new Date()
    return logDate <= today
  }, 'Log date cannot be in the future'),
  notes: z.string().max(1000, 'Notes cannot exceed 1000 characters').optional(),
})

export type MatchmakingRequestInput = z.infer<typeof matchmakingRequestSchema>
export type FightRecordInput = z.infer<typeof fightRecordSchema>
export type TournamentInput = z.infer<typeof tournamentSchema>
export type TrainingCampInput = z.infer<typeof trainingCampSchema>
export type TrainingLogInput = z.infer<typeof trainingLogSchema>

