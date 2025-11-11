import { supabase, TABLES } from './supabase';

export interface AdminUser {
  id: string;
  email: string;
  username?: string; // Email typically serves as username
  role: string;
  status: 'active' | 'inactive' | 'banned';
  created_at: string;
  last_sign_in_at?: string;
  banned_until?: string;
  fighter_profile?: {
    name: string;
    tier: string;
    points: number;
    wins: number;
    losses: number;
  };
}

export interface BanUserRequest {
  userId: string;
  duration?: number; // days, or undefined for permanent
  reason?: string;
}

export class AdminService {
  // Get all users with their profiles and fighter data
  // PRIMARY SOURCE: fighter_profiles (contains all fighters)
  // SECONDARY: profiles table (for admin accounts and additional metadata)
  static async getAllUsers(): Promise<AdminUser[]> {
    try {
      if (process.env.NODE_ENV === 'development') {
        console.log('[AdminService] Fetching all users...');
      }

      // PRIMARY: Get all fighter_profiles (this contains ALL fighters)
      const { data: fighterProfiles, error: fpError } = await supabase
        .from(TABLES.FIGHTER_PROFILES)
        .select('user_id, name, tier, points, wins, losses, created_at')
        .order('created_at', { ascending: false });

      if (fpError) {
        console.error('[AdminService] Error fetching fighter_profiles:', fpError);
        throw new Error(`Failed to fetch fighter profiles: ${fpError.message}`);
      }

      if (!fighterProfiles || fighterProfiles.length === 0) {
        console.warn('[AdminService] No fighter profiles found');
        return [];
      }

      if (process.env.NODE_ENV === 'development') {
        console.log('[AdminService] Found', fighterProfiles.length, 'fighter profiles');
      }

      // Get user IDs from fighter_profiles
      const userIds = fighterProfiles.map((fp: any) => fp.user_id);

      // Try to get email addresses from auth.users via RPC function first (most reliable)
      let userEmails: Map<string, { email: string; created_at: string; last_sign_in_at: string | null }> = new Map();
      try {
        const { data: emailsData, error: emailsError } = await supabase
          .rpc('get_user_emails_for_admin', { user_ids: userIds });
        
        if (!emailsError && emailsData) {
          emailsData.forEach((item: any) => {
            userEmails.set(item.user_id, {
              email: item.email,
              created_at: item.created_at,
              last_sign_in_at: item.last_sign_in_at
            });
          });
          if (process.env.NODE_ENV === 'development') {
            console.log('[AdminService] Got', emailsData.length, 'emails from RPC function');
          }
        } else if (emailsError) {
          if (process.env.NODE_ENV === 'development') {
            console.log('[AdminService] RPC function error (may not exist):', emailsError.message);
          }
        }
      } catch (rpcError: any) {
        // RPC function might not exist, that's okay - try profiles table instead
        if (process.env.NODE_ENV === 'development') {
          console.log('[AdminService] RPC function not available:', rpcError.message);
        }
      }

      // Create a map from RPC function email data
      // We don't query profiles table anymore since it's causing 400 errors
      // All data comes from fighter_profiles and the RPC function

      // Map fighter_profiles to AdminUser format
      const users: AdminUser[] = fighterProfiles.map((fp: any) => {
        // Get email and timestamps from RPC function result
        const emailData = userEmails.get(fp.user_id);
        const email = emailData?.email || `user_${fp.user_id.substring(0, 8)}@tantalus.com`;
        
        // Determine status based on last sign in or creation date
        let status: 'active' | 'inactive' | 'banned' = 'active';
        
        if (emailData?.last_sign_in_at) {
          const lastSignIn = new Date(emailData.last_sign_in_at);
          const ninetyDaysAgo = new Date();
          ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);
          if (lastSignIn < ninetyDaysAgo) {
            status = 'inactive';
          }
        } else if (fp.created_at) {
          const created = new Date(fp.created_at);
          const thirtyDaysAgo = new Date();
          thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
          if (created < thirtyDaysAgo) {
            status = 'inactive';
          }
        }
        
        return {
          id: fp.user_id,
          email: email,
          username: emailData?.email || fp.name,
          role: 'fighter', // All users from fighter_profiles are fighters
          status: status,
          created_at: emailData?.created_at || fp.created_at || new Date().toISOString(),
          last_sign_in_at: emailData?.last_sign_in_at || undefined, // Convert null to undefined
          banned_until: undefined, // Can't determine from fighter_profiles alone
          fighter_profile: {
            name: fp.name,
            tier: fp.tier || 'amateur',
            points: fp.points || 0,
            wins: fp.wins || 0,
            losses: fp.losses || 0,
          },
        };
      });

      // Sort by created_at descending
      users.sort((a, b) => {
        const dateA = new Date(a.created_at).getTime();
        const dateB = new Date(b.created_at).getTime();
        return dateB - dateA;
      });

      if (process.env.NODE_ENV === 'development') {
        console.log('[AdminService] Returning', users.length, 'users (fighters + admins)');
      }
      return users;
    } catch (error) {
      console.error('Error fetching all users:', error);
      throw error;
    }
  }

  // Send password reset email (doesn't require admin API)
  static async sendPasswordResetEmail(email: string): Promise<void> {
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/reset-password`,
      });

      if (error) {
        // Handle rate limit errors with a user-friendly message
        if (error.status === 429 || error.message?.includes('rate limit') || error.message?.includes('Too Many Requests')) {
          throw new Error('Email rate limit exceeded. Please wait a few minutes before requesting another password reset email. Supabase limits the number of emails that can be sent per hour to prevent abuse.');
        }
        throw error;
      }
    } catch (error: any) {
      console.error('Error sending password reset email:', error);
      
      // Re-throw with a more user-friendly message if it's a rate limit error
      if (error.status === 429 || error.message?.includes('rate limit') || error.message?.includes('Too Many Requests')) {
        throw new Error('Email rate limit exceeded. Please wait a few minutes before requesting another password reset email.');
      }
      
      // Re-throw with original message for other errors
      throw error;
    }
  }

  // Ban a user
  static async banUser(userId: string, durationDays?: number, reason?: string): Promise<void> {
    try {
      console.log('[AdminService] Banning user:', { userId, durationDays, reason });
      
      // Use RPC function to ban user (creates/updates profiles entry)
      const { data, error } = await supabase.rpc('ban_user', {
        target_user_id: userId,
        duration_days: durationDays || null,
        ban_reason: reason || null
      });

      console.log('[AdminService] Ban RPC response:', { data, error });

      if (error) {
        console.error('[AdminService] Ban RPC error:', error);
        // Check if function doesn't exist
        if (error.code === '42883' || error.message?.includes('does not exist')) {
          throw new Error('Database function not found. Please run admin-user-management-functions.sql in Supabase SQL Editor.');
        }
        throw new Error(error.message || 'Failed to ban user');
      }

      if (data && typeof data === 'object' && 'success' in data) {
        const result = data as any;
        if (!result.success) {
          throw new Error(result.error || 'Failed to ban user');
        }
        console.log('[AdminService] Ban successful:', result);
      } else {
        console.warn('[AdminService] Unexpected ban RPC response format:', data);
      }

      console.log('User banned:', { userId, durationDays, reason });
    } catch (error: any) {
      console.error('Error banning user:', error);
      throw new Error(error.message || 'Failed to ban user');
    }
  }

  // Unban a user
  static async unbanUser(userId: string): Promise<void> {
    try {
      console.log('[AdminService] Unbanning user:', { userId });
      
      // Use RPC function to unban user
      const { data, error } = await supabase.rpc('unban_user', {
        target_user_id: userId
      });

      console.log('[AdminService] Unban RPC response:', { data, error });

      if (error) {
        console.error('[AdminService] Unban RPC error:', error);
        // Check if function doesn't exist
        if (error.code === '42883' || error.message?.includes('does not exist')) {
          throw new Error('Database function not found. Please run admin-user-management-functions.sql in Supabase SQL Editor.');
        }
        throw new Error(error.message || 'Failed to unban user');
      }

      if (data && typeof data === 'object' && 'success' in data) {
        const result = data as any;
        if (!result.success) {
          throw new Error(result.error || 'Failed to unban user');
        }
        console.log('[AdminService] Unban successful:', result);
      } else {
        console.warn('[AdminService] Unexpected unban RPC response format:', data);
      }

      console.log('User unbanned:', { userId });
    } catch (error: any) {
      console.error('Error unbanning user:', error);
      throw new Error(error.message || 'Failed to unban user');
    }
  }

  // Delete user account
  static async deleteUser(userId: string): Promise<void> {
    try {
      // Delete from profiles first (if exists)
      const { error: profileError } = await supabase
        .from('profiles')
        .delete()
        .eq('id', userId);

      if (profileError && profileError.code !== 'PGRST116') {
        console.warn('Error deleting profile:', profileError);
      }

      // Delete fighter profile (cascade should handle this)
      const { error: fighterError } = await supabase
        .from(TABLES.FIGHTER_PROFILES)
        .delete()
        .eq('user_id', userId);

      if (fighterError) {
        console.warn('Error deleting fighter profile:', fighterError);
      }

      // Note: Deleting from auth.users requires admin API
      // This should be done server-side for security
      throw new Error('User deletion from auth.users requires server-side admin API. Please implement a backend endpoint.');
    } catch (error) {
      console.error('Error deleting user:', error);
      throw error;
    }
  }

  // Update user role
  static async updateUserRole(userId: string, role: 'admin' | 'fighter' | 'user'): Promise<void> {
    try {
      console.log('[AdminService] Updating user role:', { userId, role });
      
      // Use RPC function to update role (creates/updates profiles entry)
      const { data, error } = await supabase.rpc('update_user_role', {
        target_user_id: userId,
        new_role: role
      });

      console.log('[AdminService] RPC response:', { data, error });

      if (error) {
        console.error('[AdminService] RPC error:', error);
        // Check if function doesn't exist
        if (error.code === '42883' || error.message?.includes('does not exist')) {
          throw new Error('Database function not found. Please run admin-user-management-functions.sql in Supabase SQL Editor.');
        }
        throw new Error(error.message || 'Failed to update user role');
      }

      if (data && typeof data === 'object' && 'success' in data) {
        const result = data as any;
        if (!result.success) {
          throw new Error(result.error || 'Failed to update user role');
        }
        console.log('[AdminService] Role update successful:', result);
      } else {
        console.warn('[AdminService] Unexpected RPC response format:', data);
      }

      console.log('User role updated:', { userId, role });
    } catch (error: any) {
      console.error('Error updating user role:', error);
      throw new Error(error.message || 'Failed to update user role');
    }
  }

  // Reset a single fighter's records (wins, losses, draws, points, etc.)
  static async resetFighterRecords(userId: string): Promise<void> {
    try {
      // Try using the RPC function first (if it exists)
      const { data, error } = await supabase.rpc('reset_fighter_records', {
        fighter_user_id: userId
      });

      if (error) {
        // If RPC function doesn't exist or fails, fall back to direct update
        console.warn('RPC function failed, trying direct update:', error);
        
        // Fallback: Direct update (requires proper RLS policies)
        const { error: updateError } = await supabase
          .from(TABLES.FIGHTER_PROFILES)
          .update({
            wins: 0,
            losses: 0,
            draws: 0,
            knockouts: 0,
            points: 0,
            win_percentage: 0.00,
            ko_percentage: 0.00,
            current_streak: 0,
            tier: 'Amateur' // Reset tier to Amateur (capitalized to match constraint)
          })
          .eq('user_id', userId);

        if (updateError) {
          throw new Error(
            updateError.message || 
            'Failed to reset fighter records. Make sure you are logged in as an admin and the database function exists.'
          );
        }

        console.log('Fighter records reset successfully (via direct update)');
      } else {
        // RPC function succeeded
        if (data && typeof data === 'object') {
          const result = data as any;
          if (result.success) {
            console.log('Fighter records reset successfully:', result.message);
            // Wait a moment for real-time updates to propagate
            await new Promise(resolve => setTimeout(resolve, 500));
          } else {
            throw new Error(result.error || 'Failed to reset fighter records');
          }
        }
      }
    } catch (error: any) {
      console.error('Error resetting fighter records:', error);
      // Provide more detailed error message
      const errorMessage = error?.message || 
                           error?.error_description || 
                           JSON.stringify(error) || 
                           'Unknown error occurred';
      throw new Error(`Failed to reset fighter records: ${errorMessage}`);
    }
  }

  // Reset all fighters' records (wins, losses, draws, points, etc.)
  static async resetAllFightersRecords(): Promise<void> {
    try {
      // Try using the RPC function first (if it exists)
      const { data, error } = await supabase.rpc('reset_all_fighters_records');

      if (error) {
        // If RPC function doesn't exist or fails, fall back to direct update
        console.warn('RPC function failed, trying direct update:', error);
        
        // Fallback: Direct update (requires proper RLS policies)
        // Try capitalized first, then lowercase if that fails
        let updateError: any = null;
        let tierValue = 'Amateur'; // Try capitalized first
        
        const { error: error1 } = await supabase
          .from(TABLES.FIGHTER_PROFILES)
          .update({
            wins: 0,
            losses: 0,
            draws: 0,
            knockouts: 0,
            points: 0,
            win_percentage: 0.00,
            ko_percentage: 0.00,
            current_streak: 0,
            tier: 'Amateur' // Try capitalized first
          });
        
        // If capitalized fails with constraint violation, try lowercase
        if (error1 && (error1.message?.includes('tier_check') || error1.code === '23514')) {
          console.log('Capitalized tier failed, trying lowercase...');
          tierValue = 'amateur';
          const { error: error2 } = await supabase
            .from(TABLES.FIGHTER_PROFILES)
            .update({
              wins: 0,
              losses: 0,
              draws: 0,
              knockouts: 0,
              points: 0,
              win_percentage: 0.00,
              ko_percentage: 0.00,
              current_streak: 0,
              tier: 'amateur' // Try lowercase
            });
          updateError = error2;
        } else {
          updateError = error1;
        }

        if (updateError) {
          throw new Error(
            updateError.message || 
            'Failed to reset fighters records. Make sure you are logged in as an admin and the database function exists.'
          );
        }

        console.log('All fighters records reset successfully (via direct update)');
        // Wait a moment for real-time updates to propagate
        await new Promise(resolve => setTimeout(resolve, 500));
      } else {
        // RPC function succeeded
        if (data && typeof data === 'object') {
          const result = data as any;
          if (result.success) {
            console.log('All fighters records reset successfully:', result.message);
            // Wait a moment for real-time updates to propagate
            await new Promise(resolve => setTimeout(resolve, 500));
          } else {
            throw new Error(result.error || 'Failed to reset fighters records');
          }
        }
      }
    } catch (error: any) {
      console.error('Error resetting fighters records:', error);
      // Provide more detailed error message
      const errorMessage = error?.message || 
                           error?.error_description || 
                           JSON.stringify(error) || 
                           'Unknown error occurred';
      throw new Error(`Failed to reset fighters records: ${errorMessage}`);
    }
  }

  // Delete all training camp invitations and active training camps
  static async deleteAllTrainingCamps(): Promise<{ deletedInvitations: number; deletedActiveCamps: number }> {
    try {
      // Delete all pending invitations
      const { data: pendingInvitations, error: pendingError } = await supabase
        .from('training_camp_invitations')
        .select('id')
        .eq('status', 'pending');

      if (pendingError) {
        console.error('Error fetching pending invitations:', pendingError);
      }

      const { error: deletePendingError } = await supabase
        .from('training_camp_invitations')
        .delete()
        .eq('status', 'pending');

      if (deletePendingError) {
        throw new Error(`Failed to delete pending invitations: ${deletePendingError.message}`);
      }

      // Delete all accepted/active training camps
      const { data: activeCamps, error: activeError } = await supabase
        .from('training_camp_invitations')
        .select('id')
        .eq('status', 'accepted');

      if (activeError) {
        console.error('Error fetching active camps:', activeError);
      }

      const { error: deleteActiveError } = await supabase
        .from('training_camp_invitations')
        .delete()
        .eq('status', 'accepted');

      if (deleteActiveError) {
        throw new Error(`Failed to delete active training camps: ${deleteActiveError.message}`);
      }

      const deletedInvitations = pendingInvitations?.length || 0;
      const deletedActiveCamps = activeCamps?.length || 0;

      // Note: Real-time updates will be automatically triggered by postgres_changes events
      // No need for manual broadcast - components subscribed to training_camp_invitations will update automatically

      return {
        deletedInvitations,
        deletedActiveCamps
      };
    } catch (error: any) {
      console.error('Error deleting training camps:', error);
      throw new Error(`Failed to delete training camps: ${error.message || 'Unknown error'}`);
    }
  }

  // Delete all callout requests (pending and scheduled)
  static async deleteAllCallouts(): Promise<{ deletedPending: number; deletedScheduled: number }> {
    try {
      // Delete all pending callouts
      const { data: pendingCallouts, error: pendingError } = await supabase
        .from('callout_requests')
        .select('id')
        .eq('status', 'pending');

      if (pendingError) {
        console.error('Error fetching pending callouts:', pendingError);
      }

      const { error: deletePendingError } = await supabase
        .from('callout_requests')
        .delete()
        .eq('status', 'pending');

      if (deletePendingError) {
        throw new Error(`Failed to delete pending callouts: ${deletePendingError.message}`);
      }

      // Delete all scheduled callouts
      // First, get scheduled callouts to find associated scheduled fights
      const { data: scheduledCallouts, error: scheduledError } = await supabase
        .from('callout_requests')
        .select('id, scheduled_fight_id')
        .eq('status', 'scheduled');

      if (scheduledError) {
        console.error('Error fetching scheduled callouts:', scheduledError);
      }

      // Cancel associated scheduled fights (set status to 'Cancelled')
      const scheduledFightIds = scheduledCallouts?.map(c => c.scheduled_fight_id).filter(Boolean) || [];
      if (scheduledFightIds.length > 0) {
        const { error: cancelFightsError } = await supabase
          .from('scheduled_fights')
          .update({ status: 'Cancelled' })
          .in('id', scheduledFightIds);

        if (cancelFightsError) {
          console.error('Error cancelling associated scheduled fights:', cancelFightsError);
          // Don't throw - continue with deleting callouts even if fight cancellation fails
        }
      }

      const { error: deleteScheduledError } = await supabase
        .from('callout_requests')
        .delete()
        .eq('status', 'scheduled');

      if (deleteScheduledError) {
        throw new Error(`Failed to delete scheduled callouts: ${deleteScheduledError.message}`);
      }

      const deletedPending = pendingCallouts?.length || 0;
      const deletedScheduled = scheduledCallouts?.length || 0;

      // Note: Real-time updates will be automatically triggered by postgres_changes events
      // No need for manual broadcast - components subscribed to callout_requests will update automatically

      return {
        deletedPending,
        deletedScheduled
      };
    } catch (error: any) {
      console.error('Error deleting callouts:', error);
      throw new Error(`Failed to delete callouts: ${error.message || 'Unknown error'}`);
    }
  }

  // Delete all chat messages from the League Chat Room
  static async deleteAllChatMessages(): Promise<{ deletedCount: number }> {
    try {
      // First, get count of all messages
      const { data: allMessages, error: countError } = await supabase
        .from('chat_messages')
        .select('id');

      if (countError) {
        throw new Error(`Failed to fetch chat messages: ${countError.message}`);
      }

      const totalCount = allMessages?.length || 0;

      if (totalCount === 0) {
        return { deletedCount: 0 };
      }

      // Delete all chat messages using a condition that matches all rows
      // Using .gte('created_at', '1970-01-01') which will match all messages
      const { error: deleteError } = await supabase
        .from('chat_messages')
        .delete()
        .gte('created_at', '1970-01-01'); // This will match all messages since all have created_at >= 1970

      if (deleteError) {
        throw new Error(`Failed to delete chat messages: ${deleteError.message}`);
      }

      // Note: Real-time updates will be automatically triggered by postgres_changes events
      // Components subscribed to chat_messages will update automatically

      return {
        deletedCount: totalCount
      };
    } catch (error: any) {
      console.error('Error deleting chat messages:', error);
      throw new Error(`Failed to delete chat messages: ${error.message || 'Unknown error'}`);
    }
  }
}
