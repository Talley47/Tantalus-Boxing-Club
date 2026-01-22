/**
 * Check and Fix News & Announcements RLS Policy
 * 
 * This script checks if the RLS policy exists for authenticated users
 * to read published news, and provides instructions if it doesn't.
 * 
 * Usage:
 *   1. Create a .env file in the project root with:
 *      SUPABASE_URL=your_supabase_url
 *      SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
 *   2. Run: node scripts/check-and-fix-news-rls.js
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ Missing required environment variables:');
  console.error('   SUPABASE_URL or NEXT_PUBLIC_SUPABASE_URL');
  console.error('   SUPABASE_SERVICE_ROLE_KEY');
  console.error('');
  console.error('Create a .env file in the project root with these variables.');
  process.exit(1);
}

// Use service role key to bypass RLS for admin operations
const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function checkRLSPolicy() {
  console.log('🔍 Checking RLS policy for news_announcements...\n');

  try {
    // Check if we can query news items as an authenticated user would
    // First, let's check if there are any news items at all
    const { data: allNews, error: allNewsError } = await supabase
      .from('news_announcements')
      .select('id, title, is_published')
      .limit(5);

    if (allNewsError) {
      console.error('❌ Error querying news_announcements:', allNewsError);
      return;
    }

    console.log(`📰 Found ${allNews?.length || 0} news items in database`);
    
    if (allNews && allNews.length > 0) {
      const publishedCount = allNews.filter(item => item.is_published === true).length;
      const unpublishedCount = allNews.filter(item => item.is_published === false || item.is_published === null).length;
      
      console.log(`   ✅ Published: ${publishedCount}`);
      console.log(`   ⏸️  Unpublished: ${unpublishedCount}`);
      
      if (publishedCount === 0) {
        console.log('\n⚠️  WARNING: No published news items found!');
        console.log('   News items exist but are not published.');
        console.log('   Fix: Set is_published = true for news items in Supabase Dashboard.');
      }
    } else {
      console.log('   ⚠️  No news items found in database.');
      console.log('   Create news items in Admin Panel → News Management');
    }

    // Check RLS policies by querying pg_policies (if accessible)
    // Note: This might fail due to permissions, but we'll try
    const { data: policies, error: policyError } = await supabase.rpc('exec_sql', {
      query: `
        SELECT 
          schemaname,
          tablename,
          policyname,
          permissive,
          roles,
          cmd,
          qual
        FROM pg_policies
        WHERE tablename = 'news_announcements'
        AND roles::text LIKE '%authenticated%'
        AND cmd = 'SELECT';
      `
    }).catch(() => ({ data: null, error: { message: 'Cannot query pg_policies directly' } }));

    if (policyError && policyError.message !== 'Cannot query pg_policies directly') {
      console.log('\n⚠️  Cannot check RLS policies directly (permission issue)');
      console.log('   This is normal - we\'ll check by testing actual access instead.\n');
    } else if (policies && policies.length > 0) {
      console.log('\n✅ RLS Policy Found:');
      policies.forEach(policy => {
        console.log(`   Policy: ${policy.policyname}`);
        console.log(`   Roles: ${policy.roles}`);
        console.log(`   Command: ${policy.cmd}`);
      });
    } else {
      console.log('\n❌ RLS POLICY MISSING!');
      console.log('   No policy found for authenticated users to read news_announcements.');
      console.log('\n📝 TO FIX:');
      console.log('   1. Go to Supabase Dashboard → Table Editor → news_announcements');
      console.log('   2. Click "RLS" tab');
      console.log('   3. Click "New Policy"');
      console.log('   4. Set:');
      console.log('      - Name: "Authenticated read published news"');
      console.log('      - Operation: SELECT');
      console.log('      - Roles: authenticated');
      console.log('      - USING: is_published IS NOT NULL AND is_published = TRUE');
      console.log('   5. Save');
      console.log('\n   OR see: database/🚨-FIX-NEWS-VIA-DASHBOARD.md');
    }

    // Test actual access by simulating an authenticated user query
    // (This won't work perfectly without a real user session, but gives us a clue)
    console.log('\n🧪 Testing access...');
    const { data: testData, error: testError } = await supabase
      .from('news_announcements')
      .select('id, title, is_published')
      .eq('is_published', true)
      .limit(1);

    if (testError) {
      console.log('   ⚠️  Query test returned error:', testError.message);
      if (testError.code === '42501' || testError.message?.includes('permission')) {
        console.log('   ❌ This confirms RLS is blocking access!');
        console.log('   Fix the RLS policy using instructions above.');
      }
    } else {
      console.log('   ✅ Query test succeeded (service role can access)');
      console.log('   Note: This uses service role, so RLS is bypassed.');
      console.log('   Real users still need the RLS policy to access news.');
    }

  } catch (error) {
    console.error('❌ Unexpected error:', error);
  }
}

// Run the check
checkRLSPolicy()
  .then(() => {
    console.log('\n✅ Check complete!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });
