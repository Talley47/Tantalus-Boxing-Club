import { supabase } from './supabase';
import { notificationService } from './notificationService';
import { sanitizeText } from '../utils/securityUtils';

const TABLES = {
  CHAT_MESSAGES: 'chat_messages',
  FIGHTER_PROFILES: 'fighter_profiles',
};

export interface ChatMessage {
  id: string;
  user_id: string;
  message: string;
  attachment_url?: string;
  attachment_type?: 'image' | 'video' | 'file';
  created_at: string;
  updated_at: string;
  // Relations
  user?: {
    id: string;
    email?: string;
  };
  fighter_profile?: {
    id: string;
    name: string;
    handle?: string;
  };
}

class ChatService {
  // Extract @mentions from message text
  private extractMentions(message: string): string[] {
    // Match @handle or @name patterns
    // Supports: @handle, @fighter_name, @fighter name (with spaces)
    const mentionPattern = /@(\w+(?:\s+\w+)*)/g;
    const mentions: string[] = [];
    let match;
    
    while ((match = mentionPattern.exec(message)) !== null) {
      const mention = match[1].trim();
      if (mention && !mentions.includes(mention)) {
        mentions.push(mention);
      }
    }
    
    return mentions;
  }

  // Find fighter profiles by handle or name
  private async findFightersByMention(mention: string): Promise<Array<{ user_id: string; name: string; handle: string }>> {
    try {
      // Normalize mention: lowercase and replace spaces with underscores for handle matching
      const normalizedMention = mention.toLowerCase().replace(/\s+/g, '_');
      
      // Search by handle (exact match or starts with) - use separate queries
      const handleQueries = [
        supabase.from(TABLES.FIGHTER_PROFILES).select('user_id, name, handle').ilike('handle', normalizedMention).not('user_id', 'is', null),
        supabase.from(TABLES.FIGHTER_PROFILES).select('user_id, name, handle').ilike('handle', `${normalizedMention}%`).not('user_id', 'is', null)
      ];

      const handleResults = await Promise.all(handleQueries);
      const byHandle: Array<{ user_id: string; name: string; handle: string }> = [];
      
      for (const result of handleResults) {
        if (result.error) {
          console.error('Error searching fighters by handle:', result.error);
        } else if (result.data) {
          byHandle.push(...result.data);
        }
      }

      // Search by name (case-insensitive, partial match)
      const { data: byName, error: nameError } = await supabase
        .from(TABLES.FIGHTER_PROFILES)
        .select('user_id, name, handle')
        .ilike('name', `%${mention}%`)
        .not('user_id', 'is', null);

      if (nameError) {
        console.error('Error searching fighters by name:', nameError);
      }

      // Combine results and remove duplicates
      const allResults = [...byHandle, ...(byName || [])];
      const uniqueResults = Array.from(
        new Map(allResults.map(f => [f.user_id, f])).values()
      );

      return uniqueResults;
    } catch (error) {
      console.error('Error finding fighters by mention:', error);
      return [];
    }
  }

  // Send notifications to mentioned fighters
  private async notifyMentionedFighters(
    mentions: string[],
    senderName: string,
    messageId: string,
    messageText: string
  ): Promise<void> {
    if (mentions.length === 0) return;

    try {
      // Find all mentioned fighters
      const mentionedFighters = new Map<string, { user_id: string; name: string; handle: string }>();
      
      for (const mention of mentions) {
        const fighters = await this.findFightersByMention(mention);
        for (const fighter of fighters) {
          if (!mentionedFighters.has(fighter.user_id)) {
            mentionedFighters.set(fighter.user_id, fighter);
          }
        }
      }

      // Create notifications for each mentioned fighter
      const notificationPromises = Array.from(mentionedFighters.values()).map(async (fighter) => {
        try {
          // Truncate message if too long
          const truncatedMessage = messageText.length > 100 
            ? messageText.substring(0, 100) + '...' 
            : messageText;

          await notificationService.createNotification(
            fighter.user_id,
            'General',
            `@${senderName} mentioned you in League Chat`,
            `${senderName}: ${truncatedMessage}`,
            `/social?message=${messageId}` // Link to the specific message
          );
        } catch (error) {
          console.error(`Error creating notification for fighter ${fighter.user_id}:`, error);
        }
      });

      await Promise.all(notificationPromises);
    } catch (error) {
      console.error('Error notifying mentioned fighters:', error);
      // Don't throw - notification failures shouldn't block message sending
    }
  }
  // Get older chat messages (before a certain date)
  async getOlderMessages(beforeDate: string, limit: number = 50): Promise<ChatMessage[]> {
    try {
      // Fetch messages before the specified date
      const { data, error } = await supabase
        .from(TABLES.CHAT_MESSAGES)
        .select('*')
        .lt('created_at', beforeDate)
        .order('created_at', { ascending: false })
        .limit(limit);

      if (error) {
        console.error('Error fetching older chat messages:', error);
        throw error;
      }

      if (!data || data.length === 0) {
        return [];
      }

      // Fetch fighter profiles separately
      const userIds = Array.from(new Set(data.map((m: any) => m.user_id)));
      const profilesMap: Record<string, any> = {};

      if (userIds.length > 0) {
        const { data: profiles } = await supabase
          .from(TABLES.FIGHTER_PROFILES)
          .select('id, name, handle, user_id')
          .in('user_id', userIds);

        if (profiles) {
          profiles.forEach((profile: any) => {
            profilesMap[profile.user_id] = profile;
          });
        }
      }

      // Reverse to show oldest first and add fighter profiles
      return data.reverse().map((msg: any) => ({
        ...msg,
        fighter_profile: profilesMap[msg.user_id] || undefined,
      }));
    } catch (error) {
      console.error('Error in getOlderMessages:', error);
      throw error;
    }
  }

  // Get recent chat messages (last 100)
  async getMessages(limit: number = 100): Promise<ChatMessage[]> {
    try {
      // Fetch messages first
      const { data, error } = await supabase
        .from(TABLES.CHAT_MESSAGES)
        .select('*')
        .order('created_at', { ascending: false })
        .limit(limit);

      if (error) {
        console.error('Error fetching chat messages:', error);
        throw error;
      }

      if (!data || data.length === 0) {
        return [];
      }

      // Fetch fighter profiles separately
      const userIds = Array.from(new Set(data.map((m: any) => m.user_id)));
      const profilesMap: Record<string, any> = {};

      if (userIds.length > 0) {
        const { data: profiles } = await supabase
          .from(TABLES.FIGHTER_PROFILES)
          .select('id, name, handle, user_id')
          .in('user_id', userIds);

        if (profiles) {
          profiles.forEach((profile: any) => {
            profilesMap[profile.user_id] = profile;
          });
        }
      }

      // Reverse to show oldest first and add fighter profiles
      return data.reverse().map((msg: any) => ({
        ...msg,
        fighter_profile: profilesMap[msg.user_id] || undefined,
      }));
    } catch (error) {
      console.error('Error in getMessages:', error);
      throw error;
    }
  }

  // Send a chat message
  // SECURITY: Sanitizes message content before storing in database
  async sendMessage(message: string, userId: string, attachmentUrl?: string, attachmentType?: 'image' | 'video' | 'file'): Promise<ChatMessage> {
    try {
      if (!message || !message.trim()) {
        throw new Error('Message cannot be empty');
      }

      // SECURITY: Sanitize message content to prevent XSS and injection attacks
      const sanitizedMessage = sanitizeText(message.trim());
      if (!sanitizedMessage) {
        throw new Error('Invalid message content');
      }

      const insertData: any = {
        user_id: userId,
        message: sanitizedMessage,
      };

      if (attachmentUrl) {
        insertData.attachment_url = attachmentUrl;
        insertData.attachment_type = attachmentType || 'file';
      }

      const { data, error } = await supabase
        .from(TABLES.CHAT_MESSAGES)
        .insert(insertData)
        .select('*')
        .single();

      if (error) {
        console.error('Error sending chat message:', error);
        throw error;
      }

      // Fetch fighter profile separately
      const { data: profile } = await supabase
        .from(TABLES.FIGHTER_PROFILES)
        .select('id, name, handle')
        .eq('user_id', userId)
        .maybeSingle();

      const result = {
        ...data,
        fighter_profile: profile || undefined,
      };

      // Check for @mentions and send notifications
      // SECURITY: Use sanitized message for mentions (already sanitized above)
      const mentions = this.extractMentions(sanitizedMessage);
      if (mentions.length > 0 && profile) {
        // Don't await - let it run in background to avoid blocking message send
        this.notifyMentionedFighters(mentions, profile.name || 'Unknown Fighter', data.id, sanitizedMessage)
          .catch(error => console.error('Background mention notification error:', error));
      }

      return result;
    } catch (error) {
      console.error('Error in sendMessage:', error);
      throw error;
    }
  }

  // Delete a message (users can only delete their own messages within 5 minutes)
  async deleteMessage(messageId: string, userId: string): Promise<void> {
    try {
      const { data, error } = await supabase
        .from(TABLES.CHAT_MESSAGES)
        .delete()
        .eq('id', messageId)
        .eq('user_id', userId);

      if (error) {
        console.error('Error deleting chat message:', error);
        throw error;
      }
    } catch (error) {
      console.error('Error in deleteMessage:', error);
      throw error;
    }
  }

  // Update a message (users can always update their own messages)
  // SECURITY: Sanitizes message content before updating in database
  async updateMessage(messageId: string, userId: string, newMessage: string): Promise<ChatMessage> {
    try {
      if (!newMessage || !newMessage.trim()) {
        throw new Error('Message cannot be empty');
      }

      // SECURITY: Sanitize message content to prevent XSS and injection attacks
      const sanitizedMessage = sanitizeText(newMessage.trim());
      if (!sanitizedMessage) {
        throw new Error('Invalid message content');
      }

      const { data, error } = await supabase
        .from(TABLES.CHAT_MESSAGES)
        .update({ message: sanitizedMessage })
        .eq('id', messageId)
        .eq('user_id', userId)
        .select('*')
        .maybeSingle();

      if (error) {
        console.error('Error updating chat message:', error);
        throw error;
      }

      if (!data) {
        throw new Error('Message not found or cannot be updated.');
      }

      // Fetch fighter profile separately
      const { data: profile } = await supabase
        .from(TABLES.FIGHTER_PROFILES)
        .select('id, name, handle')
        .eq('user_id', userId)
        .maybeSingle();

      return {
        ...data,
        fighter_profile: profile || undefined,
      };
    } catch (error) {
      console.error('Error in updateMessage:', error);
      throw error;
    }
  }
}

export const chatService = new ChatService();

