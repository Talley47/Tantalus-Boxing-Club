import { createClient, SupabaseClient } from '@supabase/supabase-js';

// Supabase configuration
// SECURITY: Environment variables are REQUIRED - no hardcoded fallbacks in production
const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

// Debug logging in development
if (process.env.NODE_ENV === 'development') {
  console.log('🔍 Supabase Configuration Check:');
  console.log('  URL:', supabaseUrl ? '✅ Set' : '❌ Missing');
  console.log('  Anon Key:', supabaseAnonKey ? `✅ Set (${supabaseAnonKey.length} chars)` : '❌ Missing');
  if (supabaseAnonKey) {
    console.log('  Key starts with:', supabaseAnonKey.substring(0, 30) + '...');
  }
}

// Validate required environment variables
if (!supabaseUrl || !supabaseAnonKey) {
  const errorMessage = 
    'Missing required Supabase environment variables.\n\n' +
    'Please create a .env.local file in the project root with:\n' +
    'REACT_APP_SUPABASE_URL=https://your-project.supabase.co\n' +
    'REACT_APP_SUPABASE_ANON_KEY=your-anon-key-here\n\n' +
    'Get these values from: https://supabase.com/dashboard → Your Project → Settings → API\n\n' +
    '⚠️ IMPORTANT: After creating/updating .env.local, restart your dev server (Ctrl+C then npm start)';
  
  // In production, show error but don't crash immediately
  // Let the app render so users can see the error message
  if (process.env.NODE_ENV === 'production') {
    console.error('⚠️ CRITICAL ERROR:', errorMessage);
    // Don't throw - let the app render and show error in UI
    // The AuthContext will handle showing the error
  } else {
    // In development, show helpful error
    console.error('⚠️ SECURITY WARNING:', errorMessage);
    console.warn('⚠️ Application will not function without environment variables!');
    // Still throw in development to ensure proper setup
    throw new Error(errorMessage);
  }
}

// Singleton pattern to ensure only one Supabase client instance is created
// This prevents the "Multiple GoTrueClient instances detected" warning
// Use global variable to persist across hot module reloads in development
declare global {
  interface Window {
    __TANTALUS_SUPABASE_CLIENT__?: SupabaseClient;
  }
}

const getSupabaseClient = (): SupabaseClient => {
  // Ensure environment variables are set (validation happens above)
  if (!supabaseUrl || !supabaseAnonKey) {
    // In production, create a dummy client that will fail gracefully
    // This prevents the app from crashing with a white screen
    if (process.env.NODE_ENV === 'production') {
      // Return a dummy client that will show errors in the UI
      return createClient('https://placeholder.supabase.co', 'placeholder-key');
    }
    throw new Error('Supabase configuration is missing. Please check your environment variables.');
  }
  
  // In development, allow clearing cached client for debugging
  if (process.env.NODE_ENV === 'development' && typeof window !== 'undefined') {
    // Add method to clear cached client (useful for debugging)
    (window as any).__CLEAR_SUPABASE_CLIENT__ = () => {
      delete window.__TANTALUS_SUPABASE_CLIENT__;
      console.log('✅ Cleared cached Supabase client. Page will reload.');
      window.location.reload();
    };
  }
  
  // Check global window object first (persists across hot reloads)
  if (typeof window !== 'undefined' && window.__TANTALUS_SUPABASE_CLIENT__) {
    if (process.env.NODE_ENV === 'development') {
      console.log('♻️ Using cached Supabase client instance');
    }
    return window.__TANTALUS_SUPABASE_CLIENT__;
  }
  
  // Create new instance
  if (process.env.NODE_ENV === 'development') {
    console.log('🆕 Creating new Supabase client instance');
  }
  const instance = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: true,
      storageKey: 'tantalus-boxing-club-auth', // Unique storage key to prevent conflicts
    },
    realtime: {
      params: {
        eventsPerSecond: 10
      },
      // Suppress WebSocket connection errors in console
      log_level: 'error' as const,
      // Handle WebSocket errors gracefully
      heartbeatIntervalMs: 30000,
    },
    global: {
      // Suppress common errors
      headers: {
        'x-client-info': 'tantalus-boxing-club'
      }
    }
  });
  
  // Store in global window object to persist across hot reloads
  if (typeof window !== 'undefined') {
    window.__TANTALUS_SUPABASE_CLIENT__ = instance;
  }
  
  return instance;
};

// Export singleton instance
export const supabase = getSupabaseClient();

// In development, expose key info for debugging (first 30 chars only for security)
if (process.env.NODE_ENV === 'development' && typeof window !== 'undefined') {
  (window as any).__CHECK_SUPABASE_KEY__ = () => {
    console.log('🔍 Current Supabase Configuration:');
    console.log('  URL:', supabaseUrl);
    console.log('  Anon Key (first 30 chars):', supabaseAnonKey?.substring(0, 30) + '...');
    console.log('  Key Length:', supabaseAnonKey?.length || 0);
    console.log('\n📋 To verify:');
    console.log('  1. Go to: https://supabase.com/dashboard');
    console.log('  2. Select project: andmtvsqqomgwphotdwf');
    console.log('  3. Go to: Settings → API');
    console.log('  4. Compare "anon public" key with what\'s shown above');
    console.log('  5. If different, update .env.local and restart server');
  };
}

// Suppress WebSocket connection errors from Supabase Realtime
// These errors are harmless and occur when Realtime is disabled or during cleanup
if (typeof window !== 'undefined') {
  // Override console.error and console.warn to filter out Realtime errors
  const originalError = console.error;
  const originalWarn = console.warn;
  
  console.error = (...args: any[]) => {
    // Filter out specific WebSocket connection errors from Supabase Realtime
    const errorMessage = args[0]?.toString() || '';
    const errorObj = args.find(arg => arg && typeof arg === 'object' && (arg.name || arg.message)) || args[0];
    const allArgs = args.join(' ');
    const errorString = errorObj ? JSON.stringify(errorObj) : '';
    
    // Check error object properties for Auth session missing errors
    // Check all arguments for error objects (console.error can be called with multiple args)
    let errorName = '';
    let errorObjMessage = '';
    for (const arg of args) {
      if (arg && typeof arg === 'object') {
        if (arg.name) errorName = arg.name;
        if (arg.message) errorObjMessage = arg.message;
        if (errorName && errorObjMessage) break; // Found both, no need to continue
      }
    }
    
    const combinedErrorText = `${errorMessage} ${errorName} ${errorObjMessage} ${allArgs} ${errorString}`;
    
    // Early return for Auth session missing errors - check this first for performance
    if (allArgs.includes('AuthSessionMissingError') || allArgs.includes('Auth session missing')) {
      // If this is a sign out error with session missing, suppress it
      if (allArgs.includes('Sign out error') || allArgs.includes('Error signing out')) {
        return;
      }
      // Also suppress if error object has AuthSessionMissingError
      if (errorName === 'AuthSessionMissingError' || errorObjMessage.includes('Auth session missing')) {
        return;
      }
    }
    
    // Suppress harmless browser extension errors and cache errors
    if (
      errorMessage.includes('listener indicated an asynchronous response') ||
      errorMessage.includes('message channel closed before a response was received') ||
      errorMessage.includes('A listener indicated an asynchronous response') ||
      errorMessage.includes('by returning true, but the message channel closed') ||
      errorMessage.includes('runtime.lastError') ||
      errorMessage.includes('Cannot create item with duplicate id') ||
      errorMessage.includes('ERR_CACHE_OPERATION_NOT_SUPPORTED') ||
      errorMessage.includes('No tab with id') ||
      errorMessage.includes('background-redux') ||
      errorMessage.includes('$ is not defined') ||
      errorMessage.includes('ReferenceError: $') ||
      allArgs.includes('listener indicated an asynchronous response') ||
      allArgs.includes('message channel closed before a response was received') ||
      allArgs.includes('by returning true, but the message channel closed') ||
      allArgs.includes('runtime.lastError') ||
      allArgs.includes('Cannot create item with duplicate id') ||
      allArgs.includes('ERR_CACHE_OPERATION_NOT_SUPPORTED') ||
      allArgs.includes('LastPass') ||
      allArgs.includes('No tab with id') ||
      allArgs.includes('background-redux') ||
      allArgs.includes('background-redux-new.js') ||
      allArgs.includes('$ is not defined') ||
      allArgs.includes('ReferenceError: $') ||
      allArgs.includes('content-script') ||
      allArgs.includes('ch-content-script') ||
      errorString.includes('listener indicated an asynchronous response') ||
      errorString.includes('message channel closed before a response was received') ||
      errorString.includes('by returning true, but the message channel closed') ||
      errorString.includes('runtime.lastError') ||
      errorString.includes('Cannot create item with duplicate id') ||
      errorString.includes('ERR_CACHE_OPERATION_NOT_SUPPORTED') ||
      errorString.includes('No tab with id') ||
      errorString.includes('background-redux') ||
      errorString.includes('$ is not defined') ||
      errorString.includes('ReferenceError: $') ||
      // Auth session missing errors (check all variations and all arguments)
      // Check if any argument contains session missing indicators
      errorMessage.includes('Auth session missing') ||
      errorMessage.includes('AuthSessionMissingError') ||
      errorMessage.includes('session missing') ||
      errorName === 'AuthSessionMissingError' ||
      errorObjMessage.includes('Auth session missing') ||
      errorObjMessage.includes('AuthSessionMissingError') ||
      errorObjMessage.includes('session missing') ||
      allArgs.includes('Auth session missing') ||
      allArgs.includes('AuthSessionMissingError') ||
      // If "Sign out error" or "Error signing out" appears with session missing indicators, suppress it
      (allArgs.includes('Sign out error') && (allArgs.includes('AuthSessionMissingError') || allArgs.includes('Auth session missing') || allArgs.includes('session missing') || errorName === 'AuthSessionMissingError' || errorObjMessage.includes('Auth session missing'))) ||
      (allArgs.includes('Error signing out') && (allArgs.includes('AuthSessionMissingError') || allArgs.includes('Auth session missing') || allArgs.includes('session missing') || errorName === 'AuthSessionMissingError' || errorObjMessage.includes('Auth session missing'))) ||
      errorString.includes('Auth session missing') ||
      errorString.includes('AuthSessionMissingError') ||
      combinedErrorText.includes('Auth session missing') ||
      combinedErrorText.includes('AuthSessionMissingError') ||
      // Check all arguments individually for error objects with session missing
      args.some((arg: any) => 
        arg && typeof arg === 'object' && (
          arg.name === 'AuthSessionMissingError' ||
          (arg.message && (arg.message.includes('Auth session missing') || arg.message.includes('session missing')))
        )
      )
    ) {
      // Silently ignore browser extension errors (e.g., Grammarly, LastPass) - they're harmless
      // Also suppress cache operation errors which are harmless
      // Also suppress Auth session missing errors (user already logged out)
      return;
    }
    
    // Only suppress Supabase Realtime WebSocket errors
    if (
      (errorMessage.includes('WebSocket is closed before the connection is established') ||
       errorMessage.includes('WebSocket connection') ||
       allArgs.includes('RealtimeClient')) &&
      (allArgs.includes('supabase') || allArgs.includes('realtime') || allArgs.includes('websocket'))
    ) {
      // Silently ignore these specific WebSocket connection errors - they're harmless
      return;
    }
    // Log all other errors normally
    originalError.apply(console, args);
  };
  
  console.warn = (...args: any[]) => {
    // Filter out Realtime subscription CHANNEL_ERROR warnings
    const warningMessage = args[0]?.toString() || '';
    const allArgs = args.join(' ');
    
    // Suppress CHANNEL_ERROR warnings from Realtime subscriptions
    if (
      (warningMessage.includes('Realtime subscription error') && allArgs.includes('CHANNEL_ERROR')) ||
      (allArgs.includes('CHANNEL_ERROR') && allArgs.includes('Realtime'))
    ) {
      // Silently ignore CHANNEL_ERROR warnings - they're expected when Realtime is disabled
      return;
    }
    
    // Suppress "Multiple GoTrueClient instances detected" warning
    // This is harmless and can occur during hot module reloading in development
    if (
      allArgs.includes('Multiple GoTrueClient instances detected') ||
      allArgs.includes('GoTrueClient') && allArgs.includes('instances detected')
    ) {
      // Silently ignore - the singleton pattern handles this, but warning can appear during HMR
      return;
    }
    
    // Log all other warnings normally
    originalWarn.apply(console, args);
  };

  // Also catch unhandled errors that might be logged by the browser
  window.addEventListener('error', (event) => {
    const errorMessage = event.message || event.error?.message || '';
    const errorFilename = event.filename || '';
    const errorName = event.error?.name || '';
    
    // Suppress jQuery ($) not defined errors from browser extension content scripts
    if (
      errorMessage.includes('$ is not defined') ||
      errorMessage.includes('ReferenceError: $') ||
      (errorName === 'ReferenceError' && errorMessage.includes('$')) ||
      errorFilename.includes('content-script') ||
      errorFilename.includes('ch-content-script')
    ) {
      event.preventDefault();
      event.stopPropagation();
      return false;
    }
    
    // Suppress browser extension errors (multiple variations)
    if (
      errorMessage.includes('listener indicated an asynchronous response') ||
      errorMessage.includes('message channel closed before a response was received') ||
      errorMessage.includes('A listener indicated an asynchronous response') ||
      errorMessage.includes('by returning true, but the message channel closed') ||
      (errorMessage.includes('asynchronous response') && errorMessage.includes('message channel')) ||
      errorMessage.includes('runtime.lastError') ||
      errorMessage.includes('Cannot create item with duplicate id') ||
      errorMessage.includes('No tab with id') ||
      errorMessage.includes('background-redux') ||
      (event.filename && (event.filename.includes('background-redux') ||
                          event.filename.includes('content-script') ||
                          event.filename.includes('ch-content-script')))
    ) {
      event.preventDefault();
      event.stopPropagation();
      return false;
    }
    if (
      errorMessage.includes('WebSocket is closed before the connection is established') ||
      errorMessage.includes('RealtimeClient') ||
      event.filename?.includes('realtime')
    ) {
      // Prevent default error handling for WebSocket errors
      event.preventDefault();
      event.stopPropagation();
      return false;
    }
  }, true);
  
  // Also suppress unhandled promise rejections from browser extensions
  // Use capture phase to catch errors early
  window.addEventListener('unhandledrejection', (event) => {
    const errorMessage = event.reason?.message || event.reason?.toString() || '';
    const errorString = JSON.stringify(event.reason) || '';
    const errorStack = event.reason?.stack || '';
    const errorName = event.reason?.name || '';
    const allErrorText = `${errorMessage} ${errorString} ${errorStack} ${errorName}`;
    
    // Suppress jQuery ($) not defined errors from browser extension content scripts
    if (
      errorMessage.includes('$ is not defined') ||
      errorMessage.includes('ReferenceError: $') ||
      (errorName === 'ReferenceError' && (errorMessage.includes('$') || errorString.includes('$'))) ||
      errorStack.includes('content-script') ||
      errorStack.includes('ch-content-script')
    ) {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
      return false;
    }
    
    // Suppress Auth session missing errors (harmless - user already logged out)
    if (
      errorMessage.includes('Auth session missing') ||
      errorMessage.includes('AuthSessionMissingError') ||
      errorMessage.includes('session missing') ||
      errorName === 'AuthSessionMissingError' ||
      errorString.includes('Auth session missing') ||
      errorString.includes('AuthSessionMissingError') ||
      allErrorText.includes('Auth session missing') ||
      allErrorText.includes('AuthSessionMissingError')
    ) {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
      return false;
    }
    
    // Suppress browser extension errors (multiple variations)
    if (
      errorMessage.includes('listener indicated an asynchronous response') ||
      errorMessage.includes('message channel closed before a response was received') ||
      errorMessage.includes('A listener indicated an asynchronous response') ||
      errorMessage.includes('by returning true, but the message channel closed') ||
      (errorMessage.includes('asynchronous response') && errorMessage.includes('message channel')) ||
      errorMessage.includes('runtime.lastError') ||
      errorMessage.includes('Cannot create item with duplicate id') ||
      errorMessage.includes('No tab with id') ||
      errorMessage.includes('background-redux') ||
      errorString.includes('listener indicated') ||
      errorString.includes('message channel closed') ||
      errorString.includes('by returning true') ||
      errorString.includes('runtime.lastError') ||
      errorString.includes('Cannot create item with duplicate id') ||
      errorString.includes('LastPass') ||
      errorString.includes('No tab with id') ||
      errorString.includes('background-redux') ||
      errorStack.includes('listener indicated') ||
      errorStack.includes('message channel') ||
      errorStack.includes('by returning true') ||
      errorStack.includes('background-redux') ||
      errorStack.includes('background-redux-new.js') ||
      errorStack.includes('content-script') ||
      errorStack.includes('ch-content-script') ||
      allErrorText.includes('listener indicated an asynchronous response') ||
      allErrorText.includes('message channel closed before a response was received') ||
      allErrorText.includes('by returning true, but the message channel closed') ||
      allErrorText.includes('runtime.lastError') ||
      allErrorText.includes('Cannot create item with duplicate id') ||
      allErrorText.includes('No tab with id') ||
      allErrorText.includes('background-redux') ||
      allErrorText.includes('background-redux-new.js') ||
      allErrorText.includes('$ is not defined') ||
      allErrorText.includes('ReferenceError: $')
    ) {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
      return false;
    }
  }, true); // Use capture phase
}

// Database table names
export const TABLES = {
  USERS: 'users',
  FIGHTER_PROFILES: 'fighter_profiles',
  FIGHT_RECORDS: 'fight_records',
  RANKINGS: 'rankings',
  MATCHMAKING_REQUESTS: 'matchmaking_requests',
  SCHEDULED_FIGHTS: 'scheduled_fights',
  DISPUTES: 'disputes',
  TOURNAMENTS: 'tournaments',
  TOURNAMENT_PARTICIPANTS: 'tournament_participants',
  TOURNAMENT_BRACKETS: 'tournament_brackets',
  TOURNAMENT_RESULTS: 'tournament_results',
  TOURNAMENT_CHAMPIONS: 'tournament_champions',
  TOURNAMENT_ELIGIBILITY: 'tournament_eligibility',
  TITLE_BELTS: 'title_belts',
  EVENTS: 'events',
  NOTIFICATIONS: 'notifications',
  ACHIEVEMENTS: 'achievements',
  USER_ACHIEVEMENTS: 'user_achievements',
  MEDIA_ASSETS: 'media_assets',
  ANALYTICS_SNAPSHOTS: 'analytics_snapshots',
  ADMIN_LOGS: 'admin_logs'
} as const;

// Real-time subscriptions
export const subscribeToTable = (table: string, callback: (payload: any) => void) => {
  return supabase
    .channel(`${table}_changes`)
    .on('postgres_changes', 
      { event: '*', schema: 'public', table },
      callback
    )
    .subscribe();
};

// Helper functions for common operations
export const getCurrentUser = async () => {
  const { data: { user } } = await supabase.auth.getUser();
  return user;
};

export const signOut = async () => {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
};

export const getFighterProfile = async (userId: string) => {
  try {
    const { data, error } = await supabase
      .from(TABLES.FIGHTER_PROFILES)
      .select('*')
      .eq('user_id', userId)
      .maybeSingle(); // Use maybeSingle() instead of single() to return null if not found
    
    // 406 errors or "not found" errors are OK - admin accounts may not have fighter profiles
    if (error) {
      // PGRST116 means no rows found, which is fine
      if (error.code === 'PGRST116' || error.code === '406' || error.message?.includes('Not Found')) {
        return null;
      }
      throw error;
    }
    
    return data;
  } catch (error: any) {
    // Handle 406 errors gracefully (often RLS or query format issues)
    if (error.code === '406' || error.message?.includes('406')) {
      console.log('Fighter profile query returned 406 (may be RLS or admin account)');
      return null;
    }
    throw error;
  }
};

export const updateFighterProfile = async (id: string, updates: Partial<any>) => {
  const { data, error } = await supabase
    .from(TABLES.FIGHTER_PROFILES)
    .update(updates)
    .eq('id', id)
    .select()
    .single();
  
  if (error) throw error;
  return data;
};

export const getRankings = async (weightClass?: string) => {
  let query = supabase
    .from(TABLES.RANKINGS)
    .select('*')
    .order('rank', { ascending: true });
  
  if (weightClass) {
    query = query.eq('weight_class', weightClass);
  }
  
  const { data, error } = await query;
  if (error) throw error;
  return data;
};

export const getFightRecords = async (fighterId: string) => {
  const { data, error } = await supabase
    .from(TABLES.FIGHT_RECORDS)
    .select('*')
    .eq('fighter_id', fighterId)
    .order('date', { ascending: false });
  
  if (error) throw error;
  return data;
};

export const addFightRecord = async (record: any) => {
  const { data, error } = await supabase
    .from(TABLES.FIGHT_RECORDS)
    .insert(record)
    .select()
    .single();
  
  if (error) throw error;
  return data;
};

export const getNotifications = async (userId: string) => {
  const { data, error } = await supabase
    .from(TABLES.NOTIFICATIONS)
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false });
  
  if (error) throw error;
  return data;
};

export const markNotificationAsRead = async (notificationId: string) => {
  const { error } = await supabase
    .from(TABLES.NOTIFICATIONS)
    .update({ is_read: true })
    .eq('id', notificationId);
  
  if (error) throw error;
};

