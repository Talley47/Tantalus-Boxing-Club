# 🔒 PRODUCTION SECURITY CHECKLIST

## ⚠️ CRITICAL SECURITY MEASURES REQUIRED BEFORE PRODUCTION

This document outlines all security measures that MUST be implemented before deploying to production.

---

## 🔴 **CRITICAL (Must Implement Immediately)**

### 1. **Environment Variables Security**
- ✅ **Current Status**: Using `.env.local` (good)
- ⚠️ **Action Required**:
  - [ ] **NEVER commit `.env.local` to Git** (add to `.gitignore`)
  - [ ] Remove hardcoded Supabase keys from `supabase.ts`
  - [ ] Use environment variables for ALL sensitive data
  - [ ] Set different keys for production vs development
  - [ ] Use Supabase Service Role Key only on server-side (never expose to client)

**Fix Required:**
```typescript
// ❌ CURRENT (INSECURE - Keys exposed in code)
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY || 'hardcoded-key-here';

// ✅ SECURE (Only use environment variables)
const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}
```

---

### 2. **Row Level Security (RLS) Policies**
- ✅ **Current Status**: RLS policies exist in database schemas
- ⚠️ **Action Required**:
  - [ ] **Verify ALL tables have RLS enabled**
  - [ ] Test that users can ONLY access their own data
  - [ ] Verify admin-only routes are protected
  - [ ] Test that anonymous users cannot access protected data

**Critical Tables to Verify:**
- `fighter_profiles` - Users can only edit their own profile
- `fight_records` - Users can only add records for themselves
- `disputes` - Users can only see disputes they're involved in
- `chat_messages` - Users can only edit/delete their own messages
- `notifications` - Users can only see their own notifications
- `matchmaking_requests` - Users can only see requests they sent/received
- `training_camp_invitations` - Users can only see their invitations
- `callout_requests` - Users can only see their callouts

**Test Script:**
```sql
-- Verify RLS is enabled on all tables
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = false;
```

---

### 3. **Input Validation & Sanitization**
- ⚠️ **Current Status**: Basic validation exists, but needs enhancement
- ⚠️ **Action Required**:
  - [ ] Implement server-side validation (not just client-side)
  - [ ] Sanitize all user inputs (prevent XSS)
  - [ ] Validate file uploads (type, size, content)
  - [ ] Validate email formats server-side
  - [ ] Validate UUIDs before database queries
  - [ ] Prevent SQL injection (use parameterized queries - Supabase handles this)

**Required Libraries:**
```bash
npm install dompurify validator
```

**Implementation Example:**
```typescript
import DOMPurify from 'dompurify';
import validator from 'validator';

// Sanitize user input
const sanitizeInput = (input: string): string => {
  return DOMPurify.sanitize(input, { ALLOWED_TAGS: [] });
};

// Validate email
const isValidEmail = (email: string): boolean => {
  return validator.isEmail(email) && validator.isLength(email, { max: 255 });
};

// Validate file upload
const validateFile = (file: File): { valid: boolean; error?: string } => {
  const maxSize = 10 * 1024 * 1024; // 10MB
  const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'video/mp4'];
  
  if (file.size > maxSize) {
    return { valid: false, error: 'File too large' };
  }
  if (!allowedTypes.includes(file.type)) {
    return { valid: false, error: 'Invalid file type' };
  }
  return { valid: true };
};
```

---

### 4. **Security Headers**
- ❌ **Current Status**: NOT implemented in React app
- ⚠️ **Action Required**: Add security headers via server configuration

**Required Headers:**
```http
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.supabase.co; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https: blob:; connect-src 'self' https://*.supabase.co; frame-ancestors 'none';
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

**Implementation Options:**
1. **If using Netlify**: Add `_headers` file in `public/` folder
2. **If using Vercel**: Add `vercel.json` configuration
3. **If using Apache**: Add to `.htaccess`
4. **If using Nginx**: Add to server config

**Example `public/_headers` (for Netlify):**
```
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  X-XSS-Protection: 1; mode=block
  Referrer-Policy: strict-origin-when-cross-origin
  Strict-Transport-Security: max-age=31536000; includeSubDomains
  Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.supabase.co; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https: blob:; connect-src 'self' https://*.supabase.co; frame-ancestors 'none';
```

---

### 5. **HTTPS Enforcement**
- ⚠️ **Action Required**:
  - [ ] **Force HTTPS** in production (redirect HTTP to HTTPS)
  - [ ] Use SSL/TLS certificates (Let's Encrypt or provider)
  - [ ] Enable HSTS (HTTP Strict Transport Security)
  - [ ] Verify all API calls use HTTPS

**Implementation:**
- Most hosting providers (Vercel, Netlify, AWS) automatically enforce HTTPS
- Add redirect in server configuration if self-hosting

---

### 6. **Rate Limiting**
- ❌ **Current Status**: NOT implemented in React app
- ⚠️ **Action Required**: Implement rate limiting to prevent abuse

**Options:**
1. **Supabase Rate Limiting** (Recommended):
   - Configure in Supabase Dashboard → Settings → API
   - Set rate limits per endpoint

2. **Client-Side Rate Limiting** (Basic protection):
   ```typescript
   // Simple rate limiter
   const rateLimiter = new Map<string, { count: number; resetTime: number }>();
   
   const checkRateLimit = (userId: string, limit: number, windowMs: number): boolean => {
     const now = Date.now();
     const userLimit = rateLimiter.get(userId);
     
     if (!userLimit || now > userLimit.resetTime) {
       rateLimiter.set(userId, { count: 1, resetTime: now + windowMs });
       return true;
     }
     
     if (userLimit.count >= limit) {
       return false;
     }
     
     userLimit.count++;
     return true;
   };
   ```

3. **Server-Side Rate Limiting** (Best - requires backend):
   - Use Upstash Redis (as shown in Next.js version)
   - Or implement in Supabase Edge Functions

**Critical Endpoints to Protect:**
- Login attempts: 5 per minute per IP
- Registration: 3 per hour per IP
- File uploads: 10 per minute per user
- API calls: 100 per minute per user
- Admin actions: 50 per minute per admin

---

### 7. **Authentication Security**
- ✅ **Current Status**: Using Supabase Auth (good)
- ⚠️ **Action Required**:
  - [ ] Enable email confirmation in Supabase
  - [ ] Implement password strength requirements
  - [ ] Add account lockout after failed login attempts
  - [ ] Implement session timeout
  - [ ] Add 2FA (Two-Factor Authentication) for admins
  - [ ] Log all authentication attempts

**Supabase Settings:**
```
Authentication → Settings:
- Enable email confirmations: ON
- Minimum password length: 8
- Require uppercase: Yes
- Require lowercase: Yes
- Require numbers: Yes
- Require special characters: Yes
```

**Password Validation:**
```typescript
const validatePassword = (password: string): { valid: boolean; error?: string } => {
  if (password.length < 8) {
    return { valid: false, error: 'Password must be at least 8 characters' };
  }
  if (!/[A-Z]/.test(password)) {
    return { valid: false, error: 'Password must contain uppercase letter' };
  }
  if (!/[a-z]/.test(password)) {
    return { valid: false, error: 'Password must contain lowercase letter' };
  }
  if (!/[0-9]/.test(password)) {
    return { valid: false, error: 'Password must contain number' };
  }
  if (!/[^A-Za-z0-9]/.test(password)) {
    return { valid: false, error: 'Password must contain special character' };
  }
  return { valid: true };
};
```

---

### 8. **Error Handling Security**
- ⚠️ **Action Required**:
  - [ ] **Never expose sensitive information in error messages**
  - [ ] Don't reveal database structure in errors
  - [ ] Don't expose API keys or tokens
  - [ ] Use generic error messages for users
  - [ ] Log detailed errors server-side only

**Current Issue:**
```typescript
// ❌ BAD - Exposes sensitive info
catch (error) {
  alert(`Database error: ${error.message}`); // Shows SQL errors!
}

// ✅ GOOD - Generic user message
catch (error) {
  console.error('Database error:', error); // Log server-side
  alert('An error occurred. Please try again.'); // Generic user message
}
```

---

### 9. **File Upload Security**
- ⚠️ **Current Status**: Basic validation exists
- ⚠️ **Action Required**:
  - [ ] Validate file types (whitelist, not blacklist)
  - [ ] Validate file size (max 10MB for images, 50MB for videos)
  - [ ] Scan files for malware (if possible)
  - [ ] Store files outside web root (use Supabase Storage)
  - [ ] Generate unique filenames (prevent overwrites)
  - [ ] Don't execute uploaded files

**Enhanced File Validation:**
```typescript
const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
const ALLOWED_VIDEO_TYPES = ['video/mp4', 'video/webm'];
const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // 10MB
const MAX_VIDEO_SIZE = 50 * 1024 * 1024; // 50MB

const validateFileUpload = (file: File, type: 'image' | 'video'): { valid: boolean; error?: string } => {
  // Check file type
  const allowedTypes = type === 'image' ? ALLOWED_IMAGE_TYPES : ALLOWED_VIDEO_TYPES;
  if (!allowedTypes.includes(file.type)) {
    return { valid: false, error: `Invalid ${type} type. Allowed: ${allowedTypes.join(', ')}` };
  }
  
  // Check file size
  const maxSize = type === 'image' ? MAX_IMAGE_SIZE : MAX_VIDEO_SIZE;
  if (file.size > maxSize) {
    return { valid: false, error: `File too large. Max size: ${maxSize / 1024 / 1024}MB` };
  }
  
  // Check filename (prevent path traversal)
  if (file.name.includes('..') || file.name.includes('/') || file.name.includes('\\')) {
    return { valid: false, error: 'Invalid filename' };
  }
  
  return { valid: true };
};
```

---

### 10. **XSS (Cross-Site Scripting) Protection**
- ⚠️ **Action Required**:
  - [ ] Sanitize all user-generated content before displaying
  - [ ] Use React's built-in XSS protection (auto-escaping)
  - [ ] Never use `dangerouslySetInnerHTML` without sanitization
  - [ ] Validate and sanitize URLs before using in links

**Implementation:**
```typescript
import DOMPurify from 'dompurify';

// ✅ Safe rendering
const SafeHTML = ({ html }: { html: string }) => {
  const sanitized = DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br'],
    ALLOWED_ATTR: ['href', 'target']
  });
  return <div dangerouslySetInnerHTML={{ __html: sanitized }} />;
};
```

---

## 🟡 **IMPORTANT (Should Implement Soon)**

### 11. **CSRF Protection**
- ⚠️ **Action Required**:
  - [ ] Implement CSRF tokens for state-changing operations
  - [ ] Verify origin header on API requests
  - [ ] Use SameSite cookies

**Note**: Supabase handles CSRF protection for auth, but verify for custom endpoints.

---

### 12. **Dependency Security**
- ⚠️ **Action Required**:
  - [ ] Run `npm audit` regularly
  - [ ] Update dependencies with security vulnerabilities
  - [ ] Use `npm audit fix` for automatic fixes
  - [ ] Consider using Snyk or Dependabot for monitoring

**Commands:**
```bash
npm audit
npm audit fix
npm audit fix --force  # Use with caution
```

---

### 13. **Logging & Monitoring**
- ⚠️ **Action Required**:
  - [ ] Log all security events (failed logins, unauthorized access attempts)
  - [ ] Monitor for suspicious activity
  - [ ] Set up alerts for security incidents
  - [ ] Use error tracking (Sentry, LogRocket)

**Recommended:**
- Sentry for error tracking
- Supabase Logs for database activity
- Custom admin logs table for security events

---

### 14. **API Security**
- ⚠️ **Action Required**:
  - [ ] Verify all API endpoints require authentication
  - [ ] Implement API key rotation
  - [ ] Use HTTPS for all API calls
  - [ ] Implement request signing for sensitive operations

---

### 15. **Admin Panel Security**
- ⚠️ **Action Required**:
  - [ ] Verify admin routes are protected server-side (not just client-side)
  - [ ] Implement admin action logging
  - [ ] Require 2FA for admin accounts
  - [ ] Limit admin access by IP (optional)
  - [ ] Implement admin session timeout

**Current Check:**
```typescript
// ✅ GOOD - Server-side admin check
const isAdmin = async (userId: string): Promise<boolean> => {
  const { data } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', userId)
    .single();
  return data?.role === 'admin';
};
```

---

## 🟢 **RECOMMENDED (Best Practices)**

### 16. **Content Security Policy (CSP)**
- ⚠️ **Action Required**: Implement strict CSP headers (see #4)

### 17. **Subresource Integrity (SRI)**
- ⚠️ **Action Required**: Add integrity checksums for external scripts

### 18. **Security.txt**
- ⚠️ **Action Required**: Add `security.txt` file for security researchers

**Create `public/security.txt`:**
```
Contact: mailto:security@yourdomain.com
Expires: 2025-12-31T23:59:59.000Z
Preferred-Languages: en
```

### 19. **Regular Security Audits**
- ⚠️ **Action Required**:
  - [ ] Perform security audits quarterly
  - [ ] Test for vulnerabilities
  - [ ] Review access logs
  - [ ] Update security measures

---

## 📋 **PRE-DEPLOYMENT CHECKLIST**

Before deploying to production, verify:

- [ ] All environment variables are set (no hardcoded keys)
- [ ] RLS policies are enabled on all tables
- [ ] Security headers are configured
- [ ] HTTPS is enforced
- [ ] Rate limiting is implemented
- [ ] Input validation is in place
- [ ] File uploads are secured
- [ ] Error messages don't expose sensitive info
- [ ] Admin routes are protected server-side
- [ ] Dependencies are up to date (`npm audit`)
- [ ] Logging is configured
- [ ] Backup strategy is in place
- [ ] Monitoring is set up

---

## 🚨 **IMMEDIATE ACTIONS REQUIRED**

1. **Remove hardcoded Supabase keys** from `src/services/supabase.ts`
2. **Add security headers** via hosting provider configuration
3. **Implement input sanitization** using DOMPurify
4. **Enable rate limiting** in Supabase dashboard
5. **Verify RLS policies** are enabled on all tables
6. **Test admin route protection** server-side

---

## 📚 **Resources**

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Supabase Security Best Practices](https://supabase.com/docs/guides/auth/row-level-security)
- [React Security Best Practices](https://reactjs.org/docs/dom-elements.html#dangerouslysetinnerhtml)
- [Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)

---

**Last Updated**: December 2024
**Status**: ⚠️ **CRITICAL SECURITY MEASURES REQUIRED BEFORE PRODUCTION**

