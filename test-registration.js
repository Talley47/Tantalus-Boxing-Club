// Test Registration Script
require('dotenv').config({ path: '.env.local' });
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://andmtvsqqomgwphotdwf.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEzNDYwNTIsImV4cCI6MjA3NjkyMjA1Mn0.qIGPbceA5xPchQb3wtQu3OU0ngoMc7TjcTCxUQo9C5o';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testRegistration() {
  console.log('🔍 Testing Registration Flow...\n');
  
  const testEmail = `testuser${Date.now()}@gmail.com`;
  const testPassword = 'TestUser2025!Long';
  
  try {
    // Step 1: Create auth user
    console.log('1️⃣ Creating test user...');
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: testEmail,
      password: testPassword,
      options: {
        data: {
          full_name: 'Test User'
        }
      }
    });

    if (authError) {
      console.log(`❌ Auth signup failed: ${authError.message}`);
      return;
    }

    console.log(`✅ Auth user created: ${authData.user?.id}`);

    // Step 2: Check if fighter profile was created by trigger
    console.log('\n2️⃣ Checking if fighter profile was auto-created...');
    
    // Wait a moment for trigger to complete
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    const { data: profileData, error: profileError } = await supabase
      .from('fighter_profiles')
      .select('*')
      .eq('user_id', authData.user?.id)
      .single();

    if (profileError) {
      console.log(`❌ Fighter profile not found!`);
      console.log(`Error: ${profileError.message}`);
      console.log(`Code: ${profileError.code}`);
      
      if (profileError.message.includes('No rows returned')) {
        console.log('\n🚨 SOLUTION: The trigger is not working!');
        console.log('   Run CLEAN_TRIGGER_SOLUTION.sql in Supabase SQL Editor');
      }
      
      // Clean up - delete the auth user
      console.log('\n🧹 Cleaning up test user...');
      await supabase.auth.admin.deleteUser(authData.user.id);
      
      return;
    }

    console.log('✅ Fighter profile auto-created successfully!');
    console.log(`   Profile ID: ${profileData.id}`);
    console.log(`   Name: ${profileData.name}`);
    console.log(`   Tier: ${profileData.tier}`);

    // Clean up
    console.log('\n🧹 Cleaning up test user...');
    await supabase.auth.signOut();
    
    console.log('\n═══════════════════════════════════════');
    console.log('✅ REGISTRATION TEST PASSED!');
    console.log('═══════════════════════════════════════');
    console.log('✅ User signup works');
    console.log('✅ Fighter profile creation works');
    console.log('✅ Registration flow is functional');
    console.log('\n🎉 You can now register new users in the app!');
    console.log('═══════════════════════════════════════\n');

  } catch (error) {
    console.error('❌ Unexpected error:', error.message);
  }
}

testRegistration();