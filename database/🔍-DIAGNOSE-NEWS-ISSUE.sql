-- ============================================================================
-- DIAGNOSTIC: News & Announcements Not Showing
-- ============================================================================
-- Run this to check:
-- 1. Do news items exist?
-- 2. Are they published?
-- 3. Are RLS policies correct?
-- ============================================================================

-- Step 1: Check if news items exist
SELECT 
  '📰 News Items Count' as check_type,
  COUNT(*) as total_items,
  COUNT(*) FILTER (WHERE is_published = TRUE) as published_count,
  COUNT(*) FILTER (WHERE is_published = FALSE) as unpublished_count,
  COUNT(*) FILTER (WHERE is_published IS NULL) as null_published_count
FROM public.news_announcements;

-- Step 2: Show sample news items
SELECT 
  '📋 Sample News Items' as check_type,
  id,
  title,
  type,
  is_published,
  created_at
FROM public.news_announcements
ORDER BY created_at DESC
LIMIT 10;

-- Step 3: Check RLS policies for news_announcements
SELECT 
  '🔒 RLS Policies' as check_type,
  policyname,
  cmd as command,
  roles,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
ORDER BY cmd, policyname;

-- Step 4: Check if RLS is enabled
SELECT 
  '🔐 RLS Status' as check_type,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'news_announcements';

-- Step 5: Check grants/permissions
SELECT 
  '🔑 Table Permissions' as check_type,
  grantee,
  privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name = 'news_announcements'
ORDER BY grantee, privilege_type;

-- Step 6: Test query as authenticated user would see it
-- This simulates what an authenticated user would get
SELECT 
  '✅ Test Query (as authenticated)' as check_type,
  COUNT(*) as visible_count
FROM public.news_announcements
WHERE is_published = TRUE;

