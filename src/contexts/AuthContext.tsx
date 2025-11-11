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
        console.error('Supabase auth error:', error);
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
            const heightFeet = userData.height_feet ? parseInt(String(userData.height_feet)) : null;
            const heightInches = userData.height_inches ? parseInt(String(userData.height_inches)) : null;
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
              height_feet: heightFeet || null,
              height_inches: heightInches || null,
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
        console.error('Sign in error:', error);
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
      console.error('Sign in error:', error);
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
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
    } catch (error) {
      console.error('Sign out error:', error);
      throw error;
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
      const excludedColumns = ['platform_id']; // platform_id doesn't exist, but platform and timezone do
      
      // Required fields that must have default values if null/undefined
      const requiredNumericFields = ['height_feet', 'height_inches', 'weight', 'reach'];
      
      Object.keys(updates).forEach((key) => {
        const value = (updates as any)[key];
        // Skip excluded columns
        if (excludedColumns.includes(key)) {
          return; // Skip platform_id - this column doesn't exist
        }
        
        // For required numeric fields, ensure they have a default value (0) if null/undefined
        if (requiredNumericFields.includes(key)) {
          if (value === undefined || value === null || value === '') {
            cleanUpdates[key] = 0; // Default to 0 for required numeric fields
          } else {
            const numValue = typeof value === 'string' ? parseInt(value) || 0 : Number(value) || 0;
            cleanUpdates[key] = numValue;
          }
        } else if (value !== undefined && value !== null) {
          // Ensure platform value matches database constraint if provided
          if (key === 'platform' && value) {
            const platformValue = value as string;
            if (['PSN', 'Xbox', 'PC'].includes(platformValue)) {
              cleanUpdates[key] = platformValue;
            } else {
              console.warn(`Invalid platform value: ${platformValue}, defaulting to PC`);
              cleanUpdates[key] = 'PC';
            }
          } else {
            cleanUpdates[key] = value;
          }
        }
      });

      const { data, error } = await supabase
        .from('fighter_profiles')
        .update(cleanUpdates)
        .eq('user_id', fighterProfile.user_id)
        .select()
        .single();

      if (error) {
        console.error('Supabase update error:', error);
        console.error('Update payload:', cleanUpdates);
        throw error;
      }

      setFighterProfile(data);
    } catch (error) {
      console.error('Error updating fighter profile:', error);
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

