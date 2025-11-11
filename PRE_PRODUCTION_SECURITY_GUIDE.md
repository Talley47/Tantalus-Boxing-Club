# 🚀 PRE-PRODUCTION SECURITY GUIDE

## ✅ **SECURITY STATUS SUMMARY**

### Already Implemented ✅
- ✅ Security packages installed (`dompurify`, `validator`)
- ✅ Row Level Security (RLS) policies in database
- ✅ Supabase Auth (secure authentication)
- ✅ Environment variables structure
- ✅ Input validation utilities exist

### Critical Actions Required ⚠️
- ⚠️ Remove hardcoded API keys from `supabase.ts`
- ⚠️ Add security headers
- ⚠️ Verify RLS policies are enabled
- ⚠️ Implement rate limiting
- ⚠️ Enable HTTPS enforcement
- ⚠️ Configure error handling

---

## 🔴 **CRITICAL: DO THESE FIRST**

### 1. **Remove Hardcoded API Keys** (5 minutes)

**Current Issue:** `src/services/supabase.ts` has hardcoded keys as fallbacks.

**Fix:**
```typescript
// ❌ REMOVE THIS (lines 5-6 in supabase.ts)
const supabaseUrl = process.env.REACT_APP_SUPABASE_URL || 'https://andmtvsqqomgwphotdwf.supabase.co';
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY || 'hardcoded-key';

// ✅ REPLACE WITH THIS
const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing required Supabase environment variables. Please set REACT_APP_SUPABASE_URL and REACT_APP_SUPABASE_ANON_KEY in .env.local');
}
```

**Action:** Update `src/services/supabase.ts` to require environment variables.

---

### 2. **Verify Environment Variables** (2 minutes)

**Check `.env.local` exists:**
```bash
# In project root
cat .env.local
```

**Should contain:**
```
REACT_APP_SUPABASE_URL=https://your-project.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your-anon-key-here
```

**Verify `.gitignore` includes:**
```
.env.local
.env*.local
```

---

### 3. **Verify Row Level Security (RLS)** (10 minutes)

**Run in Supabase SQL Editor:**
```sql
-- Check which tables DON'T have RLS enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = false
ORDER BY tablename;
```

**Expected Result:** Should return 0 rows (all tables should have RLS enabled).

**If tables are missing RLS, run:**
```sql
-- Enable RLS on a table (example)
ALTER TABLE your_table_name ENABLE ROW LEVEL SECURITY;
```

**Critical Tables to Verify:**
- ✅ `fighter_profiles` - Users can only edit their own
- ✅ `fight_records` - Users can only add their own records
- ✅ `chat_messages` - Users can only edit/delete their own
- ✅ `notifications` - Users can only see their own
- ✅ `training_camp_invitations` - Proper access control
- ✅ `callout_requests` - Users can only see their own

---

### 4. **Add Security Headers** (15 minutes)

**Choose your hosting provider:**

#### **Option A: Netlify** (Recommended for React apps)
Create `public/_headers`:
```
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  X-XSS-Protection: 1; mode=block
  Referrer-Policy: strict-origin-when-cross-origin
  Strict-Transport-Security: max-age=31536000; includeSubDomains
  Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.supabase.co; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https: blob:; connect-src 'self' https://*.supabase.co wss://*.supabase.co; frame-ancestors 'none';
  Permissions-Policy: geolocation=(), microphone=(), camera=()
```

#### **Option B: Vercel**
Create `vercel.json`:
```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        },
        {
          "key": "Referrer-Policy",
          "value": "strict-origin-when-cross-origin"
        },
        {
          "key": "Strict-Transport-Security",
          "value": "max-age=31536000; includeSubDomains"
        },
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.supabase.co; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https: blob:; connect-src 'self' https://*.supabase.co wss://*.supabase.co; frame-ancestors 'none';"
        }
      ]
    }
  ]
}
```

#### **Option C: Apache (.htaccess)**
Add to `.htaccess`:
```apache
<IfModule mod_headers.c>
  Header set X-Frame-Options "DENY"
  Header set X-Content-Type-Options "nosniff"
  Header set X-XSS-Protection "1; mode=block"
  Header set Referrer-Policy "strict-origin-when-cross-origin"
  Header set Strict-Transport-Security "max-age=31536000; includeSubDomains"
</IfModule>
```

---

### 5. **Enable Rate Limiting** (10 minutes)

**In Supabase Dashboard:**
1. Go to **Settings** → **API**
2. Scroll to **Rate Limiting**
3. Enable rate limiting
4. Set limits:
   - **Anonymous requests**: 100/minute
   - **Authenticated requests**: 200/minute
   - **File uploads**: 10/minute

**Or implement client-side rate limiting:**
See `PRODUCTION_SECURITY_CHECKLIST.md` section #6 for code examples.

---

### 6. **Configure Supabase Auth Settings** (5 minutes)

**In Supabase Dashboard → Authentication → Settings:**

✅ **Enable Email Confirmations**: ON
✅ **Minimum Password Length**: 8
✅ **Password Requirements**:
   - Require uppercase: Yes
   - Require lowercase: Yes
   - Require numbers: Yes
   - Require special characters: Yes (recommended)

---

### 7. **Secure Error Handling** (5 minutes)

**Check all error handlers:**
- ❌ Never expose database errors to users
- ❌ Never expose API keys or tokens
- ❌ Never expose internal file paths
- ✅ Use generic error messages for users
- ✅ Log detailed errors server-side only

**Example:**
```typescript
// ❌ BAD
catch (error) {
  alert(`Database error: ${error.message}`); // Exposes SQL errors!
}

// ✅ GOOD
catch (error) {
  console.error('Database error:', error); // Log server-side
  alert('An error occurred. Please try again.'); // Generic user message
}
```

---

## 🟡 **IMPORTANT: DO BEFORE LAUNCH**

### 8. **Run Security Audit** (5 minutes)

```bash
# Check for vulnerable dependencies
npm audit

# Fix automatically fixable issues
npm audit fix

# Review critical vulnerabilities
npm audit --audit-level=moderate
```

**If vulnerabilities found:**
- Review each one
- Update packages if safe
- Document any that can't be fixed immediately

---

### 9. **Test Admin Route Protection** (10 minutes)

**Verify admin routes are protected:**

1. **Test as regular user:**
   - Try accessing `/admin` routes
   - Should be redirected or see "Access Denied"

2. **Test as admin:**
   - Login as admin
   - Verify admin routes are accessible

3. **Test server-side check:**
   ```typescript
   // Verify admin check happens server-side, not just client-side
   const isAdmin = await checkAdminStatus(userId); // Should query database
   ```

---

### 10. **Enable HTTPS** (Automatic on most hosts)

**Most hosting providers (Netlify, Vercel, AWS) automatically:**
- ✅ Force HTTPS
- ✅ Provide SSL certificates
- ✅ Redirect HTTP to HTTPS

**If self-hosting:**
- Get SSL certificate (Let's Encrypt is free)
- Configure server to redirect HTTP → HTTPS
- Enable HSTS header (see Security Headers above)

---

### 11. **File Upload Security** (Already implemented, verify)

**Verify file uploads:**
- ✅ File type validation (whitelist)
- ✅ File size limits (10MB images, 50MB videos)
- ✅ Files stored in Supabase Storage (not web root)
- ✅ Unique filenames generated

**Test:**
- Try uploading invalid file types → Should be rejected
- Try uploading oversized files → Should be rejected
- Try uploading malicious filenames → Should be sanitized

---

### 12. **Input Sanitization** (Verify implementation)

**Check that user inputs are sanitized:**
- ✅ Chat messages sanitized before display
- ✅ User profiles sanitized
- ✅ Fight records sanitized
- ✅ Comments/reviews sanitized

**Verify `src/utils/securityUtils.ts` is being used:**
```typescript
import { sanitizeText, sanitizeHTML } from '../utils/securityUtils';

// Use in components
const safeMessage = sanitizeText(userInput);
```

---

## 🟢 **RECOMMENDED: BEST PRACTICES**

### 13. **Set Up Monitoring** (Optional but recommended)

**Options:**
- **Sentry** (error tracking) - Free tier available
- **Supabase Logs** (database activity)
- **Custom admin logs** (security events)

**Basic implementation:**
```typescript
// Log security events
const logSecurityEvent = async (event: string, userId: string, details: any) => {
  await supabase.from('admin_logs').insert({
    event_type: 'security',
    event_name: event,
    user_id: userId,
    details: details,
    created_at: new Date().toISOString()
  });
};
```

---

### 14. **Create Security.txt** (5 minutes)

**Create `public/security.txt`:**
```
Contact: mailto:security@yourdomain.com
Expires: 2025-12-31T23:59:59.000Z
Preferred-Languages: en
Acknowledgments: https://yourdomain.com/security-acknowledgments
```

---

### 15. **Backup Strategy** (10 minutes)

**Supabase automatically backs up:**
- ✅ Daily backups (free tier)
- ✅ Point-in-time recovery (paid tiers)

**Verify:**
1. Go to Supabase Dashboard → Database → Backups
2. Confirm backups are enabled
3. Test restore process (optional)

---

## 📋 **PRE-DEPLOYMENT CHECKLIST**

Before deploying to production, verify:

### Environment & Configuration
- [ ] `.env.local` exists with production keys
- [ ] Hardcoded keys removed from code
- [ ] `.gitignore` includes `.env*.local`
- [ ] Production environment variables set in hosting provider

### Security Headers
- [ ] Security headers configured (`_headers` or `vercel.json`)
- [ ] HTTPS enforced (automatic on most hosts)
- [ ] CSP header configured correctly

### Database Security
- [ ] RLS enabled on ALL tables
- [ ] RLS policies tested (users can only access their data)
- [ ] Admin routes protected server-side
- [ ] Anonymous users cannot access protected data

### Authentication
- [ ] Email confirmations enabled
- [ ] Password requirements configured
- [ ] Session timeout configured (optional)

### Rate Limiting
- [ ] Rate limiting enabled in Supabase
- [ ] Or client-side rate limiting implemented

### Input Validation
- [ ] All user inputs sanitized
- [ ] File uploads validated
- [ ] Email formats validated server-side

### Error Handling
- [ ] No sensitive info in error messages
- [ ] Generic error messages for users
- [ ] Detailed errors logged server-side only

### Testing
- [ ] Admin route protection tested
- [ ] User data isolation tested
- [ ] File upload security tested
- [ ] Input validation tested

### Dependencies
- [ ] `npm audit` run and issues fixed
- [ ] Dependencies up to date
- [ ] No known vulnerabilities

### Monitoring
- [ ] Error tracking configured (optional)
- [ ] Logging configured
- [ ] Backup strategy verified

---

## 🚀 **DEPLOYMENT STEPS**

### 1. **Build Production Version**
```bash
npm run build
```

### 2. **Test Production Build Locally**
```bash
# Serve the build folder
npx serve -s build
```

### 3. **Deploy to Hosting Provider**
- **Netlify**: Drag & drop `build` folder or connect Git
- **Vercel**: Connect Git repository or deploy via CLI
- **AWS/Azure**: Follow provider-specific instructions

### 4. **Set Environment Variables in Hosting Provider**
- Add `REACT_APP_SUPABASE_URL`
- Add `REACT_APP_SUPABASE_ANON_KEY`
- Never commit these to Git!

### 5. **Verify Deployment**
- [ ] Site loads correctly
- [ ] HTTPS is enforced
- [ ] Security headers present (check with browser DevTools)
- [ ] Login/registration works
- [ ] Admin routes protected
- [ ] No console errors

---

## 🔍 **POST-DEPLOYMENT VERIFICATION**

### Security Headers Check
```bash
# Check headers
curl -I https://yourdomain.com

# Should see:
# X-Frame-Options: DENY
# X-Content-Type-Options: nosniff
# Strict-Transport-Security: ...
```

### SSL Check
- Visit: https://www.ssllabs.com/ssltest/
- Enter your domain
- Should get A or A+ rating

### Security Scan
- Visit: https://observatory.mozilla.org/
- Enter your domain
- Should score 100+ (out of 130)

---

## 📚 **RESOURCES**

- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **Supabase Security**: https://supabase.com/docs/guides/auth/row-level-security
- **React Security**: https://reactjs.org/docs/dom-elements.html#dangerouslysetinnerhtml
- **CSP Guide**: https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP

---

## ⚠️ **CRITICAL REMINDERS**

1. **NEVER commit `.env.local` to Git**
2. **NEVER expose Service Role Key to client**
3. **ALWAYS verify RLS policies before production**
4. **ALWAYS use HTTPS in production**
5. **ALWAYS sanitize user inputs**
6. **ALWAYS test admin route protection**

---

**Status**: ⚠️ **REVIEW ALL CRITICAL ITEMS BEFORE DEPLOYMENT**

**Last Updated**: December 2024

