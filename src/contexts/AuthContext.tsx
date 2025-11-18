import React, { createContext, useContext, useEffect, useState } from 'react';
import { User as SupabaseUser } from '@supabase/supabase-js';
import { supabase, getFighterProfile } from '../services/supabase';
import { FighterProfile, User } from '../types';

interface AuthContextType {
  user: SupabaseUser | null;
  fighterProfile: FighterProfile | null;
  loading: boolean;
  signUp: (email: string, password: string, userData: any) => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  updateFighterProfile: (updates: Partial<FighterProfile>) => Promise<void>;
  refreshFighterProfile: () => Promise<void>;
  isAdmin: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: React.ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<SupabaseUser | null>(null);
  const [fighterProfile, setFighterProfile] = useState<FighterProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Set loading to false immediately on mount - don't wait for session check
    // This allows the app to render while auth state is determined
    setLoading(false);
    
    // Get initial session - fast and non-blocking
    const getInitialSession = async () => {
      try {
        // Use a very short timeout - just try to get from localStorage quickly
        const sessionPromise = supabase.auth.getSession();
        const timeoutPromise = new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Auth check timeout')), 1000)
        );

        let session: any = null;
        try {
          const result = await Promise.race([sessionPromise, timeoutPromise]) as any;
          session = result?.data?.session;
          setUser(session?.user ?? null);
        } catch (timeoutError: any) {
          // Timeout is fine - just continue
          // The onAuthStateChange listener will handle it
          setUser(null);
          setFighterProfile(null);
          return;
        }
        
        // Only try to load fighter profile if we have a session
        if (session?.user) {
          // Load profile asynchronously - don't wait for it
          (async () => {
            try {
              // Check if admin first
              const { data: profile } = await supabase
                .from('profiles')
                .select('role')
                .eq('id', session.user.id)
                .maybeSingle();
              
              if (profile?.role === 'admin') {
                setFighterProfile(null);
                return;
              }
              
              // Load fighter profile
              await loadFighterProfile(session.user.id);
            } catch (error) {
              // Silently fail - profile loading is non-critical
              setFighterProfile(null);
            }
          })();
        }
      } catch (error: any) {
        // Silent fail
        setUser(null);
        setFighterProfile(null);
      }
    };

    // Run initial session check, but don't block
    getInitialSession();

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        // Always set loading to false immediately - never block the UI
        setLoading(false);
        
        try {
          // Update user state immediately
          setUser(session?.user ?? null);
          
          if (session?.user) {
            // Check if user is admin and load profile asynchronously (non-blocking)
            (async () => {
              try {
                const { data: profile } = await supabase
                  .from('profiles')
                  .select('role')
                  .eq('id', session.user.id)
                  .maybeSingle();
                
                // If user is admin, skip fighter profile loading
                if (profile?.role === 'admin') {
                  setFighterProfile(null);
                  return;
                }
                
                // Load fighter profile (non-blocking)
                await loadFighterProfile(session.user.id);
              } catch (profileError: any) {
                // Silently handle errors - profile loading is non-critical
                setFighterProfile(null);
              }
            })();
          } else {
            // No session - clear everything
            setFighterProfile(null);
          }
        } catch (error) {
          console.error('Auth state change error:', error);
          setFighterProfile(null);
        }
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  const loadFighterProfile = async (userId: string) => {
    try {
      const profile = await getFighterProfile(userId);
      setFighterProfile(profile);
    } catch (error) {
      // Admin accounts may not have fighter profiles - this is OK
      console.log('No fighter profile found (OK for admin accounts)');
      setFighterProfile(null);
    }
  };

  const refreshFighterProfile = async () => {
    if (user?.id) {
      await loadFighterProfile(user.id);
    }
  };

  const signUp = async (email: string, password: string, userData: any) => {
    setLoading(true);
    try {
      // Validate and normalize email
      if (!email || !email.trim()) {
        throw new Error('Email is required');
      }
      
      const normalizedEmail = email.trim().toLowerCase();
      
      // Basic email format validation
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(normalizedEmail)) {
        throw new Error('Please enter a valid email address');
      }
      
      console.log('Starting signUp process with email:', normalizedEmail);
      console.log('UserData being sent to Supabase:', JSON.stringify(userData, null, 2));
      
      const { data, error } = await supabase.auth.signUp({
        email: normalizedEmail,
        password,
        options: {
          data: {
            ...userData,
            role: 'fighter' // Add role to user metadata
          }
        }
      });
      
      if (data?.user) {
        console.log('User created successfully. User metadata:', JSON.stringify(data.user.user_metadata, null, 2));
      }

      if (error) {
        // Don't log "User already registered" as an error - it's expected and user-friendly
        // Only log unexpected errors
        const isExpectedError = 
          error.message?.toLowerCase().includes('already registered') ||
          error.message?.toLowerCase().includes('user already registered') ||
          error.message?.toLowerCase().includes('email already registered');
        
        if (!isExpectedError) {
          console.error('Supabase auth error:', error);
        }
        
        // Create a more user-friendly error message
        const friendlyError = new Error(error.message);
        (friendlyError as any).status = error.status;
        (friendlyError as any).code = error.status;
        throw friendlyError;
      }

      console.log('Auth signup successful, user:', data.user);

      // Wait a moment for the trigger to run, then verify/update the fighter profile
      if (data.user) {
        try {
          // Wait 1 second for the trigger to complete
          await new Promise(resolve => setTimeout(resolve, 1000));
          
          // Check if fighter profile exists and has correct data
          const { data: existingProfile, error: profileError } = await supabase
            .from('fighter_profiles')
            .select('*')
            .eq('user_id', data.user.id)
            .single();
          
          if (profileError && profileError.code !== 'PGRST116') {
            console.error('Error checking fighter profile:', profileError);
          }
          
          // If profile doesn't exist or has default values, create/update it
          const needsUpdate = !existingProfile || 
            existingProfile.height_feet === 5 || 
            existingProfile.height_inches === 8 || 
            existingProfile.weight === 150 || 
            existingProfile.reach === 70 ||
            !existingProfile.fighterName || existingProfile.name === 'Fighter';
          
          if (needsUpdate) {
            console.log('Fighter profile missing or has defaults. Creating/updating with registration data...');
            
            // Convert registration data to database format
            // Registration sends height_feet and height_inches directly (already in imperial)
            const heightFeet = userData.height_feet != null ? parseInt(String(userData.height_feet)) : null;
            // height_inches can be 0, so use nullish coalescing instead of || to preserve 0
            const heightInches = userData.height_inches != null ? parseInt(String(userData.height_inches)) : 0;
            // Registration sends reach in cm, convert to inches
            const reach = userData.reach ? Math.round(parseFloat(String(userData.reach)) / 2.54) : null;
            // Registration sends weight in kg, convert to lbs
            const weight = userData.weight ? Math.round(parseFloat(String(userData.weight)) / 0.453592) : null;
            
            const profileData: any = {
              user_id: data.user.id,
              name: userData.fighterName || userData.fighter_name || 'Fighter',
              handle: (userData.fighterName || userData.fighter_name || 'Fighter').toLowerCase().replace(/\s+/g, '_'),
              birthday: userData.birthday || null,
              hometown: userData.hometown || null,
              stance: userData.stance ? userData.stance.toLowerCase() : 'orthodox',
              height_feet: heightFeet ?? null,
              height_inches: heightInches ?? 0, // Default to 0 if null (required field)
              reach: reach || null,
              weight: weight || null,
              weight_class: userData.weightClass || userData.weight_class || 'Middleweight',
              trainer: userData.trainer || null,
              gym: userData.gym || null,
              platform: userData.platform || null,
              timezone: userData.timezone || null,
              tier: 'amateur',
              points: 0,
              wins: 0,
              losses: 0,
              draws: 0
            };
            
            if (existingProfile) {
              // Update existing profile
              const { error: updateError } = await supabase
                .from('fighter_profiles')
                .update(profileData)
                .eq('user_id', data.user.id);
              
              if (updateError) {
                console.error('Error updating fighter profile:', updateError);
              } else {
                console.log('Fighter profile updated successfully with registration data');
              }
            } else {
              // Create new profile
              const { error: insertError } = await supabase
                .from('fighter_profiles')
                .insert(profileData);
              
              if (insertError) {
                console.error('Error creating fighter profile:', insertError);
              } else {
                console.log('Fighter profile created successfully with registration data');
              }
            }
          } else {
            console.log('Fighter profile already exists with correct data');
          }
        } catch (profileError: any) {
          console.error('Error ensuring fighter profile:', profileError);
          // Don't fail registration - profile can be created later
        }
      }
      
      // Try to automatically sign in after successful registration
      // If email confirmation is required, this will fail gracefully
      try {
        if (data.user) {
          await signIn(normalizedEmail, password);
        }
      } catch (signInError: any) {
        console.log('Automatic sign-in failed (likely due to email confirmation):', signInError.message);
        // Don't throw the error - registration was successful
        // User will need to confirm email or login manually
      }
    } catch (error) {
      console.error('Sign up error:', error);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const signIn = async (email: string, password: string) => {
    try {
      // Validate input
      if (!email || !email.trim()) {
        throw new Error('Email is required');
      }
      if (!password || !password.trim()) {
        throw new Error('Password is required');
      }

      // Don't set loading - let auth state change handle it
      // This prevents blocking the UI during login
      const { data, error } = await supabase.auth.signInWithPassword({
        email: email.trim().toLowerCase(),
        password: password
      });

      if (error) {
        // Don't log "Invalid login credentials" as an error - it's expected and user-friendly
        // Only log unexpected errors
        const isExpectedError = 
          error.message?.toLowerCase().includes('invalid login credentials') ||
          error.message?.toLowerCase().includes('invalid credentials') ||
          error.message?.toLowerCase().includes('email not confirmed');
        
        if (!isExpectedError) {
          console.error('Sign in error:', error);
        }
        
        // Create a more user-friendly error message
        const errorMessage = error.message || 'Invalid login credentials';
        const friendlyError = new Error(errorMessage);
        (friendlyError as any).originalError = error;
        throw friendlyError;
      }

      if (!data.user) {
        throw new Error('Login failed: No user data returned');
      }
      
      // The onAuthStateChange listener will handle setting user and loading states
      // No return value needed
    } catch (error: any) {
      // Don't log "Invalid login credentials" as an error - it's expected and user-friendly
      const isExpectedError = 
        error?.message?.toLowerCase().includes('invalid login credentials') ||
        error?.message?.toLowerCase().includes('invalid credentials') ||
        error?.originalError?.message?.toLowerCase().includes('invalid login credentials') ||
        error?.originalError?.message?.toLowerCase().includes('invalid credentials');
      
      if (!isExpectedError) {
        console.error('Sign in error:', error);
      }
      
      // Re-throw with better error message if it's a Supabase error
      if (error.originalError) {
        throw error; // Already has friendly message
      }
      throw error;
    }
  };

  const signOut = async () => {
    setLoading(true);
    try {
      // Check if there's an active session before trying to sign out
      const { data: { session } } = await supabase.auth.getSession();
      
      if (!session) {
        // No active session - user is already logged out
        // Clear localStorage directly as a fallback (defensive)
        try {
          localStorage.removeItem('tantalus-boxing-club-auth');
        } catch (e) {
          // Ignore localStorage errors (private browsing, etc.)
        }
        setUser(null);
        setLoading(false);
        return;
      }
      
      // There's an active session - sign out with 'local' scope
      // 'local' just clears the cached session in this client (no refresh token needed)
      // 'global' would revoke all sessions but requires a valid refresh token
      // IMPORTANT: Explicitly pass scope as 'local' to avoid 403 errors
      const { error } = await supabase.auth.signOut({ scope: 'local' as const });
      
      if (error) {
        // If session is already missing or 403 error, that's fine - user is already logged out
        // This can happen if session expired between check and signOut call
        const isSessionError = 
          error.message?.includes('Auth session missing') || 
          error.name === 'AuthSessionMissingError' ||
          error.message?.includes('session missing') ||
          error.message?.includes('403') ||
          error.code === '403';
        
        if (isSessionError) {
          // Silently handle - user is already logged out
          // Clear localStorage directly as fallback
          try {
            localStorage.removeItem('tantalus-boxing-club-auth');
          } catch (e) {
            // Ignore localStorage errors
          }
          setUser(null);
          setLoading(false);
          return;
        }
        // For other errors, log but still clear local state (defensive)
        console.warn('Sign out error (clearing local state anyway):', error);
        // Clear localStorage as fallback
        try {
          localStorage.removeItem('tantalus-boxing-club-auth');
        } catch (e) {
          // Ignore localStorage errors
        }
        setUser(null);
        setLoading(false);
        return;
      }
      
      // Successfully signed out
      setUser(null);
    } catch (error: any) {
      // Check if this is a session missing or 403 error
      const isSessionError = 
        error?.message?.includes('Auth session missing') || 
        error?.name === 'AuthSessionMissingError' ||
        error?.message?.includes('session missing') ||
        error?.message?.includes('403') ||
        error?.code === '403' ||
        error?.toString()?.includes('Auth session missing') ||
        error?.toString()?.includes('AuthSessionMissingError');
      
      // Don't log session missing/403 errors - they're harmless (user already logged out)
      // These errors are expected when the session is already expired/missing
      // The console.error override in supabase.ts will suppress these automatically
      // Only log actual unexpected errors (not session missing)
      if (!isSessionError) {
        // Use console.warn instead of console.error for non-critical errors
        console.warn('Sign out error (clearing local state anyway):', error);
      }
      // Note: AuthSessionMissingError is automatically suppressed by console.error override
      
      // Clear localStorage as fallback to ensure session is removed
      try {
        localStorage.removeItem('tantalus-boxing-club-auth');
      } catch (e) {
        // Ignore localStorage errors (private browsing, etc.)
      }
      
      // Clear local state even if there was an error (user is effectively logged out)
      // This ensures the UI updates to logged-out state regardless of API errors
      setUser(null);
    } finally {
      setLoading(false);
    }
  };

  const updateFighterProfile = async (updates: Partial<FighterProfile>) => {
    if (!fighterProfile) return;

    try {
      // Filter out undefined values and ensure platform is valid if provided
      const cleanUpdates: any = {};
      // Columns that don't exist in fighter_profiles table - exclude from updates
      const excludedColumns = ['platform_id', 'id', 'user_id', 'created_at', 'updated_at', 'last_active']; // Exclude read-only fields
      
      // Required fields that must have default values if null/undefined
      const requiredNumericFields = ['height_feet', 'height_inches', 'weight', 'reach'];
      
      Object.keys(updates).forEach((key) => {
        const value = (updates as any)[key];
        // Skip excluded columns
        if (excludedColumns.includes(key)) {
          return; // Skip read-only or non-existent columns
        }
        
        // For required numeric fields, ensure they have a default value if null/undefined/NaN
        if (requiredNumericFields.includes(key)) {
          // If the field is explicitly in updates, we must provide a value (can't skip it)
          // Use current profile value as fallback, or sensible defaults
          let numValue: number;
          if (value === undefined || value === null || value === '' || (typeof value === 'number' && isNaN(value))) {
            // Use current profile value if available, otherwise use defaults
            const currentValue = (fighterProfile as any)[key];
            if (currentValue !== undefined && currentValue !== null && !isNaN(currentValue)) {
              numValue = Number(currentValue);
            } else {
              // Use sensible defaults based on field
              if (key === 'height_feet') {
                numValue = 5;
              } else if (key === 'height_inches') {
                numValue = 8;
              } else if (key === 'weight') {
                numValue = 150;
              } else if (key === 'reach') {
                numValue = 70;
              } else {
                numValue = 0;
              }
            }
          } else {
            numValue = typeof value === 'string' ? parseInt(value, 10) : Number(value);
            // If parsing resulted in NaN, use fallback
            if (isNaN(numValue)) {
              const currentValue = (fighterProfile as any)[key];
              numValue = (currentValue !== undefined && currentValue !== null && !isNaN(currentValue)) 
                ? Number(currentValue) 
                : (key === 'height_inches' ? 8 : key === 'height_feet' ? 5 : key === 'weight' ? 150 : key === 'reach' ? 70 : 0);
            }
          }
          cleanUpdates[key] = numValue;
        } else if (value !== undefined && value !== null && value !== '') {
          // Ensure platform value matches database constraint if provided
          if (key === 'platform' && value) {
            const platformValue = value as string;
            if (['PSN', 'Xbox', 'PC'].includes(platformValue)) {
              cleanUpdates[key] = platformValue;
            } else {
              console.warn(`Invalid platform value: ${platformValue}, defaulting to PC`);
              cleanUpdates[key] = 'PC';
            }
          } else if (key === 'tier' && value) {
            // Normalize tier to match database constraint
            const tierValue = value as string;
            const validTiers = ['Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite'];
            // Map old tier values to new ones
            const tierMap: Record<string, string> = {
              'bronze': 'Amateur',
              'silver': 'Semi-Pro',
              'gold': 'Pro',
              'platinum': 'Contender',
              'diamond': 'Elite',
              'amateur': 'Amateur',
              'semi-pro': 'Semi-Pro',
              'semi_pro': 'Semi-Pro',
              'pro': 'Pro',
              'contender': 'Contender',
              'elite': 'Elite',
              'champion': 'Elite'
            };
            const normalizedTier = tierMap[tierValue.toLowerCase()] || tierValue;
            if (validTiers.includes(normalizedTier)) {
              cleanUpdates[key] = normalizedTier;
            } else {
              console.warn(`Invalid tier value: ${tierValue}, defaulting to Amateur`);
              cleanUpdates[key] = 'Amateur';
            }
          } else if (key === 'stance' && value) {
            // Normalize stance to lowercase to match database constraint
            const stanceValue = (value as string).toLowerCase();
            if (['orthodox', 'southpaw', 'switch'].includes(stanceValue)) {
              cleanUpdates[key] = stanceValue;
            } else {
              console.warn(`Invalid stance value: ${stanceValue}, defaulting to orthodox`);
              cleanUpdates[key] = 'orthodox';
            }
          } else if (key === 'birthday' && value) {
            // Ensure birthday is in correct format (YYYY-MM-DD)
            if (typeof value === 'string') {
              // If it's already in YYYY-MM-DD format, use it
              if (/^\d{4}-\d{2}-\d{2}$/.test(value)) {
                cleanUpdates[key] = value;
              } else {
                // Try to parse and format
                const date = new Date(value);
                if (!isNaN(date.getTime())) {
                  cleanUpdates[key] = date.toISOString().split('T')[0];
                } else {
                  console.warn(`Invalid birthday format: ${value}, skipping`);
                }
              }
            } else {
              cleanUpdates[key] = value;
            }
          } else {
            cleanUpdates[key] = value;
          }
        }
      });

      // Ensure we have at least one field to update
      if (Object.keys(cleanUpdates).length === 0) {
        console.warn('No valid fields to update');
        return;
      }

      const { data, error } = await supabase
        .from('fighter_profiles')
        .update(cleanUpdates)
        .eq('user_id', fighterProfile.user_id)
        .select()
        .single();

      if (error) {
        // Log detailed error information for debugging
        console.error('Supabase update error:', {
          message: error.message,
          code: error.code,
          details: error.details,
          hint: error.hint,
          updatePayload: cleanUpdates,
          fighterProfileId: fighterProfile.id,
          userId: fighterProfile.user_id
        });
        
        // Provide more user-friendly error messages
        if (error.code === '23505') {
          throw new Error('A fighter profile with this information already exists. Please check your input.');
        } else if (error.code === '23503') {
          throw new Error('Invalid reference. Please refresh the page and try again.');
        } else if (error.code === '23502') {
          throw new Error('Missing required field. Please fill in all required fields.');
        } else if (error.code === '42501') {
          throw new Error('Permission denied. Please ensure you are logged in and have permission to update your profile.');
        } else if (error.message?.includes('violates check constraint')) {
          throw new Error('Invalid value provided. Please check your input and try again.');
        } else {
          throw new Error(error.message || 'Failed to update fighter profile. Please try again.');
        }
      }

      setFighterProfile(data);
    } catch (error: any) {
      // Only log unexpected errors (not user-friendly messages we created)
      if (!error.message || error.message.includes('Please')) {
        console.error('Error updating fighter profile:', error);
      }
      throw error;
    }
  };

  const isAdmin = user?.email === 'tantalusboxingclub@gmail.com' || user?.app_metadata?.role === 'admin';

  const value: AuthContextType = {
    user,
    fighterProfile,
    loading,
    signUp,
    signIn,
    signOut,
    updateFighterProfile,
    refreshFighterProfile,
    isAdmin
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

