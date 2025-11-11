import { supabase } from './supabase';
import { TABLES } from './supabase';

export interface CalendarEvent {
  id: string;
  name: string;
  date: string;
  timezone: string;
  event_type: 'Fight Card' | 'Tournament' | 'Interview' | 'Press Conference' | 'Podcast';
  description?: string;
  location?: string;
  poster_url?: string;
  theme?: string;
  broadcast_url?: string;
  status: 'Scheduled' | 'Live' | 'Completed' | 'Cancelled';
  featured_fighter_ids?: string[];
  main_card_fight_id?: string;
  tournament_id?: string;
  is_auto_scheduled?: boolean;
  created_by?: string;
  created_at: string;
}

export interface CreateEventRequest {
  name: string;
  date: string;
  timezone: string;
  event_type: CalendarEvent['event_type'];
  description?: string;
  location?: string;
  poster_url?: string;
  theme?: string;
  broadcast_url?: string;
  featured_fighter_ids?: string[];
  main_card_fight_id?: string;
  tournament_id?: string;
  is_auto_scheduled?: boolean;
}

export class CalendarService {
  // Get all events for a month
  static async getEventsForMonth(year: number, month: number): Promise<CalendarEvent[]> {
    try {
      const startDate = new Date(year, month - 1, 1).toISOString();
      const endDate = new Date(year, month, 0, 23, 59, 59).toISOString();

      const { data, error } = await supabase
        .from(TABLES.EVENTS)
        .select('*')
        .gte('date', startDate)
        .lte('date', endDate)
        .order('date', { ascending: true });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching calendar events:', error);
      throw error;
    }
  }

  // Get all events for a date range
  static async getEventsForDateRange(startDate: string, endDate: string): Promise<CalendarEvent[]> {
    try {
      const { data, error } = await supabase
        .from(TABLES.EVENTS)
        .select('*')
        .gte('date', startDate)
        .lte('date', endDate)
        .order('date', { ascending: true });

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching calendar events:', error);
      throw error;
    }
  }

  // Get upcoming events
  static async getUpcomingEvents(limit: number = 10): Promise<CalendarEvent[]> {
    try {
      const now = new Date().toISOString();
      
      const { data, error } = await supabase
        .from(TABLES.EVENTS)
        .select('*')
        .gte('date', now)
        .order('date', { ascending: true })
        .limit(limit);

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching upcoming events:', error);
      throw error;
    }
  }

  // Create a new event (Admin only)
  static async createEvent(event: CreateEventRequest): Promise<CalendarEvent> {
    try {
      const { data, error } = await supabase
        .from(TABLES.EVENTS)
        .insert({
          ...event,
          status: 'Scheduled',
        })
        .select()
        .single();

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error creating event:', error);
      throw error;
    }
  }

  // Update an event (Admin only)
  static async updateEvent(eventId: string, updates: Partial<CreateEventRequest>): Promise<CalendarEvent> {
    try {
      const { data, error } = await supabase
        .from(TABLES.EVENTS)
        .update(updates)
        .eq('id', eventId)
        .select()
        .single();

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error updating event:', error);
      throw error;
    }
  }

  // Delete an event (Admin only)
  static async deleteEvent(eventId: string): Promise<void> {
    try {
      const { error } = await supabase
        .from(TABLES.EVENTS)
        .delete()
        .eq('id', eventId);

      if (error) throw error;
    } catch (error) {
      console.error('Error deleting event:', error);
      throw error;
    }
  }

  // Auto-select fighters for interviews based on performance
  static async autoSelectInterviewFighters(limit: number = 5): Promise<string[]> {
    try {
      // Get top performers based on recent wins, points, and tier
      const { data, error } = await supabase
        .from(TABLES.FIGHTER_PROFILES)
        .select('id, points, wins, tier, weight_class')
        .order('points', { ascending: false })
        .order('wins', { ascending: false })
        .limit(limit);

      if (error) throw error;
      
      // Prioritize champions and high-tier fighters
      const fighters = data || [];
      const sorted = fighters.sort((a, b) => {
        const tierPriority: Record<string, number> = {
          'Champion': 1000,
          'Elite': 800,
          'Professional': 600,
          'Amateur': 400,
          'Beginner': 200,
        };
        
        const aScore = (a.points || 0) + tierPriority[a.tier || 'Beginner'] || 200;
        const bScore = (b.points || 0) + tierPriority[b.tier || 'Beginner'] || 200;
        
        return bScore - aScore;
      });

      return sorted.slice(0, limit).map(f => f.id);
    } catch (error) {
      console.error('Error auto-selecting interview fighters:', error);
      throw error;
    }
  }

  // Get event by ID
  static async getEventById(eventId: string): Promise<CalendarEvent | null> {
    try {
      const { data, error } = await supabase
        .from(TABLES.EVENTS)
        .select('*')
        .eq('id', eventId)
        .single();

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error fetching event:', error);
      return null;
    }
  }
}

