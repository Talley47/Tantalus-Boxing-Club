import { supabase } from './supabase';

export interface FighterDirectMessage {
  id: string;
  sender_id: string;
  recipient_id: string;
  message: string;
  read_at?: string;
  created_at: string;
  updated_at: string;
  // Enriched fields
  sender_name?: string;
  sender_handle?: string;
  recipient_name?: string;
  recipient_handle?: string;
}

export interface Conversation {
  other_fighter_id: string;
  other_fighter_name: string;
  other_fighter_handle: string;
  last_message?: FighterDirectMessage;
  unread_count: number;
  last_message_time: string;
}

export interface SendMessageRequest {
  recipient_id: string;
  message: string;
}

class FighterMessageService {
  // Get all conversations for the current fighter
  async getConversations(fighterId: string): Promise<Conversation[]> {
    try {
      // Fetch messages without FK joins (PostgREST can't auto-detect the FK relationship)
      const { data: messages, error } = await supabase
        .from('fighter_direct_messages')
        .select(`
          id,
          sender_id,
          recipient_id,
          message,
          read_at,
          created_at,
          updated_at
        `)
        .or(`sender_id.eq.${fighterId},recipient_id.eq.${fighterId}`)
        .order('created_at', { ascending: false });

      if (error) throw error;

      // Get unique user IDs from messages
      const userIds = new Set<string>();
      (messages || []).forEach((msg: any) => {
        userIds.add(msg.sender_id);
        userIds.add(msg.recipient_id);
      });

      // Fetch all fighter profiles at once
      const { data: profiles, error: profilesError } = await supabase
        .from('fighter_profiles')
        .select('user_id, name, handle')
        .in('user_id', Array.from(userIds));

      if (profilesError) throw profilesError;

      // Create a map for quick profile lookup
      const profileMap = new Map(
        (profiles || []).map(p => [p.user_id, p])
      );

      // Group messages by conversation partner
      const conversationsMap = new Map<string, Conversation>();

      (messages || []).forEach((msg: any) => {
        const otherFighterId = msg.sender_id === fighterId 
          ? msg.recipient_id 
          : msg.sender_id;
        
        const otherFighterProfile = profileMap.get(otherFighterId);

        if (!otherFighterProfile) return; // Skip if profile not found

        const conversationKey = otherFighterId;

        if (!conversationsMap.has(conversationKey)) {
          conversationsMap.set(conversationKey, {
            other_fighter_id: otherFighterId,
            other_fighter_name: otherFighterProfile.name || 'Unknown',
            other_fighter_handle: otherFighterProfile.handle || 'unknown',
            unread_count: 0,
            last_message_time: msg.created_at,
          });
        }

        const conversation = conversationsMap.get(conversationKey)!;

        // Update last message if this is more recent
        if (!conversation.last_message || new Date(msg.created_at) > new Date(conversation.last_message.created_at)) {
          conversation.last_message = {
            id: msg.id,
            sender_id: msg.sender_id,
            recipient_id: msg.recipient_id,
            message: msg.message,
            read_at: msg.read_at,
            created_at: msg.created_at,
            updated_at: msg.updated_at || msg.created_at,
            sender_name: profileMap.get(msg.sender_id)?.name,
            sender_handle: profileMap.get(msg.sender_id)?.handle,
            recipient_name: profileMap.get(msg.recipient_id)?.name,
            recipient_handle: profileMap.get(msg.recipient_id)?.handle,
          };
          conversation.last_message_time = msg.created_at;
        }

        // Count unread messages (only messages sent to current fighter that are unread)
        if (msg.recipient_id === fighterId && !msg.read_at) {
          conversation.unread_count++;
        }
      });

      // Convert map to array and sort by last message time
      return Array.from(conversationsMap.values()).sort((a, b) => 
        new Date(b.last_message_time).getTime() - new Date(a.last_message_time).getTime()
      );
    } catch (error) {
      console.error('Error fetching conversations:', error);
      throw error;
    }
  }

  // Get messages in a conversation between two fighters
  async getConversationMessages(
    fighterId: string,
    otherFighterId: string,
    limit: number = 50
  ): Promise<FighterDirectMessage[]> {
    try {
      const { data, error } = await supabase
        .from('fighter_direct_messages')
        .select(`
          id,
          sender_id,
          recipient_id,
          message,
          read_at,
          created_at,
          updated_at
        `)
        .or(`and(sender_id.eq.${fighterId},recipient_id.eq.${otherFighterId}),and(sender_id.eq.${otherFighterId},recipient_id.eq.${fighterId})`)
        .order('created_at', { ascending: true })
        .limit(limit);

      if (error) throw error;

      // Get unique user IDs
      const userIds = new Set<string>();
      (data || []).forEach((msg: any) => {
        userIds.add(msg.sender_id);
        userIds.add(msg.recipient_id);
      });

      // Fetch all fighter profiles at once
      const { data: profiles } = await supabase
        .from('fighter_profiles')
        .select('user_id, name, handle')
        .in('user_id', Array.from(userIds));

      const profileMap = new Map(
        (profiles || []).map(p => [p.user_id, p])
      );

      return (data || []).map((msg: any) => {
        const senderProfile = profileMap.get(msg.sender_id);
        const recipientProfile = profileMap.get(msg.recipient_id);
        
        return {
          id: msg.id,
          sender_id: msg.sender_id,
          recipient_id: msg.recipient_id,
          message: msg.message,
          read_at: msg.read_at,
          created_at: msg.created_at,
          updated_at: msg.updated_at || msg.created_at,
          sender_name: senderProfile?.name,
          sender_handle: senderProfile?.handle,
          recipient_name: recipientProfile?.name,
          recipient_handle: recipientProfile?.handle,
        };
      });
    } catch (error) {
      console.error('Error fetching conversation messages:', error);
      throw error;
    }
  }

  // Send a message to another fighter
  async sendMessage(request: SendMessageRequest, senderId: string): Promise<FighterDirectMessage> {
    try {
      if (!request.message.trim()) {
        throw new Error('Message cannot be empty');
      }

      if (request.recipient_id === senderId) {
        throw new Error('Cannot send message to yourself');
      }

      const { data, error } = await supabase
        .from('fighter_direct_messages')
        .insert([{
          sender_id: senderId,
          recipient_id: request.recipient_id,
          message: request.message.trim(),
        }])
        .select(`
          id,
          sender_id,
          recipient_id,
          message,
          read_at,
          created_at,
          updated_at
        `)
        .single();

      if (error) throw error;

      // Fetch sender and recipient profiles separately
      const [senderProfile, recipientProfile] = await Promise.all([
        supabase
          .from('fighter_profiles')
          .select('name, handle')
          .eq('user_id', senderId)
          .single(),
        supabase
          .from('fighter_profiles')
          .select('name, handle')
          .eq('user_id', request.recipient_id)
          .single(),
      ]);

      return {
        id: data.id,
        sender_id: data.sender_id,
        recipient_id: data.recipient_id,
        message: data.message,
        read_at: data.read_at,
        created_at: data.created_at,
        updated_at: data.updated_at || data.created_at,
        sender_name: senderProfile.data?.name,
        sender_handle: senderProfile.data?.handle,
        recipient_name: recipientProfile.data?.name,
        recipient_handle: recipientProfile.data?.handle,
      };
    } catch (error) {
      console.error('Error sending message:', error);
      throw error;
    }
  }

  // Mark messages as read
  async markAsRead(messageId: string, recipientId: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('fighter_direct_messages')
        .update({ read_at: new Date().toISOString() })
        .eq('id', messageId)
        .eq('recipient_id', recipientId)
        .is('read_at', null);

      if (error) throw error;
    } catch (error) {
      console.error('Error marking message as read:', error);
      throw error;
    }
  }

  // Mark all messages in a conversation as read
  async markConversationAsRead(fighterId: string, otherFighterId: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('fighter_direct_messages')
        .update({ read_at: new Date().toISOString() })
        .eq('recipient_id', fighterId)
        .eq('sender_id', otherFighterId)
        .is('read_at', null);

      if (error) throw error;
    } catch (error) {
      console.error('Error marking conversation as read:', error);
      throw error;
    }
  }

  // Get unread message count
  async getUnreadCount(fighterId: string): Promise<number> {
    try {
      const { data, error } = await supabase
        .from('fighter_direct_messages')
        .select('id', { count: 'exact', head: true })
        .eq('recipient_id', fighterId)
        .is('read_at', null);

      if (error) throw error;
      return data?.length || 0;
    } catch (error) {
      console.error('Error fetching unread count:', error);
      throw error;
    }
  }

  // Delete a message (only sender can delete)
  async deleteMessage(messageId: string, senderId: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('fighter_direct_messages')
        .delete()
        .eq('id', messageId)
        .eq('sender_id', senderId);

      if (error) throw error;
    } catch (error) {
      console.error('Error deleting message:', error);
      throw error;
    }
  }

  // Get fighters for message recipient selection (excluding current fighter and admins)
  async getFightersForMessaging(currentFighterId: string): Promise<Array<{
    user_id: string;
    name: string;
    handle: string;
    tier: string;
  }>> {
    try {
      const { data: fighters, error } = await supabase
        .from('fighter_profiles')
        .select('user_id, name, handle, tier')
        .not('user_id', 'is', null)
        .neq('user_id', currentFighterId)
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

      return (fighters || []).filter(f => !adminIds.has(f.user_id));
    } catch (error) {
      console.error('Error fetching fighters for messaging:', error);
      throw error;
    }
  }
}

export const fighterMessageService = new FighterMessageService();

