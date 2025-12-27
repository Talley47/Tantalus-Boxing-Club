# 🎯 Best Practice: Edge Function Setup for Top Fighters

## Why Use Edge Functions?

- **Security**: SERVICE_ROLE_KEY never exposed to browser
- **RLS**: Keep RLS tight, bypass only where needed server-side
- **Performance**: Can cache, rate limit, add business logic
- **Control**: Filter admin accounts, add analytics, etc.

## Setup Steps

### 1. Deploy Edge Function

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Deploy the function
supabase functions deploy get-top-fighters
```

### 2. Set Environment Variables

In Supabase Dashboard → Project Settings → Edge Functions:
- `SUPABASE_URL` (auto-set)
- `SUPABASE_SERVICE_ROLE_KEY` (auto-set)

### 3. Update Frontend Code

Replace `homePageService.ts` with `homePageService-edge-function.ts`:

```typescript
// Change import from:
import { HomePageService } from './services/homePageService';

// To:
import { HomePageService } from './services/homePageService-edge-function';
```

### 4. Test

```bash
# Test Edge Function locally
curl -X GET "https://your-project.supabase.co/functions/v1/get-top-fighters?limit=30" \
  -H "apikey: YOUR_ANON_KEY"
```

## Current Approach (Quick Fix)

For **dev environment**, use the quick fix SQL:
- Run `database/QUICK-FIX-FOR-DEV.sql`
- This allows public read via RLS policies
- **Not recommended for production**

## Production Approach (Best Practice)

Use Edge Function:
- Deploy `supabase/functions/get-top-fighters/index.ts`
- Update frontend to use Edge Function
- Keep RLS tight (no public read policies)
- SERVICE_ROLE_KEY stays server-side only

