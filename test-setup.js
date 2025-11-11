// Test Setup Script
// Run with: node test-setup.js

const { createClient } = require('@supabase/supabase-js');

// Check environment variables
const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

console.log('🔍 Testing Tantalus Boxing Club Setup...\n');

// Test 1: Environment Variables
console.log('1️⃣ Testing Environment Variables:');
if (!supabaseUrl || supabaseUrl.includes('your-project')) {
  console.log('❌ REACT_APP_SUPABASE_URL not configured');
  console.log('   Create .env.local file with your Supabase URL');
} else {
  console.log('✅ REACT_APP_SUPABASE_URL configured');
}

if (!supabaseAnonKey || supabaseAnonKey.includes('your-anon-key')) {
  console.log('❌ REACT_APP_SUPABASE_ANON_KEY not configured');
  console.log('   Add your Supabase anon key to .env.local');
} else {
  console.log('✅ REACT_APP_SUPABASE_ANON_KEY configured');
}

// Test 2: Supabase Connection
if (supabaseUrl && !supabaseUrl.includes('your-project') && 
    supabaseAnonKey && !supabaseAnonKey.includes('your-anon-key')) {
  
  console.log('\n2️⃣ Testing Supabase Connection:');
  const supabase = createClient(supabaseUrl, supabaseAnonKey);
  
  // Test database connection
  supabase.from('fighter_profiles').select('count').limit(1)
    .then(({ data, error }) => {
      if (error) {
        console.log('❌ Database connection failed:', error.message);
        console.log('   Check that database schema is set up');
      } else {
        console.log('✅ Database connection successful');
      }
    })
    .catch(err => {
      console.log('❌ Connection test failed:', err.message);
    });
    
  // Test auth
  supabase.auth.getSession()
    .then(({ data, error }) => {
      if (error) {
        console.log('❌ Auth connection failed:', error.message);
      } else {
        console.log('✅ Auth connection successful');
      }
    })
    .catch(err => {
      console.log('❌ Auth test failed:', err.message);
    });
}

// Test 3: Development Server
console.log('\n3️⃣ Testing Development Server:');
const http = require('http');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/',
  method: 'GET'
};

const req = http.request(options, (res) => {
  if (res.statusCode === 200) {
    console.log('✅ Development server is running on port 3000');
  } else {
    console.log('⚠️ Development server responded with status:', res.statusCode);
  }
});

req.on('error', (err) => {
  console.log('❌ Development server not accessible:', err.message);
  console.log('   Run: npm start');
});

req.end();

console.log('\n📋 Setup Checklist:');
console.log('□ Environment variables configured');
console.log('□ Database schema executed');
console.log('□ Development server running');
console.log('□ Admin account created');
console.log('□ Can access http://localhost:3000');
console.log('□ Registration form works');
console.log('□ Can create fighter profiles');

console.log('\n🎯 Next Steps:');
console.log('1. Fix any ❌ errors above');
console.log('2. Follow COMPLETE_SETUP_GUIDE.md');
console.log('3. Test registration at http://localhost:3000/register');
console.log('4. Create admin account if needed');

