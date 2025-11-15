// Test Supabase connection with current environment variables
require('dotenv').config({ path: '.env.local' });
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('❌ Missing environment variables!');
  process.exit(1);
}

console.log('🔍 Testing Supabase Connection...\n');
console.log('URL:', supabaseUrl);
console.log('Key:', supabaseAnonKey.substring(0, 20) + '...\n');

const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Test 1: Try to get session (should work even without auth)
console.log('Test 1: Checking Supabase client initialization...');
try {
  const { data: { session }, error } = await supabase.auth.getSession();
  if (error) {
    console.log('  ⚠️ Session check error (expected if not logged in):', error.message);
  } else {
    console.log('  ✅ Client initialized successfully');
  }
} catch (err) {
  console.log('  ⚠️ Session check:', err.message);
}

// Test 2: Try a simple query to verify API key
console.log('\nTest 2: Testing API key with a simple query...');
try {
  const { data, error } = await supabase
    .from('profiles')
    .select('count')
    .limit(1);
  
  if (error) {
    if (error.message.includes('Invalid API key') || error.code === 'PGRST301') {
      console.log('  ❌ ERROR: Invalid API key!');
      console.log('  The API key in .env.local does not match your Supabase project.');
      console.log('  Please verify the key in Supabase Dashboard → Settings → API');
      process.exit(1);
    } else {
      console.log('  ⚠️ Query error (may be RLS or table not found):', error.message);
      console.log('  This is OK - it means the API key is valid but query failed for other reasons');
    }
  } else {
    console.log('  ✅ API key is valid! Connection successful.');
  }
} catch (err) {
  if (err.message.includes('Invalid API key')) {
    console.log('  ❌ ERROR: Invalid API key!');
    console.log('  Please check your REACT_APP_SUPABASE_ANON_KEY in .env.local');
    process.exit(1);
  } else {
    console.log('  ⚠️ Error:', err.message);
  }
}

console.log('\n✅ Connection test complete!');
console.log('\n📝 Next steps:');
console.log('   1. If API key is invalid, update .env.local with the correct key from Supabase Dashboard');
console.log('   2. Restart your React dev server: npm start');
console.log('   3. Try logging in again');

