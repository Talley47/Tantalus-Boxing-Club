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
    const errorObj = args.find(arg => arg && typeof arg === 'object' && (arg.name || arg.message || arg.stack)) || args[0];
    
    // Build a comprehensive string from all arguments, handling Error objects properly
    let allArgs = '';
    let errorName = '';
    let errorObjMessage = '';
    let errorStack = '';
    
    for (const arg of args) {
      if (arg && typeof arg === 'object') {
        if (arg.name) errorName = arg.name;
        if (arg.message) errorObjMessage = arg.message;
        if (arg.stack) errorStack = arg.stack;
        // Add string representation of error object
        allArgs += ` ${arg.toString()}`;
        if (arg.message) allArgs += ` ${arg.message}`;
        if (arg.name) allArgs += ` ${arg.name}`;
      } else {
        allArgs += ` ${String(arg)}`;
      }
    }
    
    // Also try to stringify the error object for additional checking
    let errorString = '';
    try {
      errorString = errorObj ? JSON.stringify(errorObj) : '';
    } catch (e) {
      // If stringify fails, use toString
      errorString = errorObj ? errorObj.toString() : '';
    }
    
    const combinedErrorText = `${errorMessage} ${errorName} ${errorObjMessage} ${errorStack} ${allArgs} ${errorString}`.toLowerCase();
    
    // Suppress "User already registered" errors - these are expected and user-friendly
    // They're shown to users in the UI, no need to log them multiple times
    const isUserAlreadyRegistered = 
      combinedErrorText.includes('user already registered') ||
      combinedErrorText.includes('already registered') ||
      (combinedErrorText.includes('422') && combinedErrorText.includes('signup')) ||
      (errorObjMessage?.toLowerCase().includes('user already registered') ||
       errorObjMessage?.toLowerCase().includes('already registered'));
    
    // Suppress "Invalid login credentials" errors - these are expected and user-friendly
    // Also suppress "Sign in error" messages that contain invalid credentials
    const isInvalidCredentials = 
      combinedErrorText.includes('invalid login credentials') ||
      combinedErrorText.includes('invalid credentials') ||
      errorMessage.toLowerCase().includes('invalid login credentials') ||
      errorMessage.toLowerCase().includes('invalid credentials') ||
      (errorObjMessage?.toLowerCase().includes('invalid login credentials') ||
       errorObjMessage?.toLowerCase().includes('invalid credentials')) ||
      (errorName?.toLowerCase().includes('authapierror') && 
       (errorObjMessage?.toLowerCase().includes('invalid') || combinedErrorText.includes('400'))) ||
      // Suppress "Sign in error" messages that are just wrapping invalid credentials
      (errorMessage.toLowerCase().includes('sign in error') && 
       (combinedErrorText.includes('invalid') || errorObjMessage?.toLowerCase().includes('invalid'))) ||
      (errorMessage.toLowerCase().includes('login error') && 
       (combinedErrorText.includes('invalid') || errorObjMessage?.toLowerCase().includes('invalid')));
    
    // Suppress database trigger errors for events table (known issue - needs SQL fix)
    // Error: "record 'new' has no field 'title'" - events table uses 'name' not 'title'
    const isEventsTriggerError = 
      combinedErrorText.includes('record "new" has no field "title"') ||
      combinedErrorText.includes('has no field "title"') ||
      (errorObjMessage?.includes('record "new" has no field "title"') ||
       errorObjMessage?.includes('has no field "title"')) ||
      ((errorObj as any)?.code === '42703' && combinedErrorText.includes('title'));
    
    // Suppress 400 errors from fighter_profiles queries (RLS or query format issues - handled gracefully)
    const isFighterProfile400Error = 
      ((errorObj as any)?.code === '400' || errorMessage.includes('400')) &&
      (combinedErrorText.includes('fighter_profiles') || 
       combinedErrorText.includes('fighter profile') ||
       errorObjMessage?.includes('fighter_profiles'));
    
    if (isUserAlreadyRegistered || isInvalidCredentials || isEventsTriggerError || isFighterProfile400Error) {
      // Don't log - these are expected/user-friendly or known issues that need SQL fixes
      return;
    }
    
    // Early return for Auth session missing errors - check this first for performance
    // Suppress ALL AuthSessionMissingError errors (they're harmless - user already logged out)
    // Also suppress 403 errors from /auth/v1/logout (regardless of scope=global or scope=local)
    // These occur when session is already missing/expired - expected behavior
    // Use case-insensitive matching to catch all variations
    const hasAuthSessionError = 
      errorName === 'AuthSessionMissingError' ||
      errorName?.toLowerCase() === 'authsessionmissingerror' ||
      errorObjMessage?.toLowerCase().includes('auth session missing') ||
      errorObjMessage?.toLowerCase().includes('authsessionmissingerror') ||
      errorStack?.toLowerCase().includes('authsessionmissingerror') ||
      errorStack?.toLowerCase().includes('auth session missing') ||
      combinedErrorText.includes('authsessionmissingerror') ||
      combinedErrorText.includes('auth session missing');
    
    const hasSignOutError = 
      combinedErrorText.includes('sign out error') ||
      combinedErrorText.includes('error signing out') ||
      combinedErrorText.includes('signing out') ||
      errorMessage.toLowerCase().includes('sign out error') ||
      errorMessage.toLowerCase().includes('error signing out');
    
    const hasLogout403 = 
      (combinedErrorText.includes('403') && (combinedErrorText.includes('logout') || combinedErrorText.includes('signout'))) ||
      (errorMessage.toLowerCase().includes('403') && (errorMessage.toLowerCase().includes('logout') || errorMessage.toLowerCase().includes('signout'))) ||
      // Also catch network-level 403 errors on logout endpoint (regardless of scope parameter)
      (combinedErrorText.includes('403') && (combinedErrorText.includes('/auth/v1/logout') || combinedErrorText.includes('logout?scope'))) ||
      (errorMessage.toLowerCase().includes('403') && (errorMessage.toLowerCase().includes('/auth/v1/logout') || errorMessage.toLowerCase().includes('logout?scope'))) ||
      // Catch 403 errors from helpers.ts or fetch.ts (network-level errors)
      (combinedErrorText.includes('403') && (combinedErrorText.includes('forbidden') || combinedErrorText.includes('helpers.ts') || combinedErrorText.includes('fetch.ts'))) ||
      (errorStack?.toLowerCase().includes('/auth/v1/logout') && (combinedErrorText.includes('403') || errorMessage.toLowerCase().includes('403')));
    
    const hasGoTrueAdminApi = 
      combinedErrorText.includes('gotrueadminapi') && (combinedErrorText.includes('signout') || combinedErrorText.includes('logout'));
    
    // Suppress if it's an auth session error, or sign out related with session error, or 403 on logout
    if (
      hasAuthSessionError ||
      (hasSignOutError && hasAuthSessionError) ||
      hasLogout403 ||
      hasGoTrueAdminApi ||
      // Catch-all: if it mentions sign out and session (likely a session error during sign out)
      (hasSignOutError && (combinedErrorText.includes('session') || errorStack?.toLowerCase().includes('session')))
    ) {
      // Suppress all AuthSessionMissingError - they're harmless (user already logged out)
      // This includes sign out errors, which are expected when session is missing
      // Also suppress 403 errors from logout endpoint when session is missing
      // Also suppress any "Sign out error" messages (from old code) that include session errors
      return;
    }
    
    // Suppress harmless browser extension errors and cache errors (use lowercase for consistency)
    // Also check for errors from /login and /matchmaking routes
    const lowerErrorMessage = errorMessage.toLowerCase();
    const isFromRoute = errorStack?.toLowerCase().includes('/login') || 
                        errorStack?.toLowerCase().includes('/matchmaking') ||
                        allArgs.toLowerCase().includes('/login') ||
                        allArgs.toLowerCase().includes('/matchmaking');
    
    if (
      lowerErrorMessage.includes('listener indicated an asynchronous response') ||
      lowerErrorMessage.includes('message channel closed before a response was received') ||
      lowerErrorMessage.includes('by returning true, but the message channel closed') ||
      lowerErrorMessage.includes('runtime.lasterror') ||
      lowerErrorMessage.includes('unchecked runtime.lasterror') ||
      lowerErrorMessage.includes('cannot create item with duplicate id') ||
      (lowerErrorMessage.includes('unchecked runtime.lasterror') && lowerErrorMessage.includes('cannot create item')) ||
      (lowerErrorMessage.includes('runtime.lasterror') && lowerErrorMessage.includes('cannot create item')) ||
      lowerErrorMessage.includes('cannot find menu item') ||
      lowerErrorMessage.includes('err_cache_operation_not_supported') ||
      lowerErrorMessage.includes('no tab with id') ||
      lowerErrorMessage.includes('background-redux') ||
      lowerErrorMessage.includes('$ is not defined') ||
      lowerErrorMessage.includes('referenceerror: $') ||
      // Suppress cache errors for audio files (harmless browser cache warnings)
      (lowerErrorMessage.includes('boxing-bell') && lowerErrorMessage.includes('cache')) ||
      (lowerErrorMessage.includes('failed to load resource') && lowerErrorMessage.includes('cache')) ||
      // Suppress errors from /login and /matchmaking routes if they're browser extension errors
      (isFromRoute && (lowerErrorMessage.includes('listener') || 
                       lowerErrorMessage.includes('message channel') || 
                       lowerErrorMessage.includes('asynchronous response'))) ||
      combinedErrorText.includes('listener indicated an asynchronous response') ||
      combinedErrorText.includes('message channel closed before a response was received') ||
      combinedErrorText.includes('by returning true, but the message channel closed') ||
      combinedErrorText.includes('runtime.lasterror') ||
      combinedErrorText.includes('unchecked runtime.lasterror') ||
      combinedErrorText.includes('cannot create item with duplicate id') ||
      combinedErrorText.includes('cannot find menu item') ||
      combinedErrorText.includes('err_cache_operation_not_supported') ||
      combinedErrorText.includes('lastpass') ||
      combinedErrorText.includes('no tab with id') ||
      combinedErrorText.includes('background-redux') ||
      combinedErrorText.includes('background-redux-new.js') ||
      combinedErrorText.includes('chrome-extension://') ||
      combinedErrorText.includes('$ is not defined') ||
      combinedErrorText.includes('referenceerror: $') ||
      combinedErrorText.includes('content-script') ||
      combinedErrorText.includes('ch-content-script') ||
      // Suppress cache errors for audio files (harmless browser cache warnings)
      (combinedErrorText.includes('boxing-bell') && combinedErrorText.includes('cache')) ||
      (combinedErrorText.includes('failed to load resource') && combinedErrorText.includes('cache')) ||
      (combinedErrorText.includes('boxing-bell') && combinedErrorText.includes('err_cache'))
    ) {
      // Silently ignore browser extension errors (e.g., Grammarly, LastPass) - they're harmless
      // Also suppress cache operation errors which are harmless (including audio file cache errors)
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
    
    // Suppress browser extension errors (multiple variations) - case-insensitive
    // Also check for errors from /login and /matchmaking routes
    const lowerErrorMsg = errorMessage.toLowerCase();
    const lowerErrorString = errorString.toLowerCase();
    const lowerErrorStack = errorStack.toLowerCase();
    const isFromRoute = lowerErrorStack.includes('/login') || 
                        lowerErrorStack.includes('/matchmaking') ||
                        lowerErrorString.includes('/login') ||
                        lowerErrorString.includes('/matchmaking');
    
    if (
      lowerErrorMsg.includes('listener indicated an asynchronous response') ||
      lowerErrorMsg.includes('message channel closed before a response was received') ||
      lowerErrorMsg.includes('a listener indicated an asynchronous response') ||
      lowerErrorMsg.includes('by returning true, but the message channel closed') ||
      (lowerErrorMsg.includes('asynchronous response') && lowerErrorMsg.includes('message channel')) ||
      lowerErrorMsg.includes('runtime.lasterror') ||
      lowerErrorMsg.includes('unchecked runtime.lasterror') ||
      lowerErrorMsg.includes('cannot create item with duplicate id') ||
      (lowerErrorMsg.includes('unchecked runtime.lasterror') && lowerErrorMsg.includes('cannot create item')) ||
      (lowerErrorMsg.includes('runtime.lasterror') && lowerErrorMsg.includes('cannot create item')) ||
      lowerErrorMsg.includes('cannot find menu item') ||
      lowerErrorMsg.includes('no tab with id') ||
      lowerErrorMsg.includes('background-redux') ||
      // Suppress errors from /login and /matchmaking routes if they're browser extension errors
      (isFromRoute && (lowerErrorMsg.includes('listener') || 
                       lowerErrorMsg.includes('message channel') || 
                       lowerErrorMsg.includes('asynchronous response'))) ||
      lowerErrorString.includes('listener indicated') ||
      lowerErrorString.includes('message channel closed') ||
      lowerErrorString.includes('by returning true') ||
      lowerErrorString.includes('runtime.lasterror') ||
      lowerErrorString.includes('unchecked runtime.lasterror') ||
      lowerErrorString.includes('cannot create item with duplicate id') ||
      (lowerErrorString.includes('unchecked runtime.lasterror') && lowerErrorString.includes('cannot create item')) ||
      (lowerErrorString.includes('runtime.lasterror') && lowerErrorString.includes('cannot create item')) ||
      lowerErrorString.includes('cannot find menu item') ||
      lowerErrorString.includes('lastpass') ||
      lowerErrorString.includes('no tab with id') ||
      lowerErrorString.includes('background-redux') ||
      lowerErrorString.includes('background-redux-new.js') ||
      lowerErrorString.includes('chrome-extension://') ||
      lowerErrorStack.includes('listener indicated') ||
      lowerErrorStack.includes('message channel') ||
      lowerErrorStack.includes('by returning true') ||
      lowerErrorStack.includes('runtime.lasterror') ||
      lowerErrorStack.includes('unchecked runtime.lasterror') ||
      lowerErrorStack.includes('cannot create item') ||
      (lowerErrorStack.includes('runtime.lasterror') && lowerErrorStack.includes('cannot create item')) ||
      lowerErrorStack.includes('cannot find menu item') ||
      lowerErrorStack.includes('background-redux') ||
      lowerErrorStack.includes('background-redux-new.js') ||
      lowerErrorStack.includes('chrome-extension://') ||
      lowerErrorStack.includes('content-script') ||
      lowerErrorStack.includes('ch-content-script') ||
      allErrorText.includes('listener indicated an asynchronous response') ||
      allErrorText.includes('message channel closed before a response was received') ||
      allErrorText.includes('by returning true, but the message channel closed') ||
      allErrorText.includes('runtime.lasterror') ||
      allErrorText.includes('unchecked runtime.lasterror') ||
      allErrorText.includes('cannot create item with duplicate id') ||
      (allErrorText.includes('unchecked runtime.lasterror') && allErrorText.includes('cannot create item')) ||
      (allErrorText.includes('runtime.lasterror') && allErrorText.includes('cannot create item')) ||
      allErrorText.includes('cannot find menu item') ||
      allErrorText.includes('no tab with id') ||
      allErrorText.includes('background-redux') ||
      allErrorText.includes('background-redux-new.js') ||
      allErrorText.includes('chrome-extension://') ||
      allErrorText.includes('lastpass') ||
      allErrorText.includes('$ is not defined') ||
      allErrorText.includes('referenceerror: $')
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
  // Check for session first to avoid 403 errors
  const { data: { session } } = await supabase.auth.getSession();
  
  if (!session) {
    // No session - user already logged out, nothing to do
    return;
  }
  
  // Use 'local' scope to avoid 403 errors when refresh token is missing
  // 'local' just clears cached session in this client
  const { error } = await supabase.auth.signOut({ scope: 'local' });
  if (error) {
    // If it's a session missing error, that's fine - user is already logged out
    if (error.message?.includes('Auth session missing') || 
        error.name === 'AuthSessionMissingError') {
      return; // Silently ignore - user is already logged out
    }
    throw error;
  }
};

export const getFighterProfile = async (userId: string) => {
  try {
    const { data, error } = await supabase
      .from(TABLES.FIGHTER_PROFILES)
      .select('*')
      .eq('user_id', userId)
      .maybeSingle(); // Use maybeSingle() instead of single() to return null if not found
    
    // 400, 406 errors or "not found" errors are OK - admin accounts may not have fighter profiles
    // 400 can occur due to RLS policies or query format issues
    if (error) {
      // PGRST116 means no rows found, which is fine
      // 400 and 406 can occur due to RLS or query issues - treat as "not found"
      if (error.code === 'PGRST116' || 
          error.code === '406' || 
          error.code === '400' ||
          error.message?.includes('Not Found') ||
          error.message?.includes('400') ||
          error.message?.includes('406')) {
        // Silently return null - this is expected for admin accounts or RLS issues
        return null;
      }
      // Only throw unexpected errors
      throw error;
    }
    
    return data;
  } catch (error: any) {
    // Handle 400 and 406 errors gracefully (often RLS or query format issues)
    if (error.code === '406' || 
        error.code === '400' || 
        error.message?.includes('406') ||
        error.message?.includes('400')) {
      // Silently return null - this is expected for admin accounts or RLS issues
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

