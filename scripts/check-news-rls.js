/**
 * Check News RLS Policy Status
 * 
 * This script checks if the RLS policy for authenticated users exists
 * on the news_announcements table.
 * 
 * Run: node scripts/check-news-rls.js
 */

require('dotenv').config({ path: '.env.local' });
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('❌ Missing Supabase environment variables!');
  console.error('   Create .env.local with REACT_APP_SUPABASE_URL and REACT_APP_SUPABASE_ANON_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function checkNewsRLS() {
  console.log('🔍 Checking News & Announcements RLS Policy...\n');

  try {
    // Try to fetch news items as an authenticated user
    // If RLS policy is missing, this will return empty array or error
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      console.log('⚠️  Not logged in. Signing in as test user...');
      console.log('   (This check requires authentication)');
      console.log('\n📋 MANUAL CHECK REQUIRED:');
      console.log('   1. Go to Supabase Dashboard → Authentication → Policies');
      console.log('   2. Select "news_announcements" table');
      console.log('   3. Look for policy: "Authenticated read published news"');
      console.log('   4. If missing, create it using Dashboard UI (see instructions below)\n');
      return;
    }

    console.log(`✅ Authenticated as: ${user.email || user.id}\n`);

    // Try to fetch news items
    const { data, error } = await supabase
      .from('news_announcements')
      .select('id, title, is_published')
      .limit(5);

    if (error) {
      console.error('❌ Error fetching news items:');
      console.error(`   Code: ${error.code}`);
      console.error(`   Message: ${error.message}`);
      
      if (error.code === '42501' || error.message?.includes('permission') || error.message?.includes('policy')) {
        console.error('\n🚫 RLS POLICY MISSING!');
        console.error('   Authenticated users cannot read news_announcements table.\n');
        console.log('📋 FIX: Create RLS Policy via Dashboard UI');
        console.log('   See: database/🚨-FIX-NEWS-VIA-DASHBOARD.md\n');
      }
      return;
    }

    console.log(`✅ Successfully fetched ${data?.length || 0} news items`);
    
    if (data && data.length > 0) {
      const published = data.filter(item => item.is_published === true);
      console.log(`   Published: ${published.length}`);
      console.log(`   Unpublished: ${data.length - published.length}`);
      
      if (published.length === 0) {
        console.log('\n⚠️  No published news items found!');
        console.log('   News items exist but are not published.');
        console.log('   Fix: Set is_published = TRUE in Supabase Dashboard\n');
      } else {
        console.log('\n✅ RLS Policy is working correctly!');
        console.log('   Authenticated users can read published news.\n');
      }
    } else {
      console.log('\n⚠️  No news items found in database.');
      console.log('   This could mean:');
      console.log('   1. No news items exist yet');
      console.log('   2. RLS policy is blocking access (check Dashboard)\n');
    }

  } catch (error) {
    console.error('❌ Unexpected error:', error.message);
  }
}

checkNewsRLS();
