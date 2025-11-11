export interface FighterProfile {
  id: string
  user_id: string
  name: string
  handle: string
  platform: 'PSN' | 'Xbox' | 'PC' | 'TBC'
  platform_id: string
  timezone: string
  height: number // cm
  weight: number // kg
  reach: number // cm
  age: number
  stance: 'Orthodox' | 'Southpaw' | 'Switch'
  nationality: string
  fighting_style: string
  hometown: string
  birthday: string
  trainer?: string
  gym?: string
  wins: number
  losses: number
  draws: number
  knockouts: number
  points: number
  tier: 'Amateur' | 'Semi-Pro' | 'Pro' | 'Contender' | 'Elite' | 'Champion'
  rank: number
  weight_class: string
  win_percentage: number
  ko_percentage: number
  current_streak: number
  longest_win_streak: number
  longest_loss_streak: number
  average_fight_duration: number
  last_20_results: any[]
  recent_form: any[]
  profile_photo_url?: string
  social_links: any[]
  created_at: string
  updated_at: string
  last_active: string
}

export interface FightRecord {
  id: string
  fighter_id: string
  opponent_name: string
  result: 'Win' | 'Loss' | 'Draw'
  method: 'UD' | 'SD' | 'MD' | 'KO' | 'TKO' | 'Submission' | 'DQ' | 'No Contest'
  round: number
  date: string
  weight_class: string
  points_earned: number
  proof_url?: string
  notes?: string
  created_at: string
}

export interface Tournament {
  id: string
  name: string
  description?: string
  start_date: string
  end_date: string
  weight_class: string
  max_participants: number
  current_participants: number
  entry_fee: number
  prize_pool: number
  status: 'upcoming' | 'active' | 'completed' | 'cancelled'
  created_by: string
  created_at: string
  updated_at: string
}

export interface Match {
  id: string
  fighter1_id: string
  fighter2_id: string
  scheduled_date: string
  weight_class: string
  status: 'scheduled' | 'completed' | 'cancelled'
  result?: 'fighter1_win' | 'fighter2_win' | 'draw'
  method?: string
  round?: number
  created_at: string
  updated_at: string
}

export interface Notification {
  id: string
  user_id: string
  type: 'Match' | 'Tournament' | 'Tier' | 'Dispute' | 'Award' | 'General' | 'fight_update' | 'tournament_update' | 'ranking_update' | 'dispute_update'
  title: string
  message: string
  read: boolean
  created_at: string
}

export interface MediaAsset {
  id: string
  user_id: string
  title: string
  description?: string
  file_url: string
  file_type: 'image' | 'video'
  category: 'highlight' | 'training' | 'interview' | 'promo'
  created_at: string
}

export interface Interview {
  id: string
  fighter_id: string
  interviewer: string
  title: string
  description?: string
  scheduled_date: string
  duration_minutes: number
  status: 'scheduled' | 'completed' | 'cancelled'
  recording_url?: string
  created_at: string
}

export interface PressConference {
  id: string
  title: string
  description?: string
  scheduled_date: string
  duration_minutes: number
  participants: string[]
  status: 'scheduled' | 'completed' | 'cancelled'
  recording_url?: string
  created_at: string
}

export interface SocialLink {
  id: string
  fighter_id: string
  platform: 'Twitter' | 'Instagram' | 'YouTube' | 'Twitch' | 'TikTok' | 'Facebook'
  url: string
  handle: string
  created_at: string
}

export interface TrainingCamp {
  id: string
  name: string
  description?: string
  start_date: string
  end_date: string
  location: string
  max_participants: number
  current_participants: number
  created_by: string
  status: 'upcoming' | 'active' | 'completed' | 'cancelled'
  created_at: string
}

export interface TrainingObjective {
  id: string
  camp_id: string
  title: string
  description?: string
  target_date: string
  status: 'pending' | 'in_progress' | 'completed'
  created_at: string
}

export interface TrainingLog {
  id: string
  fighter_id: string
  camp_id?: string
  objective_id?: string
  activity: string
  duration_minutes: number
  notes?: string
  date: string
  created_at: string
}

export interface User {
  id: string
  email: string
  full_name?: string
  role?: 'user' | 'admin' | 'moderator'
  created_at: string
  updated_at: string
}

export interface MatchmakingRequest {
  id: string
  fighter_id: string
  weight_class: string
  tier: string
  max_distance: number
  preferred_date?: string
  notes?: string
  status: 'pending' | 'matched' | 'cancelled'
  created_at: string
}

export interface TournamentParticipant {
  id: string
  tournament_id: string
  fighter_id: string
  joined_at: string
  fighter?: FighterProfile
}
