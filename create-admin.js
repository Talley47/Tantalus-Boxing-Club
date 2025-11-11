// Admin Account Creation Script
// Run this with: node create-admin.js

require('dotenv').config({ path: '.env.local' });
const { createClient } = require('@supabase/supabase-js');

// Load from .env.local file
const supabaseUrl = process.env.REACT_APP_SUPABASE_URL || 'https://your-project.supabase.co';
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY || 'your-anon-key';

console.log('📋 Configuration Check:');
console.log(`Supabase URL: ${supabaseUrl}`);
console.log(`Anon Key: ${supabaseAnonKey.substring(0, 20)}...`);
console.log('');

if (supabaseUrl.includes('your-project') || supabaseAnonKey.includes('your-anon-key')) {
  console.log('❌ ERROR: .env.local file not properly configured!');
  console.log('Please update tantalus-boxing-club/.env.local with your actual Supabase credentials');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function createAdminAccount() {
  console.log('🚀 Creating default admin account...');
  
  try {
    // Create admin user
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: 'admin@tantalusboxing.com',
      password: 'TantalusAdmin2025!',
      options: {
        data: {
          full_name: 'Admin User',
          role: 'admin'
        },
        emailRedirectTo: undefined
      }
    });

    if (authError) {
      if (authError.message.includes('duplicate key') || authError.message.includes('already registered')) {
        console.log('✅ Admin account already exists!');
        console.log('📧 Email: admin@tantalusboxing.com');
        console.log('🔑 Password: TantalusAdmin2025!');
        console.log('\n💡 Try logging in with these credentials');
        return;
      }
      if (authError.message.includes('invalid')) {
        console.log('⚠️  Email validation error. This might be due to Supabase email settings.');
        console.log('📋 To fix this:');
        console.log('   1. Go to Supabase Dashboard → Authentication → Providers');
        console.log('   2. Make sure "Enable email provider" is checked');
        console.log('   3. Under "Email Auth", disable "Confirm email" for development');
        console.log('   4. Try running this script again');
        console.log('\n💡 Alternative: Create admin account manually in Supabase Dashboard → Authentication → Users');
        return;
      }
      throw authError;
    }

    console.log('✅ Admin user created successfully!');

    if (authData.user) {
      // Create fighter profile for admin
      const { data: profileData, error: profileError } = await supabase
        .from('fighter_profiles')
        .insert({
          user_id: authData.user.id,
          name: 'Admin User',
          handle: 'Admin Fighter',
          platform: 'TBC',
          platform_id: authData.user.id,
          timezone: 'UTC',
          height: 180, // 5'11" in cm
          weight: 90, // 200 lbs in kg
          reach: 180, // 71" in cm
          age: 30,
          stance: 'Orthodox',
          nationality: 'International',
          fighting_style: 'Boxing',
          hometown: 'Admin City',
          birthday: '1994-01-01',
          weight_class: 'Heavyweight',
          trainer: 'System',
          gym: 'TBC HQ',
          tier: 'Champion',
          points: 1000,
          wins: 0,
          losses: 0,
          draws: 0
        });

      if (profileError) {
        console.error('❌ Error creating fighter profile:', profileError);
      } else {
        console.log('✅ Admin fighter profile created successfully!');
      }
    }

    console.log('🎉 Admin account setup complete!');
    console.log('📧 Email: admin@tantalusboxing.com');
    console.log('🔑 Password: TantalusAdmin2025!');

  } catch (error) {
    console.error('❌ Error creating admin account:', error.message);
    console.log('\n🔧 Troubleshooting:');
    console.log('1. Make sure Supabase environment variables are set');
    console.log('2. Check that your Supabase project is active');
    console.log('3. Verify the database schema is set up');
    console.log('4. Ensure RLS policies allow user creation');
  }
}

// Run the script
createAdminAccount();

