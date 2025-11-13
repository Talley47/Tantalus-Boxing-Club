# ✅ Update Your .env.local File

## 🔐 **Your New Supabase Keys**

Copy these into your `.env.local` file:

```env
REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

**⚠️ SECURITY WARNING:** Never commit service role keys to Git! Get your keys from:
- Supabase Dashboard → Settings → API
- Copy the "anon public" key for `REACT_APP_SUPABASE_ANON_KEY`
- Copy the "service_role secret" key for `SUPABASE_SERVICE_ROLE_KEY` (server-side only)

---

## 📝 **Steps to Update**

1. **Open:** `tantalus-boxing-club/.env.local`
2. **Replace** all three lines with the new keys above
3. **Save** the file
4. **Verify:** The file is NOT committed to Git (check `.gitignore`)

---

## ✅ **Verify Old Key is Invalid**

After updating, test that the old exposed key no longer works:

```bash
# After rotating keys, test that the old exposed key no longer works
# Old keys should fail authentication
```

---

## 🚀 **Next Steps**

1. ✅ **Update `.env.local`** (you're doing this now)
2. ⚠️ **Update Vercel environment variables** (after build completes)
3. ⚠️ **Remove secret from Git history** (still needed)
4. ✅ **Test your app** (verify everything works)

---

**Status:** ✅ Keys rotated successfully!

