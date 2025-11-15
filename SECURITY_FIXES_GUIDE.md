# 🔧 Security Fixes Implementation Guide

This guide provides step-by-step instructions to fix all security issues identified in the audit.

---

## 🔴 **PRIORITY 1: Verify RLS (30 minutes)**

### Step 1: Run RLS Verification

1. **Open Supabase Dashboard**:
   - Go to: https://supabase.com/dashboard
   - Select your project: `andmtvsqqomgwphotdwf`
   - Click **SQL Editor** in the left sidebar

2. **Run Verification Script**:
   - Open file: `database/COMPLETE_RLS_VERIFICATION.sql`
   - Copy the entire contents
   - Paste into Supabase SQL Editor
   - Click **Run** (or press `Ctrl+Enter`)

3. **Review Results**:
   - **Section 1**: Should show **0 rows** (no unprotected tables)
   - **Section 4**: All critical tables should show `✅ Protected`
   - **Summary**: Should show all green checkmarks

### Step 2: Fix Any Issues Found

**If you see unprotected tables**:

```sql
-- For each table shown in Section 1, run:
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- Then create appropriate policies (see existing schema files)
```

**If you see locked tables** (RLS enabled but no policies):

```sql
-- Example: Create a basic policy
CREATE POLICY "Users can view own data" ON table_name
    FOR SELECT
    USING (auth.uid() = user_id);
```

### Step 3: Verify Fixes

- Re-run the verification script
- All sections should now show green checkmarks
- Test with different user accounts

---

## 🟡 **PRIORITY 2: Secure Chat Component (2 hours)**

### File: `src/components/Social/Social.tsx`

### Step 1: Add Sanitization Imports

```typescript
import { sanitizeHTML, sanitizeText } from '../../utils/securityUtils';
```

### Step 2: Sanitize Message Display

Find where messages are displayed and add sanitization:

```typescript
// Before (unsafe):
<div>{message.content}</div>

// After (safe):
<div dangerouslySetInnerHTML={{ 
  __html: sanitizeHTML(message.content) 
}} />
```

### Step 3: Sanitize Message Input

Find the message send handler:

```typescript
// Before (unsafe):
const handleSendMessage = async (content: string) => {
  await sendMessage(content);
};

// After (safe):
const handleSendMessage = async (content: string) => {
  const sanitized = sanitizeText(content);
  if (!sanitized.trim()) return; // Don't send empty messages
  await sendMessage(sanitized);
};
```

### Step 4: Sanitize Usernames

```typescript
// When displaying usernames:
<span>{sanitizeText(user.username)}</span>
```

### Step 5: Test

Try sending these XSS payloads (they should be sanitized):
- `<script>alert('XSS')</script>`
- `<img src=x onerror=alert('XSS')>`
- `javascript:alert('XSS')`

---

## 🟡 **PRIORITY 3: Add Input Sanitization (4-6 hours)**

### Step 1: Identify Components Needing Sanitization

Run this search to find components:
```bash
grep -r "onChange\|onSubmit\|handleChange" src/components --include="*.tsx"
```

### Step 2: Add Sanitization to Each Component

**Template for each component**:

```typescript
// 1. Import security utilities
import { sanitizeText, validateEmail, validateTextLength } from '../../utils/securityUtils';

// 2. Sanitize on input
const handleInputChange = (field: string, value: string) => {
  const sanitized = sanitizeText(value);
  setFormData(prev => ({ ...prev, [field]: sanitized }));
};

// 3. Validate before submit
const handleSubmit = async (e: React.FormEvent) => {
  e.preventDefault();
  
  // Validate email
  const emailValidation = validateEmail(formData.email);
  if (!emailValidation.valid) {
    setError(emailValidation.error);
    return;
  }
  
  // Validate text length
  const nameValidation = validateTextLength(formData.name, 2, 100, 'Name');
  if (!nameValidation.valid) {
    setError(nameValidation.error);
    return;
  }
  
  // Submit sanitized data
  await submitForm(formData);
};
```

### Step 3: Priority Components to Fix

Fix in this order:

1. **High Priority** (User-generated content):
   - `src/components/Social/Social.tsx` ⚠️ **CRITICAL**
   - `src/components/DisputeResolution/DisputeResolution.tsx`
   - `src/components/Matchmaking/Matchmaking.tsx`

2. **Medium Priority** (Form inputs):
   - `src/components/Admin/NewsManagement.tsx`
   - `src/components/Admin/CalendarEventManagement.tsx`
   - `src/components/TrainingCamps/TrainingCamps.tsx`

3. **Lower Priority** (Admin/internal):
   - `src/components/Admin/*.tsx` (all admin components)

---

## 🟡 **PRIORITY 4: Review Error Handling (2 hours)**

### Step 1: Find All Error Handlers

```bash
grep -r "catch\|\.error\|console\.error" src --include="*.tsx" --include="*.ts"
```

### Step 2: Replace Unsafe Error Messages

**Before (unsafe)**:
```typescript
catch (error) {
  setError(`Database error: ${error.message}`);
  console.error(error);
}
```

**After (safe)**:
```typescript
import { sanitizeErrorMessage } from '../../utils/securityUtils';

catch (error) {
  console.error('Internal error:', error); // Log full error server-side
  setError(sanitizeErrorMessage(error, 'An error occurred. Please try again.'));
}
```

### Step 3: Check for Information Leakage

Look for these patterns and fix them:

- ❌ `error.message` shown to users
- ❌ `error.stack` in user-facing errors
- ❌ Database error details exposed
- ❌ API keys or tokens in error messages
- ❌ File paths or system information

---

## 🟡 **PRIORITY 5: Verify Authorization (2 hours)**

### Step 1: Test Authorization

1. **Create Test Accounts**:
   - User A (regular user)
   - User B (regular user)
   - Admin account

2. **Test as User A**:
   - Try to access User B's data
   - Try to modify User B's data
   - Try to access admin functions
   - **Expected**: All should be denied

3. **Test as Admin**:
   - Access all user data
   - Modify user data
   - Access admin functions
   - **Expected**: All should work

### Step 2: Fix Client-Side Authorization Issues

**Find client-side admin checks**:
```bash
grep -r "isAdmin\|is_admin\|role.*admin" src/components --include="*.tsx"
```

**Verify server-side protection**:
- All admin operations should be protected by RLS
- Never trust client-side checks alone

**Example Fix**:
```typescript
// ❌ BAD - Client-side only
if (user?.isAdmin) {
  await deleteUser(otherUserId);
}

// ✅ GOOD - Server-side RLS protects
// The RLS policy ensures only admins can delete
await supabase
  .from('users')
  .delete()
  .eq('id', otherUserId);
// If user is not admin, RLS will block this
```

---

## 📋 **TESTING CHECKLIST**

After implementing fixes, test:

### XSS Protection:
- [ ] Try XSS payloads in all text inputs
- [ ] Try XSS payloads in chat messages
- [ ] Verify all are sanitized/blocked

### Authorization:
- [ ] Test with regular user account
- [ ] Test with admin account
- [ ] Verify users can't access other users' data
- [ ] Verify admin functions work for admins only

### File Upload:
- [ ] Try uploading files > size limit
- [ ] Try uploading invalid file types
- [ ] Try uploading files with malicious names
- [ ] Verify all are rejected

### Error Handling:
- [ ] Trigger errors intentionally
- [ ] Verify no sensitive info exposed
- [ ] Verify user-friendly messages shown

---

## 🎯 **QUICK WINS (Do First)**

These are the easiest fixes with highest impact:

1. **Run RLS Verification** (30 min) - Just verify, no code changes
2. **Add sanitization to chat** (1 hour) - One component, high risk
3. **Review error messages** (1 hour) - Search and replace pattern

---

## 📚 **RESOURCES**

- **Security Utils**: `src/utils/securityUtils.ts`
- **RLS Verification**: `database/COMPLETE_RLS_VERIFICATION.sql`
- **Security Audit**: `SECURITY_AUDIT_REPORT.md`
- **Supabase RLS Docs**: https://supabase.com/docs/guides/auth/row-level-security

---

## ✅ **SUCCESS CRITERIA**

You're done when:

- ✅ RLS verification shows all green checkmarks
- ✅ Chat component sanitizes all user input
- ✅ All form inputs use sanitization
- ✅ Error messages don't expose sensitive info
- ✅ Authorization tests pass
- ✅ Security testing shows no vulnerabilities

---

**Estimated Total Time**: 8-12 hours  
**Priority Order**: RLS → Chat → Inputs → Errors → Authorization

