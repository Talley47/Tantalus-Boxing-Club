// =====================================================
// BROWSER CONSOLE TEST SCRIPT
// Copy and paste this ENTIRE script into your browser console
// This will test your Supabase connection and show what's happening
// =====================================================

(async function testSupabaseConnection() {
  console.log('🧪 TESTING SUPABASE CONNECTION...\n');
  
  // Get Supabase client from the app
  const supabase = window.__TANTALUS_SUPABASE_CLIENT__;
  
  if (!supabase) {
    console.error('❌ ERROR: Supabase client not found!');
    console.error('   Make sure you are on a page that has loaded the app.');
    return;
  }
  
  console.log('✅ Supabase client found\n');
  
  // Test 1: Check authentication
  console.log('📋 TEST 1: Authentication Status');
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  console.log('   User:', user ? `✅ Logged in (${user.email})` : '❌ Not logged in');
  console.log('   Role:', user ? 'authenticated' : 'anon');
  if (authError) console.log('   Auth Error:', authError.message);
  console.log('');
  
  // Test 2: Try to query fighter_profiles (simple query)
  console.log('📋 TEST 2: Query fighter_profiles (simple)');
  const { data: simpleData, error: simpleError, status, statusText } = await supabase
    .from('fighter_profiles')
    .select('id, name')
    .limit(1);
  
  console.log('   HTTP Status:', status, statusText);
  console.log('   Rows returned:', simpleData?.length || 0);
  if (simpleError) {
    console.log('   ❌ ERROR:', simpleError.message);
    console.log('   Error Code:', simpleError.code);
  } else if (simpleData && simpleData.length > 0) {
    console.log('   ✅ SUCCESS: Can see data!');
    console.log('   Sample:', simpleData[0]);
  } else {
    console.log('   ⚠️ WARNING: Query succeeded but returned 0 rows');
    console.log('   This means RLS is blocking access or table is empty');
  }
  console.log('');
  
  // Test 3: Check if table exists (bypass RLS with count)
  console.log('📋 TEST 3: Check table exists (admin query)');
  const { data: countData, error: countError } = await supabase
    .rpc('exec_sql', { 
      sql: 'SELECT COUNT(*) as total FROM fighter_profiles' 
    })
    .single();
  
  // RPC might not exist, so try direct query
  const { data: directCount, error: directError } = await supabase
    .from('fighter_profiles')
    .select('id', { count: 'exact', head: true });
  
  if (directCount !== null) {
    console.log('   Table exists: ✅');
    console.log('   Total rows (if visible):', directCount);
  } else if (directError) {
    console.log('   Table check error:', directError.message);
  }
  console.log('');
  
  // Test 4: Check current role
  console.log('📋 TEST 4: Current Database Role');
  const { data: roleData, error: roleError } = await supabase
    .rpc('current_role')
    .single();
  
  if (roleError) {
    // RPC might not exist, that's OK
    console.log('   (Cannot check role directly - this is normal)');
  } else {
    console.log('   Current role:', roleData);
  }
  console.log('');
  
  // Summary
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📊 SUMMARY:');
  console.log('');
  
  if (simpleError) {
    console.log('❌ QUERY FAILED:', simpleError.message);
    console.log('   This is a permissions/RLS issue.');
    console.log('   SOLUTION: Run database/COPY-PASTE-THIS-NOW.sql in Supabase SQL Editor');
  } else if (simpleData && simpleData.length === 0) {
    console.log('⚠️ QUERY SUCCEEDED BUT RETURNED 0 ROWS');
    console.log('   This means:');
    console.log('   1. RLS policies are blocking access (MOST LIKELY)');
    console.log('   2. OR the table is empty');
    console.log('');
    console.log('   SOLUTION: Run database/COPY-PASTE-THIS-NOW.sql in Supabase SQL Editor');
    console.log('   Then run: database/FIND-THE-PROBLEM.sql to verify');
  } else if (simpleData && simpleData.length > 0) {
    console.log('✅ EVERYTHING WORKS!');
    console.log('   You can see fighter data. The issue might be elsewhere.');
  }
  
  console.log('');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
})();

