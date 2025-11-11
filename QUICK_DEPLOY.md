# 🚀 QUICK DEPLOYMENT COMMANDS

## For Netlify (CLI)

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login to Netlify
netlify login

# Deploy
cd tantalus-boxing-club
netlify deploy --prod --dir=build
```

## For Vercel (CLI)

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
cd tantalus-boxing-club
vercel --prod
```

## For Manual Upload

1. Zip the `build` folder contents
2. Upload to your hosting provider
3. Extract in web root directory

---

## Environment Variables to Set

In your hosting provider's dashboard, add:

```
REACT_APP_SUPABASE_URL=https://your-project.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your-anon-key-here
```

---

## Post-Deployment

1. Visit your site URL
2. Test login/registration
3. Check browser console for errors
4. Verify HTTPS is active
5. Test all main features

