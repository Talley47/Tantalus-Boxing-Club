// Quick test to verify environment variables are being loaded
// Run: node test-env-load.js

// Load .env.local manually
require('dotenv').config({ path: '.env.local' });

console.log('🔍 Testing Environment Variable Loading...\n');

const url = process.env.REACT_APP_SUPABASE_URL;
const key = process.env.REACT_APP_SUPABASE_ANON_KEY;

console.log('REACT_APP_SUPABASE_URL:', url ? `✅ ${url}` : '❌ Missing');
console.log('REACT_APP_SUPABASE_ANON_KEY:', key ? `✅ Set (${key.length} chars)` : '❌ Missing');

if (!url || !key) {
  console.log('\n❌ ERROR: Environment variables not loaded!');
  console.log('\nPossible issues:');
  console.log('1. .env.local file is missing');
  console.log('2. File is in wrong location (should be in tantalus-boxing-club/)');
  console.log('3. File has wrong format');
  console.log('4. Need to install dotenv: npm install dotenv');
  process.exit(1);
}

console.log('\n✅ Environment variables are loaded correctly!');
console.log('\n⚠️  Note: React apps use react-scripts which loads .env.local automatically.');
console.log('   This test uses dotenv to verify the file format is correct.');

