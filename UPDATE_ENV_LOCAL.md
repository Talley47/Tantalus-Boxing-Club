# ✅ Update Your .env.local File

## 🔐 **Your New Supabase Keys**

Copy these into your `.env.local` file:

```env
REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mjk5NDAxNywiZXhwIjoyMDc4MzU0MDE3fQ.c78wDF-n_e3BlPdyOLlEkK-U35GPYwLZYzWmptf4fbc
```

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
# The old key should fail
# Old key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...UhaH4pPCppApMPjKsguPqb237NFzX0sB1xnC6-NsnEY
# New key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...c78wDF-n_e3BlPdyOLlEkK-U35GPYwLZYzWmptf4fbc
```

---

## 🚀 **Next Steps**

1. ✅ **Update `.env.local`** (you're doing this now)
2. ⚠️ **Update Vercel environment variables** (after build completes)
3. ⚠️ **Remove secret from Git history** (still needed)
4. ✅ **Test your app** (verify everything works)

---

**Status:** ✅ Keys rotated successfully!

