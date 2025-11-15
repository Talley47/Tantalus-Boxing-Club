#!/usr/bin/env node
/**
 * Quick script to verify .env.local setup
 * Run: node verify-env-setup.js
 */

const fs = require('fs');
const path = require('path');

const envPath = path.join(__dirname, '.env.local');

console.log('🔍 Checking Supabase Environment Variables...\n');

// Check if .env.local exists
if (!fs.existsSync(envPath)) {
  console.error('❌ .env.local file NOT FOUND!');
  console.error('\n📝 Create .env.local in the project root with:');
  console.error('   REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co');
  console.error('   REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...');
  process.exit(1);
}

console.log('✅ .env.local file exists');

// Read and check contents
const envContent = fs.readFileSync(envPath, 'utf8');
const lines = envContent.split('\n').filter(line => line.trim() && !line.trim().startsWith('#'));

let hasUrl = false;
let hasKey = false;

lines.forEach(line => {
  const trimmedLine = line.trim();
  if (trimmedLine.startsWith('REACT_APP_SUPABASE_URL=')) {
    hasUrl = true;
    const parts = trimmedLine.split('=');
    if (parts.length >= 2) {
      const url = parts.slice(1).join('=').trim(); // Handle URLs with = in them
      if (url && url !== 'https://your-project.supabase.co' && !url.includes('your-project')) {
        console.log(`✅ REACT_APP_SUPABASE_URL is set: ${url}`);
      } else {
        console.error('❌ REACT_APP_SUPABASE_URL contains placeholder value');
      }
    }
  }
  if (trimmedLine.startsWith('REACT_APP_SUPABASE_ANON_KEY=')) {
    hasKey = true;
    const parts = trimmedLine.split('=');
    if (parts.length >= 2) {
      const key = parts.slice(1).join('=').trim(); // Handle keys with = in them
      if (key && key.length > 50 && !key.includes('your-anon-key')) {
        console.log(`✅ REACT_APP_SUPABASE_ANON_KEY is set (${key.length} characters)`);
      } else {
        console.error('❌ REACT_APP_SUPABASE_ANON_KEY contains placeholder value');
      }
    }
  }
});

if (!hasUrl) {
  console.error('❌ REACT_APP_SUPABASE_URL is missing');
}

if (!hasKey) {
  console.error('❌ REACT_APP_SUPABASE_ANON_KEY is missing');
}

if (hasUrl && hasKey) {
  console.log('\n✅ All environment variables are configured!');
  console.log('\n⚠️  IMPORTANT: Restart your dev server for changes to take effect:');
  console.log('   1. Stop the server (Ctrl+C)');
  console.log('   2. Run: npm start');
  console.log('   3. Refresh your browser');
} else {
  console.log('\n❌ Some environment variables are missing or incorrect.');
  process.exit(1);
}

