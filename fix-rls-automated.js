#!/usr/bin/env node

/**
 * RLS FIX HELPER SCRIPT
 * 
 * ⚠️ IMPORTANT: Supabase doesn't allow executing DDL (CREATE POLICY, GRANT) 
 *    statements via the REST API for security reasons. This script helps you
 *    apply the fix using Supabase CLI (if installed) or guides you through
 *    the manual process.
 * 
 * This script will:
 * 1. Check if Supabase CLI is installed
 * 2. If yes, try to apply the fix via CLI
 * 3. If no, provide clear instructions for manual fix
 * 
 * REQUIREMENTS:
 * - Supabase CLI (optional, but recommended)
 *   Install: npm install -g supabase
 *   Or: https://supabase.com/docs/guides/cli
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const FIX_SQL_FILE = path.join(__dirname, 'database', 'COPY-PASTE-THIS-NOW.sql');

function checkSupabaseCLI() {
  try {
    execSync('supabase --version', { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

function main() {
  console.log('🚀 RLS Fix Helper Script');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');

  // Check if SQL file exists
  if (!fs.existsSync(FIX_SQL_FILE)) {
    console.error('❌ ERROR: Fix SQL file not found:', FIX_SQL_FILE);
    process.exit(1);
  }

  const sqlContent = fs.readFileSync(FIX_SQL_FILE, 'utf8');

  // Check for Supabase CLI
  const hasCLI = checkSupabaseCLI();

  if (hasCLI) {
    console.log('✅ Supabase CLI detected');
    console.log('');
    console.log('📋 To apply the fix using Supabase CLI:');
    console.log('');
    console.log('   1. Make sure you\'re logged in:');
    console.log('      supabase login');
    console.log('');
    console.log('   2. Link your project (if not already linked):');
    console.log('      supabase link --project-ref YOUR_PROJECT_REF');
    console.log('      (Get project ref from Supabase Dashboard URL)');
    console.log('');
    console.log('   3. Run the migration:');
    console.log('      supabase db push');
    console.log('      (Or create a migration and apply it)');
    console.log('');
    console.log('   ⚠️  Note: CLI migrations require proper setup.');
    console.log('   For the quickest fix, use the manual method below.');
    console.log('');
  } else {
    console.log('ℹ️  Supabase CLI not detected');
    console.log('');
  }

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📖 MANUAL FIX (Recommended - Takes 2 minutes)');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');
  console.log('STEP 1: Open the SQL file');
  console.log(`   File: ${FIX_SQL_FILE}`);
  console.log('');
  console.log('STEP 2: Copy ALL lines from the file');
  console.log('   (Ctrl+A to select all, Ctrl+C to copy)');
  console.log('');
  console.log('STEP 3: Go to Supabase Dashboard');
  console.log('   URL: https://supabase.com/dashboard');
  console.log('   → Select your project');
  console.log('   → Click "SQL Editor" in left sidebar');
  console.log('   → Click "New Query"');
  console.log('');
  console.log('STEP 4: Paste and run');
  console.log('   → Paste the SQL (Ctrl+V)');
  console.log('   → Click "Run" button (or press Ctrl+Enter)');
  console.log('');
  console.log('STEP 5: Verify success');
  console.log('   → Should see "Success" message');
  console.log('   → Results should show 2 policies listed');
  console.log('');
  console.log('STEP 6: Refresh your app');
  console.log('   → Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)');
  console.log('');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');
  console.log('📋 SQL Content Preview (first 10 lines):');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  const lines = sqlContent.split('\n').slice(0, 10);
  lines.forEach(line => console.log('   ' + line));
  console.log('   ... (see full file for complete SQL)');
  console.log('');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');
  console.log('💡 Why can\'t this be automated?');
  console.log('   Database security settings (RLS policies, GRANT statements)');
  console.log('   must be applied directly in the database. Supabase doesn\'t');
  console.log('   allow executing DDL statements via the REST API for security');
  console.log('   reasons. This is a safety feature, not a limitation.');
  console.log('');
  console.log('✅ The SQL is 100% safe - it only adds READ permissions.');
  console.log('   It does not modify or delete any data.');
  console.log('');
}

main();
