import { supabase } from './supabase';

export interface AdminDirectMessage {
  id: string;
  fighter_id: string;
  admin_id: string;
  subject: string;
  message: string;
  message_type: 'live_event_selection' | 'tournament_selection' | 'general' | 'announcement';
  event_name?: string;
  event_type?: 'live_event' | 'tournament';
  read_at?: string;
  created_at: string;
  updated_at: string;
  // Enriched fields
  fighter_name?: string;
  fighter_handle?: string;
  admin_name?: string;
}

export interface SendAdminMessageRequest {
  fighter_id: string;
  subject: string;
  message: string;
  message_type?: 'live_event_selection' | 'tournament_selection' | 'general' | 'announcement';
  event_name?: string;
  event_type?: 'live_event' | 'tournament';
}

export interface FighterOption {
  id: string;
  user_id: string;
  name: string;
  handle: string;
  tier: string;
  weight_class: string;
  email?: string;
}

class AdminMessageService {
  // Get all messages (for admin)
  async getAllMessages(limit: number = 100): Promise<AdminDirectMessage[]> {
    try {
      // First try without event_name to avoid errors if column doesn't exist
      const { data, error } = await supabase
        .from('admin_direct_messages')
        .select(`
          id,
          fighter_id,
          admin_id,
          subject,
          message,
          message_type,
          event_type,
          read_at,
          created_at,
          updated_at,
          fighter:fighter_profiles!admin_direct_messages_fighter_id_fkey(
            name,
            handle
          )
        `)
        .order('created_at', { ascending: false })
        .limit(limit);

      if (error) throw error;

      // Try to fetch event_name separately if column exists
      const messagesWithEventName = await Promise.all(
        (data || []).map(async (msg: any) => {
          try {
            const { data: eventData } = await supabase
              .from('admin_direct_messages')
              .select('event_name')
              .eq('id', msg.id)
              .single();
            return {
              ...msg,
              event_name: eventData?.event_name,
              fighter_name: msg.fighter?.name,
              fighter_handle: msg.fighter?.handle,
            };
          } catch {
            // Column doesn't exist or other error - just return without event_name
            return {
              ...msg,
              event_name: undefined,
              fighter_name: msg.fighter?.name,
              fighter_handle: msg.fighter?.handle,
            };
          }
        })
      );

      return messagesWithEventName;
    } catch (error) {
      console.error('Error fetching admin messages:', error);
      throw error;
    }
  }

  // Get messages for a specific fighter
  async getFighterMessages(fighterId: string): Promise<AdminDirectMessage[]> {
    try {
      // Select without event_name first to avoid errors if column doesn't exist
      const { data, error } = await supabase
        .from('admin_direct_messages')
        .select('id, fighter_id, admin_id, subject, message, message_type, event_type, read_at, created_at, updated_at')
        .eq('fighter_id', fighterId)
        .order('created_at', { ascending: false });

      if (error) throw error;

      // Try to add event_name if column exists (safe - won't fail if column doesn't exist)
      const messagesWithEventName = await Promise.all(
        (data || []).map(async (msg: any) => {
          try {
            const { data: eventData } = await supabase
              .from('admin_direct_messages')
              .select('event_name')
              .eq('id', msg.id)
              .single();
            return {
              ...msg,
              event_name: eventData?.event_name,
            };
          } catch {
            // Column doesn't exist - return without event_name
            return {
              ...msg,
              event_name: undefined,
            };
          }
        })
      );

      return messagesWithEventName;
    } catch (error) {
      console.error('Error fetching fighter messages:', error);
      throw error;
    }
  }

  // Get unread message count for a fighter
  async getUnreadCount(fighterId: string): Promise<number> {
    try {
      const { data, error } = await supabase
        .from('admin_direct_messages')
        .select('id', { count: 'exact', head: true })
        .eq('fighter_id', fighterId)
        .is('read_at', null);

      if (error) throw error;
      return data?.length || 0;
    } catch (error) {
      console.error('Error fetching unread count:', error);
      throw error;
    }
  }

  // Send a message to a fighter
  async sendMessage(request: SendAdminMessageRequest): Promise<AdminDirectMessage> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');

      const messageData: any = {
        fighter_id: request.fighter_id,
        admin_id: user.id,
        subject: request.subject,
        message: request.message,
        message_type: request.message_type || 'live_event_selection',
        event_type: request.event_type,
      };

      // Try to include event_name if provided
      const normalizedEventName = request.event_name?.trim();
      if (normalizedEventName) {
        messageData.event_name = normalizedEventName;
      }

      let { data, error } = await supabase
        .from('admin_direct_messages')
        .insert([messageData])
        .select()
        .single();

      // If error is about missing event_name column, retry without it
      if (error && (error.message?.includes('event_name') || error.code === 'PGRST204')) {
        console.warn('event_name column not found, sending message without event_name');
        delete messageData.event_name;
        const retryResult = await supabase
          .from('admin_direct_messages')
          .insert([messageData])
          .select()
          .single();
        if (retryResult.error) throw retryResult.error;
        return retryResult.data;
      }

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error sending message:', error);
      throw error;
    }
  }

  // Send bulk messages to multiple fighters
  async sendBulkMessage(
    fighterIds: string[],
    request: Omit<SendAdminMessageRequest, 'fighter_id'>
  ): Promise<AdminDirectMessage[]> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');

      const normalizedEventName = request.event_name?.trim();
      const messages = fighterIds.map(fighterId => {
        const messageData: any = {
          fighter_id: fighterId,
          admin_id: user.id,
          subject: request.subject,
          message: request.message,
          message_type: request.message_type || 'live_event_selection',
          event_type: request.event_type,
        };

        // Only include event_name if it's provided
        if (normalizedEventName) {
          messageData.event_name = normalizedEventName;
        }

        return messageData;
      });

      let { data, error } = await supabase
        .from('admin_direct_messages')
        .insert(messages)
        .select();

      // If error is about missing event_name column, retry without it
      if (error && (error.message?.includes('event_name') || error.code === 'PGRST204')) {
        console.warn('event_name column not found, sending messages without event_name');
        const messagesWithoutEventName = messages.map(msg => {
          const { event_name, ...rest } = msg;
          return rest;
        });
        const retryResult = await supabase
          .from('admin_direct_messages')
          .insert(messagesWithoutEventName)
          .select();
        if (retryResult.error) throw retryResult.error;
        return retryResult.data || [];
      }

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error sending bulk messages:', error);
      throw error;
    }
  }

  // Mark a message as read
  async markAsRead(messageId: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('admin_direct_messages')
        .update({ read_at: new Date().toISOString() })
        .eq('id', messageId);

      if (error) throw error;
    } catch (error) {
      console.error('Error marking message as read:', error);
      throw error;
    }
  }

  // Mark all messages as read for a fighter
  async markAllAsRead(fighterId: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('admin_direct_messages')
        .update({ read_at: new Date().toISOString() })
        .eq('fighter_id', fighterId)
        .is('read_at', null);

      if (error) throw error;
    } catch (error) {
      console.error('Error marking all messages as read:', error);
      throw error;
    }
  }

  // Delete a message (admin only)
  async deleteMessage(messageId: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('admin_direct_messages')
        .delete()
        .eq('id', messageId);

      if (error) throw error;
    } catch (error) {
      console.error('Error deleting message:', error);
      throw error;
    }
  }

  // Get all fighters for selection (excluding admins)
  async getFightersForSelection(): Promise<FighterOption[]> {
    try {
      const { data: fighters, error } = await supabase
        .from('fighter_profiles')
        .select('id, user_id, name, handle, tier, weight_class')
        .not('user_id', 'is', null)
        .order('name', { ascending: true });

      if (error) throw error;

      // Filter out admin accounts
      const fighterIds = (fighters || []).map(f => f.user_id);
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id, role')
        .in('id', fighterIds);

      const adminIds = new Set(
        (profiles || [])
          .filter(p => p.role === 'admin')
          .map(p => p.id)
      );

      const filteredFighters = (fighters || []).filter(f => !adminIds.has(f.user_id));

      // Map fighters to options (email is optional and may not be available)
      const fighterOptions: FighterOption[] = filteredFighters.map((fighter: any) => ({
        id: fighter.id,
        user_id: fighter.user_id,
        name: fighter.name || 'Unknown',
        handle: fighter.handle || 'unknown',
        tier: fighter.tier || 'Amateur',
        weight_class: fighter.weight_class || 'N/A',
      }));

      return fighterOptions;
    } catch (error) {
      console.error('Error fetching fighters for selection:', error);
      throw error;
    }
  }
}

export const adminMessageService = new AdminMessageService();

