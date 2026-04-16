-- ============================================================================
-- AUDIT-BLOCKERS-TODAY
-- ============================================================================
-- Single consolidated audit that produces the evidence needed to fill in
-- ../BLOCKERS_TODAY.md. Paste the whole file into the Supabase SQL editor
-- and run once. Copy the result of each block into BLOCKERS_TODAY.md.
--
-- Tables audited:
--   fighter_profiles, profiles, news_announcements, news_reactions,
--   scheduled_fights, callout_requests, training_camp_invitations,
--   training_camps, tournaments, fighter_direct_messages, notifications
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. RLS enabled + row counts (as superuser / dashboard role)
-- ----------------------------------------------------------------------------
SELECT
  t.tablename,
  t.rowsecurity                                                   AS rls_enabled,
  (xpath('/row/c/text()',
         query_to_xml(format('SELECT count(*) AS c FROM public.%I', t.tablename),
                      false, true, '')))[1]::text::bigint          AS total_rows
FROM pg_tables t
WHERE t.schemaname = 'public'
  AND t.tablename IN (
    'fighter_profiles', 'profiles', 'news_announcements', 'news_reactions',
    'scheduled_fights', 'callout_requests', 'training_camp_invitations',
    'training_camps', 'tournaments', 'fighter_direct_messages', 'notifications'
  )
ORDER BY t.tablename;

-- ----------------------------------------------------------------------------
-- 2. Table-level GRANTs (who has SELECT/INSERT/UPDATE/DELETE?)
-- ----------------------------------------------------------------------------
SELECT
  table_name,
  grantee,
  string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privileges
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND grantee IN ('anon', 'authenticated', 'service_role')
  AND table_name IN (
    'fighter_profiles', 'profiles', 'news_announcements', 'news_reactions',
    'scheduled_fights', 'callout_requests', 'training_camp_invitations',
    'training_camps', 'tournaments', 'fighter_direct_messages', 'notifications'
  )
GROUP BY table_name, grantee
ORDER BY table_name, grantee;

-- ----------------------------------------------------------------------------
-- 3. RLS policy count by table and action (fewer rows than full policy list)
-- ----------------------------------------------------------------------------
SELECT
  tablename,
  cmd AS action,
  count(*) AS policy_count,
  string_agg(policyname, ' | ' ORDER BY policyname) AS policies
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'fighter_profiles', 'profiles', 'news_announcements', 'news_reactions',
    'scheduled_fights', 'callout_requests', 'training_camp_invitations',
    'training_camps', 'tournaments', 'fighter_direct_messages', 'notifications'
  )
GROUP BY tablename, cmd
ORDER BY tablename, cmd;

-- ----------------------------------------------------------------------------
-- 4. Anonymous-role SELECT smoke test
--    Runs each SELECT AS the anon role. 0 rows = RLS is blocking anon.
--    We use SET LOCAL so the role change does not persist past the transaction.
-- ----------------------------------------------------------------------------
BEGIN;
SET LOCAL ROLE anon;
SELECT 'anon' AS role,
  (SELECT count(*) FROM public.fighter_profiles)         AS fighter_profiles,
  (SELECT count(*) FROM public.news_announcements)       AS news_announcements,
  (SELECT count(*) FROM public.scheduled_fights)         AS scheduled_fights,
  (SELECT count(*) FROM public.tournaments)              AS tournaments,
  (SELECT count(*) FROM public.training_camps)           AS training_camps;
ROLLBACK;

-- ----------------------------------------------------------------------------
-- 5. Authenticated-role SELECT smoke test
--    Same idea but as authenticated. 0 rows on a table known to have data
--    = RLS is blocking authenticated reads.
-- ----------------------------------------------------------------------------
BEGIN;
SET LOCAL ROLE authenticated;
SELECT 'authenticated' AS role,
  (SELECT count(*) FROM public.fighter_profiles)              AS fighter_profiles,
  (SELECT count(*) FROM public.news_announcements)            AS news_announcements,
  (SELECT count(*) FROM public.scheduled_fights)              AS scheduled_fights,
  (SELECT count(*) FROM public.callout_requests)              AS callout_requests,
  (SELECT count(*) FROM public.training_camp_invitations)     AS training_camp_invitations,
  (SELECT count(*) FROM public.training_camps)                AS training_camps,
  (SELECT count(*) FROM public.tournaments)                   AS tournaments,
  (SELECT count(*) FROM public.fighter_direct_messages)       AS fighter_direct_messages,
  (SELECT count(*) FROM public.news_reactions)                AS news_reactions,
  (SELECT count(*) FROM public.notifications)                 AS notifications,
  (SELECT count(*) FROM public.profiles)                      AS profiles;
ROLLBACK;

-- ----------------------------------------------------------------------------
-- 6. tier check-constraint + column shape (Phase 3 reconciliation evidence)
-- ----------------------------------------------------------------------------
SELECT
  con.conname  AS constraint_name,
  pg_get_constraintdef(con.oid) AS definition
FROM pg_constraint con
JOIN pg_class cls ON cls.oid = con.conrelid
JOIN pg_namespace nsp ON nsp.oid = cls.relnamespace
WHERE nsp.nspname = 'public'
  AND cls.relname = 'fighter_profiles'
  AND con.contype = 'c';

SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'fighter_profiles'
ORDER BY ordinal_position;

-- ----------------------------------------------------------------------------
-- 7. Distinct tier values currently in the data (proves the live casing)
-- ----------------------------------------------------------------------------
SELECT tier, count(*) AS n
FROM public.fighter_profiles
GROUP BY tier
ORDER BY n DESC;

-- ============================================================================
-- Interpretation:
--   - If block 1 shows total_rows > 0 but block 4/5 shows 0 for the same
--     table and role --> RLS is blocking that role. Fix required.
--   - If block 2 shows the role has NO privileges for a table --> GRANT is
--     missing (a policy alone is not enough). Fix required.
--   - Block 3: any table with >1 permissive policy for the same (role, cmd)
--     is the "Multiple Permissive Policies" warning. Performance, not broken.
--   - Block 6/7 drive the Phase 3 Next.js insert shape. Use whichever tier
--     casing and column names (height vs height_feet/inches) actually exist.
-- ============================================================================
