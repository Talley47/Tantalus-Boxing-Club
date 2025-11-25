# Fix for News Announcements Timeout Error (500)

## Problem

The news announcements query is timing out with error:
```
GET /rest/v1/news_announcements?select=*&order=created_at.desc&limit=20&is_published=eq.true
500 (Internal Server Error)
Error: canceling statement due to statement timeout (code: 57014)
```

## Root Cause

The query is timing out because:
1. **Missing Optimized Index**: The query filters by `is_published = TRUE` and orders by `created_at DESC`, but there's no composite index covering both conditions
2. **Index Mismatch**: Existing index is on `(is_published, published_at)` but the query orders by `created_at`
3. **RLS Policy**: The RLS policy might be slow if the table is large

## Solution

Create optimized indexes that match the exact query pattern.

### Step 1: Run the Index Optimization Script

Run this in your Supabase SQL Editor:

```sql
-- File: database/fix-news-announcements-timeout.sql
```

This script:
- Creates a composite index on `(is_published, created_at DESC)` for published items
- Creates a partial index (only for published items) for better performance
- Creates a general index on `created_at` for other queries
- Analyzes the table to update statistics

### Step 2: Verify Indexes

After running the script, verify the indexes exist:

```sql
SELECT 
    indexname, 
    indexdef 
FROM pg_indexes 
WHERE tablename = 'news_announcements'
ORDER BY indexname;
```

You should see:
- `idx_news_announcements_published_created` (composite index)
- `idx_news_announcements_is_published` (partial index)
- `idx_news_announcements_created_at` (general index)

## Expected Results

After applying the fix:
- ✅ Query should execute in < 100ms (instead of timing out)
- ✅ No more 500 errors
- ✅ Fast loading of news items
- ✅ Better performance for all news queries

## Additional Optimization (Optional)

If the issue persists, you can also optimize the RLS policy:

```sql
-- File: database/optimize-news-rls-policy.sql
```

This ensures the RLS policy is as simple and fast as possible.

## Verification

Test the query after applying the fix:

```sql
EXPLAIN ANALYZE
SELECT * 
FROM news_announcements 
WHERE is_published = TRUE 
ORDER BY created_at DESC 
LIMIT 20;
```

The query plan should show:
- Index Scan using `idx_news_announcements_published_created`
- Execution time should be very fast (< 50ms)

## Prevention

For future queries, ensure:
1. Indexes match the query pattern (filter + sort columns)
2. Use partial indexes for common filter conditions
3. Keep RLS policies simple
4. Regularly analyze tables to update statistics

