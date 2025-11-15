// Quick script to verify environment variables are set correctly
require('dotenv').config({ path: '.env.local' });

console.log('🔍 Checking Environment Variables...\n');

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

console.log('REACT_APP_SUPABASE_URL:', supabaseUrl ? '✅ Set' : '❌ Missing');
if (supabaseUrl) {
  console.log('  Value:', supabaseUrl);
}

console.log('\nREACT_APP_SUPABASE_ANON_KEY:', supabaseAnonKey ? '✅ Set' : '❌ Missing');
if (supabaseAnonKey) {
  console.log('  Length:', supabaseAnonKey.length, 'characters');
  console.log('  Starts with:', supabaseAnonKey.substring(0, 20) + '...');
  console.log('  Format check:', supabaseAnonKey.startsWith('eyJ') ? '✅ Valid JWT format' : '❌ Invalid format');
}

if (!supabaseUrl || !supabaseAnonKey) {
  console.log('\n❌ ERROR: Missing required environment variables!');
  console.log('Please ensure .env.local exists and contains both variables.');
  process.exit(1);
}

console.log('\n✅ Environment variables are set correctly!');
console.log('\n⚠️ IMPORTANT: If you just created/updated .env.local, restart your dev server:');
console.log('   1. Stop the server (Ctrl+C)');
console.log('   2. Run: npm start');
console.log('\nReact apps only load environment variables at startup.');

