# Blockers — current state

_Generated: 2026-01-23. Supersedes [`🚨-ALL-BLOCKING-ISSUES-COMPLETE-LIST.md`](./%F0%9F%9A%A8-ALL-BLOCKING-ISSUES-COMPLETE-LIST.md) (Jan 23, 2025) and [`BLOCKING_ISSUES_REPORT.md`](./BLOCKING_ISSUES_REPORT.md) (Jan 16, 2025), which are kept for history only._

This doc is the single source of truth for what is actually still broken across the CRA app (`tantalus-boxing-club/`) and the Next.js app (`tantalus-boxing-nextjs/`), both of which point at the same Supabase database.

---

## How to refresh the DB section

1. Open the Supabase SQL editor.
2. Paste the full contents of [`database/AUDIT-BLOCKERS-TODAY.sql`](./database/AUDIT-BLOCKERS-TODAY.sql).
3. Run.
4. Copy the result of each of the 7 blocks into the matching slot under **Phase 0.1** below. Mark each table OK / BROKEN / UNKNOWN.
5. Do the browser smoke test listed under **Phase 0.2**.

Until Phase 0 is filled in, do **not** run any Phase 2 SQL fixes — you will either no-op or make things worse.

---

## Phase 0.1 — Database audit (fill this in after running the SQL)

| Table                        | RLS | Total rows | anon SELECT | auth SELECT | Verdict |
| ---------------------------- | --- | ---------- | ----------- | ----------- | ------- |
| `fighter_profiles`           |     |            |             |             |         |
| `profiles`                   |     |            |             |             |         |
| `news_announcements`         |     |            |             |             |         |
| `news_reactions`             |     |            |             |             |         |
| `scheduled_fights`           |     |            |             |             |         |
| `callout_requests`           |     |            |             |             |         |
| `training_camp_invitations`  |     |            |             |             |         |
| `training_camps`             |     |            |             |             |         |
| `tournaments`                |     |            |             |             |         |
| `fighter_direct_messages`    |     |            |             |             |         |
| `notifications`              |     |            |             |             |         |

Verdict legend: `OK` (rows returned for expected role), `BROKEN` (RLS is blocking), `UNKNOWN` (no data in table yet; retest after seeding).

### Tier constraint (from block 6)

```
-- paste the constraint definition here
```

### Tier casing currently in live data (from block 7)

```
-- paste the tier distribution here
```

### Notes

- Paste any interesting GRANT gaps from block 2 here.
- Paste any table with >1 permissive policy for the same `(role, cmd)` from block 3 here — those are performance warnings, not blockers, but worth tracking.

---

## Phase 0.2 — CRA browser smoke test (fill after loading the app)

Load the CRA app signed out, then signed in. For each section record what you see and the HTTP status of the corresponding Supabase request (Dev Tools → Network).

| Section                  | Signed out | Signed in | Notes |
| ------------------------ | ---------- | --------- | ----- |
| Homepage — Top Fighters  |            |           |       |
| Homepage — News feed     |            |           |       |
| Homepage — Upcoming fights |          |           |       |
| Rankings page            |            |           |       |
| My Profile               |            |           |       |
| Matchmaking              |            |           |       |
| Training Camps           |            |           |       |

Rule of thumb: HTTP 200 + 0 rows = RLS. HTTP 4xx/5xx = code/auth/schema.

---

## Phase 0.3 — Next.js code audit (already verified from the filesystem)

| Jan-16 issue                                              | Current state                                                                                                                       | Verdict |
| --------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ------- |
| Middleware `matcher` disabled                             | Matcher is active: [`tantalus-boxing-nextjs/middleware.ts`](../tantalus-boxing-nextjs/middleware.ts) line 78.                       | OK      |
| Admin role check commented out                            | Still commented out at [`middleware.ts`](../tantalus-boxing-nextjs/middleware.ts) lines 44-46.                                      | BROKEN  |
| Supabase client files are circular imports                | Real implementations exist in [`lib/supabase/client.ts`](../tantalus-boxing-nextjs/lib/supabase/client.ts) and `server.ts`.         | OK      |
| `existingProfile` check missing `.eq('user_id', user.id)` | The entire `existingProfile` check no longer exists anywhere in `tantalus-boxing-nextjs/` — code was refactored.                     | OK      |
| Rate limit has no fallback if Redis is down               | [`lib/rate-limit.ts`](../tantalus-boxing-nextjs/lib/rate-limit.ts) fails open (lines 44-53). Module-load is still un-guarded — hardened in Phase 1.4. | PARTIAL |
| Schema mismatch (height_feet/inches vs height, tier case) | Next.js insert writes `height` (cm int) and `tier: 'Amateur'` — CRA writes `height_feet`/`height_inches` and `tier: 'amateur'`.     | BROKEN  |
| Vercel env vars not set                                   | Cannot be verified from IDE. Confirm via `vercel env ls` or dashboard.                                                              | UNKNOWN |

---

## Confirmed active blockers

### B1. Next.js admin routes let any authenticated user through — SECURITY
Source: [`tantalus-boxing-nextjs/middleware.ts`](../tantalus-boxing-nextjs/middleware.ts) lines 36-46. Fixed in **Phase 1.1** of the plan.

### B2. Next.js `createFighterProfile` writes the wrong column shape
Source: [`tantalus-boxing-nextjs/lib/actions/auth.ts`](../tantalus-boxing-nextjs/lib/actions/auth.ts) lines 179-205.
- Writes `height` (cm) — CRA uses `height_feet` / `height_inches` (inches).
- Writes `weight` in kg — CRA writes in lbs.
- Writes `reach` in cm — CRA writes in inches.
- Writes `tier: 'Amateur'` — the proven-working CRA INSERT path uses lowercase `'amateur'`.
- Writes extra fields (`age`, `nationality`, `fighting_style`) that the CRA INSERT path does not.

Left as-is this will either fail the check constraint or silently populate columns the rest of the app never reads. Fixed in **Phase 3**.

### B3. Rate-limit module crashes at cold start if Upstash env is missing
Source: [`tantalus-boxing-nextjs/lib/rate-limit.ts`](../tantalus-boxing-nextjs/lib/rate-limit.ts) lines 3-6. The `!` non-null assertions cause `new Redis(...)` to throw at module load before the fail-open catch block can help. Fixed in **Phase 1.4**.

### B4. Vercel env vars (operational)
Cannot be verified or set from the IDE. Before the next deploy, confirm these 5 are set in Vercel → Project → Settings → Environment Variables for Production, Preview, and Development:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `UPSTASH_REDIS_REST_URL`
- `UPSTASH_REDIS_REST_TOKEN`

After Phase 1.4, missing Upstash vars no longer crash the app — rate limiting just disables itself. But Supabase vars remain hard requirements.

### B5. RLS — only what Phase 0.1 confirms
Run the audit first. Then, for each table marked BROKEN in the table above, apply the matching script:

| Table                        | Script to run                                                                                                                                |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `fighter_profiles` SELECT    | [`database/🔧-MINIMAL-FIX-3-COMMANDS.sql`](./database/%F0%9F%94%A7-MINIMAL-FIX-3-COMMANDS.sql)                                                |
| `fighter_profiles` INSERT    | [`database/🔧-FIX-FIGHTER-PROFILE-INSERT-RLS.sql`](./database/%F0%9F%94%A7-FIX-FIGHTER-PROFILE-INSERT-RLS.sql)                                |
| `news_announcements` SELECT  | [`database/🚨-URGENT-FIX-NEWS-RLS-AUTHENTICATED.sql`](./database/%F0%9F%9A%A8-URGENT-FIX-NEWS-RLS-AUTHENTICATED.sql)                          |
| `scheduled_fights` etc.      | Per-table block in [`database/🔧-COMPREHENSIVE-RLS-FIX-ALL-TABLES.sql`](./database/%F0%9F%94%A7-COMPREHENSIVE-RLS-FIX-ALL-TABLES.sql)         |
| `callout_requests`           | [`database/fix-callout-requests-rls-comprehensive.sql`](./database/fix-callout-requests-rls-comprehensive.sql)                                |
| `training_camp_invitations`  | [`database/fix-training-camp-invitations-rls-comprehensive.sql`](./database/fix-training-camp-invitations-rls-comprehensive.sql)              |
| `notifications`              | [`database/fix-notifications-rls-comprehensive.sql`](./database/fix-notifications-rls-comprehensive.sql)                                     |

Do **not** invent new scripts. After each table: rerun block 5 of [`AUDIT-BLOCKERS-TODAY.sql`](./database/AUDIT-BLOCKERS-TODAY.sql) and confirm row counts are non-zero for the expected role.

---

## Items from the Jan-16/Jan-23 docs that are already resolved (no action)

- Middleware disabled.
- Supabase client files circular.
- `existingProfile` bug in Next.js.
- Rate-limit has no runtime fallback (still crashes at module load though — see B3).

These stay in the historical docs for context but do not need re-fixing.

---

## Version control caveat

The `tantalus-boxing-nextjs/` scaffold is a **sibling** of `tantalus-boxing-club/` in the workspace, but the git repo root is `tantalus-boxing-club/` — so the Next.js files are not under version control. The Phase 1.1, 1.4, and 3 edits were applied to disk, but to land on GitHub (`https://github.com/Talley47/Tantalus-Boxing-Club`) the Next.js scaffold needs to either:

1. Be moved into `tantalus-boxing-club/` and committed there, **or**
2. Become its own git repo with its own remote.

Until one of those happens, treat the Next.js edits as ephemeral. Re-apply them from this doc if they disappear.

Current Next.js files with applied Phase 1 and 3 fixes (snapshot of pending commits):

- `tantalus-boxing-nextjs/middleware.ts` — admin role check enabled with fail-closed redirect.
- `tantalus-boxing-nextjs/lib/rate-limit.ts` — guarded module load; fails open when Upstash env missing.
- `tantalus-boxing-nextjs/lib/actions/auth.ts` — `createFighterProfile` insert rewritten to canonical shape (`height_feet` / `height_inches`, `reach` inches, `weight` lbs, `tier: 'amateur'`, stance lowercased, removed `age`/`nationality`/`fighting_style`/`platform: 'TBC'`).

---

## Out of scope (intentional)

- Cleaning up the 100+ overlapping scripts in `database/` — separate dedup task.
- Rewriting CRA services that return empty arrays on error — they are correct once RLS is fixed.
- Tier casing reconciliation across the CRA app (`'Amateur'` vs `'amateur'` in UI, types, services). Pervasive and risky; drive from a dedicated task once the audit confirms which casing the DB actually stores.
- Sentry / PostHog wiring.

---

## Verification sweep (Phase 4 success criteria)

- [ ] Homepage shows fighters.
- [ ] Rankings shows fighters (signed out AND signed in).
- [ ] News & Announcements shows published items.
- [ ] Registration + fighter-profile creation works end-to-end on both apps.
- [ ] No RLS errors in the browser console.
- [ ] Admin route on Next.js redirects non-admin users to `/dashboard`.
- [ ] Vercel build passes and deploys.
- [ ] Rate-limit module-load does not throw with Upstash env unset.
