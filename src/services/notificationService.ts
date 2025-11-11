import { supabase } from './supabase';

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

class NotificationService {
  // Get all notifications for a user
  async getNotifications(userId: string, limit: number = 50): Promise<Notification[]> {
    try {
      const { data, error } = await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(limit);

      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching notifications:', error);
      throw error;
    }
  }

  // Get unread notifications count
  async getUnreadCount(userId: string): Promise<number> {
    try {
      const { data, error } = await supabase
        .from('notifications')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('is_read', false);

      if (error) throw error;
      return data?.length || 0;
    } catch (error) {
      console.error('Error fetching unread count:', error);
      return 0;
    }
  }

  // Mark notification as read
  async markAsRead(notificationId: string, userId: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('notifications')
        .update({ is_read: true })
        .eq('id', notificationId)
        .eq('user_id', userId);

      if (error) throw error;
    } catch (error) {
      console.error('Error marking notification as read:', error);
      throw error;
    }
  }

  // Mark all notifications as read
  async markAllAsRead(userId: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('notifications')
        .update({ is_read: true })
        .eq('user_id', userId)
        .eq('is_read', false);

      if (error) throw error;
    } catch (error) {
      console.error('Error marking all notifications as read:', error);
      throw error;
    }
  }

  // Create a notification (used by backend triggers and services)
  async createNotification(
    userId: string,
    type: Notification['type'],
    title: string,
    message: string,
    actionUrl?: string
  ): Promise<Notification> {
    try {
      const { data, error } = await supabase
        .from('notifications')
        .insert({
          user_id: userId,
          type,
          title,
          message,
          action_url: actionUrl,
          is_read: false,
        })
        .select()
        .single();

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error creating notification:', error);
      throw error;
    }
  }

  // Create notification for multiple users (e.g., all fighters for league-wide announcements)
  async createNotificationForAllUsers(
    type: Notification['type'],
    title: string,
    message: string,
    actionUrl?: string
  ): Promise<void> {
    try {
      // Get all fighter user IDs
      const { data: fighters, error: fightersError } = await supabase
        .from('fighter_profiles')
        .select('user_id');

      if (fightersError) throw fightersError;

      if (!fighters || fighters.length === 0) return;

      // Create notifications for all fighters
      const notifications = fighters.map(fighter => ({
        user_id: fighter.user_id,
        type,
        title,
        message,
        action_url: actionUrl,
        is_read: false,
      }));

      // Insert in batches to avoid overwhelming the database
      const batchSize = 100;
      for (let i = 0; i < notifications.length; i += batchSize) {
        const batch = notifications.slice(i, i + batchSize);
        const { error } = await supabase
          .from('notifications')
          .insert(batch);

        if (error) {
          console.error(`Error creating notifications batch ${i / batchSize + 1}:`, error);
          // Continue with next batch even if one fails
        }
      }
    } catch (error) {
      console.error('Error creating notifications for all users:', error);
      throw error;
    }
  }

  // Delete a notification
  async deleteNotification(notificationId: string, userId: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId)
        .eq('user_id', userId);

      if (error) throw error;
    } catch (error) {
      console.error('Error deleting notification:', error);
      throw error;
    }
  }
}

export const notificationService = new NotificationService();
