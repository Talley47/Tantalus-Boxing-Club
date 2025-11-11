// Core Types for Tantalus Boxing Club

export interface User {
  id: string;
  email: string;
  username: string;
  role: 'Fighter' | 'Promoter' | 'Admin';
  created_at: string;
  updated_at: string;
  is_active: boolean;
}

export interface FighterProfile {
  id: string;
  user_id: string;
  name: string;
  handle: string;
  platform: 'PSN' | 'Xbox' | 'PC';
  platform_id: string;
  timezone: string;
  
  // Physical attributes
  height?: number; // inches (deprecated, use height_feet and height_inches)
  height_feet?: number; // feet
  height_inches?: number; // inches
  weight: number; // pounds
  reach: number; // inches
  age?: number;
  stance: 'orthodox' | 'southpaw' | 'switch' | 'Orthodox' | 'Southpaw' | 'Switch';
  nationality: string;
  fighting_style: string;
  hometown: string;
  birthday?: string;
  trainer?: string;
  gym?: string;
  
  // Record and stats
  wins: number;
  losses: number;
  draws: number;
  knockouts: number;
  points: number;
  tier: 'Amateur' | 'Semi-Pro' | 'Pro' | 'Contender' | 'Elite' | 'bronze' | 'silver' | 'gold' | 'platinum' | 'diamond' | 'amateur' | 'semi-pro' | 'contender' | 'elite' | 'champion';
  rank?: number;
  weight_class: string;
  
  // Advanced stats
  win_percentage?: number;
  ko_percentage?: number;
  current_streak?: number;
  longest_win_streak?: number;
  longest_loss_streak?: number;
  average_fight_duration?: number;
  
  // Recent performance
  last_20_results?: FightRecord[];
  recent_form?: string[]; // Last 5 results as W/L/D
  
  // Social and media
  profile_photo_url?: string;
  social_links?: SocialLink[];
  
  // Timestamps
  created_at: string;
  updated_at: string;
  last_active: string;
}

export interface FightRecord {
  id: string;
  fighter_id: string;
  opponent_name: string;
  result: 'Win' | 'Loss' | 'Draw';
  method: 'UD' | 'SD' | 'MD' | 'KO' | 'TKO' | 'Submission' | 'DQ' | 'No Contest';
  round: number;
  date: string;
  weight_class: string;
  points_earned: number;
  proof_url?: string;
  notes?: string;
  created_at: string;
}

// Removed duplicate SocialLink interface

export interface Ranking {
  id: string;
  fighter_id: string;
  weight_class: string;
  rank: number;
  points: number;
  tier: string;
  win_percentage: number;
  ko_percentage: number;
  recent_form: string;
  updated_at: string;
}

export interface Tier {
  name: 'Amateur' | 'Semi-Pro' | 'Pro' | 'Contender' | 'Elite';
  min_points: number;
  max_points: number;
  color: string;
  benefits: string[];
}

export interface TierHistory {
  id: string;
  fighter_id: string;
  from_tier: string;
  to_tier: string;
  reason: string;
  created_at: string;
}

export interface MediaAsset {
  id: string;
  fighter_id: string;
  title: string;
  description: string;
  type: 'video' | 'photo';
  file_url: string;
  tags: string[];
  views: number;
  likes: number;
  created_at: string;
}

export interface Interview {
  id: string;
  fighter_id: string;
  title: string;
  description: string;
  scheduled_date: string;
  interviewer: string;
  platform: string;
  status: 'Scheduled' | 'Completed' | 'Cancelled';
  created_at: string;
}

export interface PressConference {
  id: string;
  fighter_id: string;
  title: string;
  description: string;
  scheduled_date: string;
  location: string;
  attendees: string[];
  status: 'Scheduled' | 'Completed' | 'Cancelled';
  created_at: string;
}

export interface SocialLink {
  id: string;
  fighter_id: string;
  platform: 'Twitter' | 'Instagram' | 'YouTube' | 'Twitch' | 'TikTok' | 'Facebook';
  url: string;
  handle: string;
  created_at: string;
}

export interface TrainingCamp {
  id: string;
  name: string;
  description: string;
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced' | 'Elite';
  duration_days: number;
  points_reward: number;
  requirements: string[];
  created_by: string;
  created_at: string;
}

export interface TrainingObjective {
  id: string;
  camp_id: string;
  title: string;
  description: string;
  type: 'Fitness' | 'Technique' | 'Strategy' | 'Mental';
  points_reward: number;
  order_index: number;
  created_at: string;
}

export interface TrainingLog {
  id: string;
  fighter_id: string;
  camp_id: string;
  objective_id: string;
  completed_at: string;
  notes: string;
  proof_url?: string;
}

export interface MatchmakingRequest {
  id: string;
  requester_id: string;
  target_id?: string;
  weight_class: string;
  preferred_time?: string;
  timezone: string;
  status: 'Pending' | 'Accepted' | 'Declined' | 'Expired';
  created_at: string;
  expires_at: string;
}

export interface ScheduledFight {
  id: string;
  fighter1_id: string;
  fighter2_id: string;
  weight_class: string;
  scheduled_date: string;
  timezone: string;
  platform: string;
  connection_notes?: string;
  house_rules?: string;
  status: 'Pending' | 'Scheduled' | 'Completed' | 'Cancelled' | 'Disputed';
  match_type?: 'manual' | 'auto_mandatory' | 'callout' | 'training_camp';
  auto_matched_at?: string;
  match_score?: number;
  result1?: FightRecord;
  result2?: FightRecord;
  created_at: string;
  fighter1?: FighterProfile;
  fighter2?: FighterProfile;
}

export interface Dispute {
  id: string;
  fight_id: string;
  disputer_id: string;
  opponent_id?: string;
  reason: string;
  evidence_urls: string[];
  status: 'Open' | 'In Review' | 'Resolved';
  admin_notes?: string;
  resolution?: string;
  resolution_type?: 'warning' | 'give_win_to_submitter' | 'one_week_suspension' | 'two_week_suspension' | 'one_month_suspension' | 'banned_from_league' | 'dispute_invalid' | 'other';
  created_at: string;
  resolved_at?: string;
  fighter1_name?: string;
  fighter2_name?: string;
  fight_link?: string; // Web link to the fight uploaded by fighter
  dispute_category?: 'cheating' | 'spamming' | 'exploits' | 'excessive_punches' | 'stamina_draining' | 'power_punches' | 'other';
  admin_message_to_disputer?: string;
  admin_message_to_opponent?: string;
  // Relations
  disputer?: FighterProfile;
  opponent?: FighterProfile;
  scheduled_fight?: ScheduledFight;
}

export interface DisputeMessage {
  id: string;
  dispute_id: string;
  sender_id: string;
  sender_type: 'fighter' | 'admin';
  message: string;
  created_at: string;
  read_at?: string;
  sender?: {
    name?: string;
    email?: string;
    role?: string;
  };
}

export interface FightRecordSubmission {
  id: string;
  scheduled_fight_id: string;
  fighter_id: string;
  opponent_id: string;
  result: 'Win' | 'Loss' | 'Draw';
  method: string;
  round?: number;
  date: string;
  weight_class: string;
  proof_url?: string;
  notes?: string;
  status: 'Pending' | 'Confirmed' | 'Disputed' | 'Cancelled';
  created_at: string;
  updated_at: string;
  fighter?: FighterProfile;
  opponent?: FighterProfile;
  scheduled_fight?: ScheduledFight;
}

export interface Tournament {
  id: string;
  name: string;
  format: 'Single Elimination' | 'Double Elimination' | 'Group Stage' | 'Swiss' | 'Round Robin';
  weight_class: string;
  max_participants: number;
  entry_fee: number;
  prize_pool: number;
  start_date: string;
  end_date: string;
  status: 'Open' | 'In Progress' | 'Completed' | 'Cancelled';
  created_by: string;
  created_at: string;
}

export interface FightUrlSubmission {
  id: string;
  fighter_id: string;
  scheduled_fight_id?: string;
  tournament_id?: string;
  fight_url: string;
  event_type: 'Live Event' | 'Tournament';
  description?: string;
  status: 'Pending' | 'Reviewed' | 'Rejected' | 'Approved';
  admin_notes?: string;
  submitted_at: string;
  reviewed_at?: string;
  reviewed_by?: string;
  created_at: string;
  updated_at: string;
  fighter?: FighterProfile;
  scheduled_fight?: ScheduledFight;
  tournament?: Tournament;
}

export interface CreateFightUrlSubmissionRequest {
  scheduled_fight_id?: string;
  tournament_id?: string;
  fight_url: string;
  event_type: 'Live Event' | 'Tournament';
  description?: string;
}

export interface TournamentBracket {
  id: string;
  tournament_id: string;
  round: number;
  match_number: number;
  fighter1_id?: string;
  fighter2_id?: string;
  winner_id?: string;
  scheduled_date?: string;
  status: 'Pending' | 'Scheduled' | 'Completed' | 'Bye';
}

export interface TitleBelt {
  id: string;
  weight_class: string;
  current_champion_id?: string;
  belt_name: string;
  defense_requirement: number; // fights before mandatory defense
  last_defense: string;
  created_at: string;
}

export interface Event {
  id: string;
  name: string;
  date: string;
  timezone: string;
  poster_url?: string;
  theme: string;
  broadcast_url?: string;
  status: 'Scheduled' | 'Live' | 'Completed' | 'Cancelled';
  created_by: string;
  created_at: string;
}

export interface Notification {
  id: string;
  user_id: string;
  type: 'Match' | 'Tournament' | 'Tier' | 'Dispute' | 'Award' | 'General' | 'FightRequest' | 'TrainingCamp' | 'Callout' | 'FightUrlSubmission' | 'Event' | 'News' | 'NewFighter';
  title: string;
  message: string;
  is_read: boolean;
  action_url?: string;
  created_at: string;
}

export interface Achievement {
  id: string;
  name: string;
  description: string;
  icon: string;
  category: 'Performance' | 'Tournament' | 'Special' | 'Milestone';
  rarity: 'Common' | 'Rare' | 'Epic' | 'Legendary';
  points_required?: number;
  fights_required?: number;
  created_at: string;
}

export interface UserAchievement {
  id: string;
  user_id: string;
  achievement_id: string;
  unlocked_at: string;
}

// Removed duplicate MediaAsset interface

export interface AnalyticsSnapshot {
  id: string;
  date: string;
  total_fighters: number;
  total_fights: number;
  tier_distribution: Record<string, number>;
  weight_class_distribution: Record<string, number>;
  platform_distribution: Record<string, number>;
  dispute_rate: number;
  average_time_to_match: number;
  created_at: string;
}

export interface AdminLog {
  id: string;
  admin_id: string;
  action: string;
  target_type: string;
  target_id: string;
  details: Record<string, any>;
  created_at: string;
}

// Weight classes
export const WEIGHT_CLASSES = [
  'Strawweight',
  'Flyweight', 
  'Bantamweight',
  'Featherweight',
  'Lightweight',
  'Welterweight',
  'Middleweight',
  'Light Heavyweight',
  'Cruiserweight',
  'Heavyweight'
] as const;

export type WeightClass = typeof WEIGHT_CLASSES[number];

// Tier definitions
export const TIERS: Tier[] = [
  {
    name: 'Amateur',
    min_points: 0,
    max_points: 19,
    color: '#9E9E9E',
    benefits: ['Basic training access', 'Local events']
  },
  {
    name: 'Semi-Pro',
    min_points: 20,
    max_points: 39,
    color: '#4CAF50',
    benefits: ['Advanced training', 'Regional events', 'Basic analytics']
  },
  {
    name: 'Pro',
    min_points: 40,
    max_points: 89,
    color: '#2196F3',
    benefits: ['Professional training', 'National events', 'Full analytics', 'Sponsorship opportunities']
  },
  {
    name: 'Contender',
    min_points: 90,
    max_points: 149,
    color: '#FF9800',
    benefits: ['Elite training', 'Championship events', 'Advanced analytics', 'Media coverage', 'Title shots']
  },
  {
    name: 'Elite',
    min_points: 150,
    max_points: Infinity,
    color: '#9C27B0',
    benefits: ['World-class training', 'Global events', 'Premium analytics', 'Live streaming', 'Media interviews', 'Championship belts']
  }
];

// Point system constants
export const POINT_SYSTEM = {
  WIN: 5,
  LOSS: -3, // CORRECTED: Loss = -3 not -2
  DRAW: 0,
  KO_BONUS: 3
} as const;

// Matchmaking criteria
export const MATCHMAKING_CRITERIA = {
  RANK_WINDOW: 5,
  POINTS_PROXIMITY: 30,
  REPEAT_AVOIDANCE: 5,
  TIMEZONE_OVERLAP: 4,
  MISMATCH_THRESHOLD: 50
} as const;

