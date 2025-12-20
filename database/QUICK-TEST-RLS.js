// database/QUICK-TEST-RLS.js
// Copy and paste this ENTIRE script into your browser console (F12 → Console tab)
// This will test if RLS policies are working correctly

(async () => {
  console.log('🧪 Testing RLS Policies for fighter_profiles...\n');
  
  // Get Supabase client from your app
  // Try multiple ways to access it
  let supabase = null;
  
  if (typeof window !== 'undefined') {
    // Try window.supabase first
    if (window.supabase) {
      supabase = window.supabase;
      console.log('✅ Found Supabase client: window.supabase');
    }
    // Try the cached client
    else if (window.__TANTALUS_SUPABASE_CLIENT__) {
      supabase = window.__TANTALUS_SUPABASE_CLIENT__;
      console.log('✅ Found Supabase client: window.__TANTALUS_SUPABASE_CLIENT__');
    }
    // Try React DevTools
    else if (window.__REACT_DEVTOOLS_GLOBAL_HOOK__) {
      console.log('⚠️ Supabase client not found in window. Trying to import...');
      console.log('   Please ensure you are on a page that has loaded the Supabase client.');
    }
  }
  
  if (!supabase) {
    console.error('❌ ERROR: Could not find Supabase client!');
    console.error('   Make sure you are on a page that uses Supabase (like the homepage).');
    console.error('   The app needs to load first before running this test.');
    return;
  }
  
  // Test 1: Check authentication status
  console.log('\n📋 TEST 1: Authentication Status');
  console.log('─────────────────────────────────────');
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  console.log('   Authenticated:', user ? '✅ YES' : '❌ NO (anonymous)');
  console.log('   User ID:', user?.id || 'none');
  console.log('   Email:', user?.email || 'none');
  if (authError) {
    console.log('   Auth Error:', authError.message);
  }
  
  // Test 2: Try to query fighter_profiles
  console.log('\n📋 TEST 2: Query fighter_profiles Table');
  console.log('─────────────────────────────────────');
  const { data, error, status, statusText } = await supabase
    .from('fighter_profiles')
    .select('id, name, handle, tier, points')
    .limit(5);
  
  if (error) {
    console.error('   ❌ QUERY FAILED');
    console.error('   Error Code:', error.code);
    console.error('   Error Message:', error.message);
    console.error('   Status:', status);
    
    if (error.code === '42501' || error.message?.includes('policy') || error.message?.includes('permission')) {
      console.error('\n   🚨 RLS POLICY ERROR DETECTED!');
      console.error('   This means RLS policies are blocking access.');
      console.error('   SOLUTION: Run database/COPY-PASTE-THIS-NOW.sql in Supabase SQL Editor');
    }
  } else {
    console.log('   ✅ QUERY SUCCEEDED');
    console.log('   Status:', status);
    console.log('   Rows Returned:', data?.length || 0);
    
    if (data && data.length > 0) {
      console.log('   ✅ DATA IS VISIBLE - RLS policies are working!');
      console.log('   Sample data:', data.slice(0, 3));
    } else {
      console.warn('   ⚠️ NO DATA RETURNED');
      console.warn('   This could mean:');
      console.warn('   1. RLS policies are still blocking (most likely)');
      console.warn('   2. The table is empty');
      console.warn('   SOLUTION: Run database/COPY-PASTE-THIS-NOW.sql in Supabase SQL Editor');
    }
  }
  
  // Test 3: Summary
  console.log('\n📋 TEST SUMMARY');
  console.log('─────────────────────────────────────');
  const isAuthenticated = !!user;
  const hasData = data && data.length > 0;
  const hasError = !!error;
  
  if (hasData) {
    console.log('   ✅ SUCCESS: RLS policies are working correctly!');
    console.log('   Fighters should appear in your app.');
  } else if (hasError && (error.code === '42501' || error.message?.includes('policy'))) {
    console.log('   ❌ FAILED: RLS policies are blocking access.');
    console.log('   ACTION REQUIRED: Run database/COPY-PASTE-THIS-NOW.sql in Supabase SQL Editor');
  } else if (!hasError && !hasData) {
    console.log('   ⚠️ WARNING: Query succeeded but returned 0 rows.');
    console.log('   This likely means RLS policies are filtering everything out.');
    console.log('   ACTION REQUIRED: Run database/COPY-PASTE-THIS-NOW.sql in Supabase SQL Editor');
  } else {
    console.log('   ❓ UNCLEAR: Need more information.');
    console.log('   Please share the full output above.');
  }
  
  console.log('\n📖 Next Steps:');
  console.log('   1. If RLS is blocking: Run database/COPY-PASTE-THIS-NOW.sql in Supabase SQL Editor');
  console.log('   2. After running SQL: Hard refresh your app (Ctrl+Shift+R)');
  console.log('   3. Run this test again to verify the fix worked');
  console.log('\n🏁 Test Complete!');
})();

