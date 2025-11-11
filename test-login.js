// Test Login Script
require('dotenv').config({ path: '.env.local' });
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://andmtvsqqomgwphotdwf.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEzNDYwNTIsImV4cCI6MjA3NjkyMjA1Mn0.qIGPbceA5xPchQb3wtQu3OU0ngoMc7TjcTCxUQo9C5o';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testLogin() {
  console.log('🔍 Testing Login...\n');
  
  try {
    // Test 1: Check connection
    console.log('1️⃣ Testing Supabase connection...');
    const { data: healthData, error: healthError } = await supabase
      .from('profiles')
      .select('count')
      .limit(1);
    
    if (healthError) {
      console.log(`❌ Connection failed: ${healthError.message}`);
      console.log('   This means the database schema may not be set up yet.');
      console.log('   Solution: Run schema-fixed.sql in Supabase SQL Editor\n');
    } else {
      console.log('✅ Supabase connection successful!\n');
    }

    // Test 2: Try to login
    console.log('2️⃣ Attempting admin login...');
    const { data, error } = await supabase.auth.signInWithPassword({
      email: 'tantalusboxingclub@gmail.com',
      password: 'TantalusAdmin2025!'
    });

    if (error) {
      console.log(`❌ Login failed: ${error.message}`);
      
      if (error.message.includes('Invalid login credentials')) {
        console.log('\n📋 Possible causes:');
        console.log('   1. Admin account not created yet');
        console.log('   2. Incorrect password');
        console.log('   3. Email not confirmed in Supabase\n');
        console.log('✅ Solution: Go to Supabase Dashboard → Authentication → Users');
        console.log('   and manually create the admin account with:');
        console.log('   Email: admin@tantalusboxing.com');
        console.log('   Password: TantalusAdmin2025!');
        console.log('   ✅ Check "Auto Confirm User"\n');
      }
    } else {
      console.log('✅ Login successful!');
      console.log(`   User ID: ${data.user?.id}`);
      console.log(`   Email: ${data.user?.email}`);
      console.log(`   App Metadata: ${JSON.stringify(data.user?.app_metadata)}`);
      
      // Check for fighter profile
      console.log('\n3️⃣ Checking for fighter profile...');
      const { data: profileData, error: profileError } = await supabase
        .from('fighter_profiles')
        .select('*')
        .eq('user_id', data.user.id)
        .single();
      
      if (profileError) {
        console.log(`⚠️  No fighter profile found: ${profileError.message}`);
        console.log('   This is OK for admin - profile will be created on first login\n');
      } else {
        console.log('✅ Fighter profile found!');
        console.log(`   Name: ${profileData.name}`);
        console.log(`   Tier: ${profileData.tier}\n`);
      }
      
      // Sign out
      await supabase.auth.signOut();
      console.log('✅ Test complete - signed out\n');
    }

    console.log('═══════════════════════════════════════');
    console.log('📊 SUMMARY');
    console.log('═══════════════════════════════════════');
    if (!healthError && !error) {
      console.log('✅ Everything is working!');
      console.log('✅ You can now login to the app');
      console.log('🚀 Go to: http://localhost:3003/login');
    } else if (healthError) {
      console.log('❌ Database schema not set up');
      console.log('📋 Action: Run schema-fixed.sql in Supabase SQL Editor');
    } else if (error) {
      console.log('❌ Login issue detected');
      console.log('📋 Action: Create admin account in Supabase Dashboard');
    }
    console.log('═══════════════════════════════════════\n');

  } catch (err) {
    console.error('❌ Unexpected error:', err.message);
  }
}

testLogin();

