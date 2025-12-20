// =====================================================
// VERIFY RLS FIX IN BROWSER CONSOLE
// Copy and paste this ENTIRE script into your browser console
// This will test if the RLS fix has been applied
// =====================================================

(async () => {
  console.log('🔍 VERIFYING RLS FIX...');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  // Get Supabase client (assuming it's available globally or imported)
  let supabase;
  if (typeof window !== 'undefined' && window.__TANTALUS_SUPABASE_CLIENT__) {
    supabase = window.__TANTALUS_SUPABASE_CLIENT__;
  } else if (typeof window !== 'undefined' && window.supabase) {
    supabase = window.supabase;
  } else {
    console.error('❌ ERROR: Supabase client not found!');
    console.error('   Make sure you run this in your app\'s browser console (not a blank page)');
    console.error('   The app needs to be loaded first.');
    return;
  }
  
  console.log('✅ Supabase client found');
  
  // Test 1: Check authentication status
  console.log('\n📋 TEST 1: Authentication Status');
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  const isAuthenticated = !!user;
  console.log('   Status:', isAuthenticated ? '✅ Logged in' : '⚠️ Not logged in (anonymous)');
  console.log('   User ID:', user?.id || 'none');
  console.log('   Expected role:', isAuthenticated ? 'authenticated' : 'anon');
  
  // Test 2: Try to query fighter_profiles
  console.log('\n📋 TEST 2: Query fighter_profiles table');
  const { data, error, count } = await supabase
    .from('fighter_profiles')
    .select('id, name, handle, tier, points', { count: 'exact' })
    .limit(5);
  
  if (error) {
    console.error('   ❌ QUERY FAILED:', error.message);
    console.error('   Error code:', error.code);
    
    if (error.code === '42501' || error.message?.includes('permission') || error.message?.includes('policy')) {
      console.error('\n🚨 RLS FIX NOT APPLIED YET!');
      console.error('   The database is blocking access.');
      console.error('   ACTION REQUIRED: Run database/COPY-PASTE-THIS-NOW.sql in Supabase SQL Editor');
    } else {
      console.error('\n⚠️ UNEXPECTED ERROR');
      console.error('   This might be a different issue. Error details:', error);
    }
  } else {
    const rowCount = data?.length || 0;
    const totalCount = count || 0;
    
    if (rowCount === 0 && totalCount === 0) {
      console.warn('   ⚠️ NO DATA RETURNED');
      console.warn('   Possible reasons:');
      console.warn('   1. RLS fix not applied (most likely)');
      console.warn('   2. Table is empty (no fighter data)');
      console.warn('   3. RLS policies are too restrictive');
      console.warn('\n   ACTION: Run database/COPY-PASTE-THIS-NOW.sql in Supabase SQL Editor');
    } else if (rowCount > 0) {
      console.log('   ✅ SUCCESS! Query returned', rowCount, 'rows');
      console.log('   Total rows available:', totalCount);
      console.log('   Sample data:', data?.slice(0, 3));
      console.log('\n🎉 RLS FIX IS WORKING!');
      console.log('   If fighters still don\'t show in your app, try:');
      console.log('   1. Hard refresh (Ctrl+Shift+R)');
      console.log('   2. Check browser console for other errors');
      console.log('   3. Check if filterAdminFighters is filtering everything out');
    } else {
      console.warn('   ⚠️ Query succeeded but returned 0 rows');
      console.warn('   This suggests RLS is still blocking access');
      console.warn('   ACTION: Run database/COPY-PASTE-THIS-NOW.sql in Supabase SQL Editor');
    }
  }
  
  // Test 3: Check if we can see ANY rows (even with minimal query)
  console.log('\n📋 TEST 3: Minimal query (no filters)');
  const { data: minimalData, error: minimalError } = await supabase
    .from('fighter_profiles')
    .select('id')
    .limit(1);
  
  if (minimalError) {
    console.error('   ❌ Even minimal query failed:', minimalError.message);
    console.error('   This confirms RLS is blocking access');
  } else if (minimalData && minimalData.length > 0) {
    console.log('   ✅ Can see at least 1 row');
    console.log('   RLS is working, but main query might have other issues');
  } else {
    console.warn('   ⚠️ Cannot see any rows');
    console.warn('   RLS is likely blocking access');
  }
  
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📝 SUMMARY:');
  console.log('   If you see "RLS FIX NOT APPLIED" or "NO DATA RETURNED":');
  console.log('   → Run database/COPY-PASTE-THIS-NOW.sql in Supabase SQL Editor');
  console.log('   → Then hard refresh your app (Ctrl+Shift+R)');
  console.log('   → Run this verification script again');
  console.log('\n   If you see "SUCCESS" but fighters still don\'t show:');
  console.log('   → Check browser console for other errors');
  console.log('   → Check if filterAdminFighters is removing all fighters');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
})();

