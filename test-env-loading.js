#!/usr/bin/env node
/**
 * Test script to verify environment variables are being loaded correctly
 * This simulates what Create React App does when loading .env.local
 */

// Load dotenv to read .env.local (same way CRA does it)
require('dotenv').config({ path: '.env.local' });

console.log('\n🔍 Testing Environment Variable Loading...\n');
console.log('=' .repeat(60));

// Check what dotenv loaded
const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
const supabaseKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

console.log('\n📋 Environment Variables:');
console.log('  REACT_APP_SUPABASE_URL:', supabaseUrl ? `✅ ${supabaseUrl}` : '❌ NOT FOUND');
console.log('  REACT_APP_SUPABASE_ANON_KEY:', supabaseKey ? `✅ Set (${supabaseKey.length} chars)` : '❌ NOT FOUND');

if (!supabaseUrl || !supabaseKey) {
    console.log('\n❌ ERROR: Environment variables are NOT being loaded!');
    console.log('\nPossible causes:');
    console.log('  1. .env.local file is missing or in wrong location');
    console.log('  2. File has wrong encoding (should be UTF-8)');
    console.log('  3. File has syntax errors');
    console.log('  4. File is in .gitignore and not being read');
    console.log('\n💡 Solution:');
    console.log('  Run: node verify-env-setup.js');
    process.exit(1);
}

console.log('\n✅ Environment variables are loaded correctly!');
console.log('\n📝 Next Steps:');
console.log('  1. Make sure dev server is STOPPED (Ctrl+C)');
console.log('  2. Clear browser cache (Ctrl+Shift+Delete)');
console.log('  3. Run: npm start');
console.log('  4. Access: http://localhost:3000');
console.log('\n');

