# Fixed: Invalid Vercel.json Rewrite Pattern

## Problem
Vercel error: "Rewrite at index 0 has invalid `source` pattern"

## Root Cause
The `vercel.json` file in the repository root had an invalid rewrite pattern using negative lookahead syntax that Vercel doesn't support:
```
/((?!static|manifest.json|favicon.ico|logo.*\.png|.*\.(ico|png|jpg|jpeg|gif|svg|woff|woff2|ttf|eot)).*)
```

## ✅ Solution Applied
Fixed the rewrite pattern to use a simpler, valid Vercel syntax:
```json
{
  "source": "/(.*)",
  "destination": "/index.html"
}
```

## What This Does
- Routes all requests to `/index.html` (for React SPA routing)
- This is the standard pattern for single-page applications
- Vercel will handle static file serving automatically

## Note
This `vercel.json` is in the repository root and appears to be for the old React app. The Next.js app in `tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs/` doesn't need this file since Next.js handles routing internally.

## Next Steps
1. ✅ Fixed rewrite pattern
2. ✅ Committed and pushed to GitHub
3. **Deploy again in Vercel** - the error should be resolved

## If You Still Get Errors
If you're deploying the Next.js app, make sure:
- Root Directory is set to: `tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs`
- The Next.js app doesn't need this `vercel.json` file
- Consider removing or moving this file if it's causing conflicts

---

**The rewrite pattern is now fixed and should work with Vercel!**

