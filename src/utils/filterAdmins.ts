import { supabase } from '../services/supabase';

/**
 * Filters out admin users from a list of user IDs
 * @param userIds Array of user IDs to filter
 * @returns Array of user IDs that are not admins
 */
export async function filterAdminUsers(userIds: string[]): Promise<string[]> {
  if (userIds.length === 0) return [];
  
  try {
    // Get profiles to check roles
    const { data: profiles, error } = await supabase
      .from('profiles')
      .select('id, role')
      .in('id', userIds);
    
    if (error) {
      console.warn('Error filtering admin users:', error);
      return userIds; // Return all if error (better than filtering incorrectly)
    }
    
    // Filter out admin users
    const nonAdminIds = profiles
      ?.filter(p => p.role !== 'admin')
      .map(p => p.id) || [];
    
    return nonAdminIds;
  } catch (error) {
    console.warn('Error filtering admin users:', error);
    return userIds; // Return all if error
  }
}

/**
 * Filters fighter profiles to exclude admin users
 * Uses a join to check the profiles table for role
 */
export async function filterAdminFighters<T extends { user_id: string }>(
  fighters: T[]
): Promise<T[]> {
  if (fighters.length === 0) return [];

  try {
    // Get all user IDs from fighters
    const userIds = fighters.map(f => f.user_id).filter(Boolean);
    if (userIds.length === 0) {
      console.log('[filterAdminFighters] No user_ids found in fighters array');
      return fighters;
    }
    
    if (process.env.NODE_ENV === 'development') {
      console.log(`[filterAdminFighters] Checking ${userIds.length} user IDs for admin status`);
    }
    
    // Query profiles table directly to check roles
    const { data: profiles, error } = await supabase
      .from('profiles')
      .select('id, role')
      .in('id', userIds);
    
    if (error) {
      console.error('[filterAdminFighters] Error querying profiles:', error);
      console.error('Error details:', {
        message: error.message,
        code: error.code,
        details: error.details,
        hint: error.hint
      });
      
      // If RLS is blocking, log a warning but return all fighters
      // This prevents false filtering
      console.warn('[filterAdminFighters] Cannot verify admin status - returning all fighters');
      return fighters;
    }
    
    if (!profiles || profiles.length === 0) {
      // Silently return all fighters if profiles don't exist (common for new users)
      // This is expected behavior - profiles may not exist yet for all users
      if (process.env.NODE_ENV === 'development') {
        console.info(`[filterAdminFighters] No profiles found for ${userIds.length} user IDs - returning all fighters (this is normal if profiles haven't been created yet)`);
      }
      return fighters;
    }
    
    console.log(`[filterAdminFighters] Found ${profiles.length} profiles out of ${userIds.length} user IDs`);
    
    // Create a set of admin user IDs
    // Check for 'admin' role (case-insensitive)
    const adminIds = new Set(
      profiles
        .filter(p => p.role && p.role.toLowerCase().trim() === 'admin')
        .map(p => p.id)
    );
    
    if (adminIds.size > 0) {
      console.log(`[filterAdminFighters] ✅ Filtered out ${adminIds.size} admin account(s) from ${fighters.length} fighters`);
      console.log('[filterAdminFighters] Admin user IDs:', Array.from(adminIds));
      
      // Log which fighters are being filtered
      const adminFighters = fighters.filter(f => adminIds.has(f.user_id));
      console.log('[filterAdminFighters] Admin fighters being removed:', adminFighters.map(f => ({
        name: (f as any).name || 'Unknown',
        handle: (f as any).handle || 'unknown',
        user_id: f.user_id
      })));
    } else {
      console.log('[filterAdminFighters] No admin accounts found in profiles');
      console.log('[filterAdminFighters] All profiles checked:', profiles.map(p => ({ 
        id: p.id, 
        role: p.role || 'null',
        role_type: typeof p.role
      })));
    }
    
    // Filter out fighters with admin user IDs
    const filtered = fighters.filter(f => !adminIds.has(f.user_id));
    
    if (filtered.length !== fighters.length) {
      console.log(`[filterAdminFighters] Result: ${fighters.length} → ${filtered.length} fighters (removed ${fighters.length - filtered.length} admin accounts)`);
    } else {
      console.log(`[filterAdminFighters] No filtering needed - all ${fighters.length} fighters are non-admin`);
    }
    
    return filtered;
  } catch (error) {
    console.error('[filterAdminFighters] Unexpected error:', error);
    return fighters; // Return all if error
  }
}

