# 🧪 Security Testing Plan

Complete security testing guide for Tantalus Boxing Club application.

---

## 📋 **TESTING OVERVIEW**

This plan covers:
- ✅ XSS (Cross-Site Scripting) testing
- ✅ Authorization testing
- ✅ Input validation testing
- ✅ File upload security testing
- ✅ RLS (Row Level Security) verification
- ✅ Error handling testing

**Estimated Time**: 4-6 hours  
**Priority**: High (before production)

---

## 🔴 **PRIORITY 1: RLS Verification (30 minutes)**

### Test: Verify Row Level Security

**Objective**: Ensure users can only access their own data.

**Steps**:

1. **Run RLS Verification Script**:
   ```sql
   -- Copy and paste into Supabase SQL Editor
   -- File: database/COMPLETE_RLS_VERIFICATION.sql
   ```

2. **Review Results**:
   - Section 1: Should show **0 rows** (no unprotected tables)
   - Section 4: All critical tables should show `✅ Protected`
   - Summary: All green checkmarks

3. **Manual Testing**:
   - Create two test accounts (User A and User B)
   - As User A, try to access User B's data via API
   - **Expected**: All requests should be denied (403 Forbidden)

**Success Criteria**:
- ✅ All tables have RLS enabled
- ✅ All critical tables have policies
- ✅ Users cannot access other users' data

---

## 🟡 **PRIORITY 2: XSS Testing (2 hours)**

### Test 1: Chat Component XSS

**Objective**: Verify chat messages are sanitized.

**Test Cases**:

1. **Script Injection**:
   ```
   Input: <script>alert('XSS')</script>
   Expected: Script tags removed, plain text displayed
   ```

2. **Image with onerror**:
   ```
   Input: <img src=x onerror=alert('XSS')>
   Expected: Image tag removed or sanitized
   ```

3. **JavaScript Protocol**:
   ```
   Input: javascript:alert('XSS')
   Expected: Link blocked or sanitized
   ```

4. **SVG with onload**:
   ```
   Input: <svg onload=alert('XSS')>
   Expected: SVG tag removed
   ```

5. **Event Handlers**:
   ```
   Input: <div onclick=alert('XSS')>Click me</div>
   Expected: Event handler removed
   ```

**How to Test**:
1. Go to Social/Chat page
2. Try sending each test case above
3. Verify message is sanitized (no script execution)
4. Check browser console for any errors
5. Verify message displays as plain text

**Success Criteria**:
- ✅ No scripts execute
- ✅ No alert boxes appear
- ✅ Messages display as safe text
- ✅ Browser console shows no XSS warnings

---

### Test 2: Form Input XSS

**Objective**: Verify all form inputs sanitize user data.

**Components to Test**:
- Registration form
- Login form
- Profile edit forms
- Dispute resolution forms
- Matchmaking forms
- Admin forms

**Test Cases** (for each form):
```
1. <script>alert('XSS')</script>
2. <img src=x onerror=alert('XSS')>
3. javascript:alert('XSS')
4. <svg onload=alert('XSS')>
5. '; DROP TABLE users; --
```

**How to Test**:
1. Navigate to each form
2. Enter test payloads in text fields
3. Submit form
4. Verify data is sanitized
5. Check database (if possible) to verify sanitization

**Success Criteria**:
- ✅ No scripts execute
- ✅ Data stored is sanitized
- ✅ Displayed data is safe

---

## 🟡 **PRIORITY 3: Authorization Testing (1 hour)**

### Test 1: User Data Access

**Objective**: Verify users cannot access other users' data.

**Test Cases**:

1. **Access Other User's Profile**:
   - As User A, try to access User B's profile
   - **Expected**: Denied or redirected

2. **Modify Other User's Data**:
   - As User A, try to update User B's fighter profile
   - **Expected**: 403 Forbidden or error

3. **Access Other User's Messages**:
   - As User A, try to delete User B's chat message
   - **Expected**: Denied

4. **Access Other User's Fight Records**:
   - As User A, try to modify User B's fight records
   - **Expected**: Denied

**How to Test**:
1. Create two test accounts
2. Log in as User A
3. Try to access/modify User B's data
4. Verify all attempts are denied

**Success Criteria**:
- ✅ All unauthorized access attempts fail
- ✅ Error messages don't leak sensitive info
- ✅ RLS policies enforce restrictions

---

### Test 2: Admin Functions

**Objective**: Verify only admins can access admin functions.

**Test Cases**:

1. **Non-Admin Access**:
   - As regular user, try to access `/admin` routes
   - **Expected**: Redirected to login or denied

2. **Admin Access**:
   - As admin, access admin functions
   - **Expected**: Allowed

3. **Admin Operations**:
   - As regular user, try to perform admin operations
   - **Expected**: Denied

**How to Test**:
1. Create admin and regular user accounts
2. Test admin functions as regular user
3. Test admin functions as admin
4. Verify proper access control

**Success Criteria**:
- ✅ Regular users cannot access admin functions
- ✅ Admins can access all functions
- ✅ RLS policies enforce admin restrictions

---

## 🟡 **PRIORITY 4: File Upload Security (1 hour)**

### Test: File Upload Validation

**Objective**: Verify file uploads are properly validated.

**Test Cases**:

1. **File Size Limits**:
   - Try uploading image > 10MB
   - Try uploading video > 50MB
   - **Expected**: Rejected with error message

2. **File Type Validation**:
   - Try uploading `.exe` file
   - Try uploading `.php` file
   - Try uploading `.js` file
   - **Expected**: Rejected (only images/videos allowed)

3. **Malicious Filenames**:
   - Try uploading file named `../../../etc/passwd`
   - Try uploading file with special characters
   - **Expected**: Rejected or sanitized

4. **Valid Files**:
   - Upload valid image (JPEG, PNG)
   - Upload valid video (MP4)
   - **Expected**: Accepted

**How to Test**:
1. Go to Media Hub or file upload component
2. Try uploading each test case
3. Verify validation works
4. Check error messages

**Success Criteria**:
- ✅ Invalid files rejected
- ✅ Valid files accepted
- ✅ Error messages are user-friendly
- ✅ No path traversal possible

---

## 🟡 **PRIORITY 5: Error Handling (30 minutes)**

### Test: Error Message Security

**Objective**: Verify errors don't leak sensitive information.

**Test Cases**:

1. **Database Errors**:
   - Trigger a database error
   - **Expected**: Generic error message, no SQL details

2. **Authentication Errors**:
   - Try invalid login
   - **Expected**: Generic "Invalid credentials" message

3. **API Errors**:
   - Trigger API error
   - **Expected**: Generic error, no stack traces

4. **Network Errors**:
   - Disconnect network, try operation
   - **Expected**: User-friendly error message

**How to Test**:
1. Intentionally trigger errors
2. Check error messages shown to users
3. Verify no sensitive info exposed
4. Check browser console (should have detailed logs)

**Success Criteria**:
- ✅ No database structure exposed
- ✅ No stack traces in user-facing errors
- ✅ No API keys or tokens in errors
- ✅ Generic, user-friendly messages

---

## 📊 **TEST RESULTS TEMPLATE**

Use this template to document test results:

```markdown
## Test: [Test Name]
**Date**: [Date]
**Tester**: [Name]
**Status**: ✅ Pass / ❌ Fail / ⚠️ Partial

### Test Cases:
- [ ] Test Case 1: [Result]
- [ ] Test Case 2: [Result]
- [ ] Test Case 3: [Result]

### Issues Found:
1. [Issue description]
2. [Issue description]

### Fixes Applied:
1. [Fix description]
2. [Fix description]

### Retest Results:
- [ ] All tests pass
- [ ] Issues resolved
```

---

## 🎯 **QUICK TEST CHECKLIST**

### Before Production:

- [ ] RLS verification script run (all green)
- [ ] XSS tests in chat component (all pass)
- [ ] XSS tests in all forms (all pass)
- [ ] Authorization tests (users can't access others' data)
- [ ] Admin authorization tests (only admins can access)
- [ ] File upload tests (invalid files rejected)
- [ ] Error handling tests (no info leakage)
- [ ] Manual security review completed

---

## 🚨 **CRITICAL TEST SCENARIOS**

### Scenario 1: Malicious User Attack

**Setup**:
- Create test account: `attacker@test.com`
- Create victim account: `victim@test.com`

**Tests**:
1. Attacker tries to access victim's profile → Should fail
2. Attacker sends XSS payload in chat → Should be sanitized
3. Attacker tries to upload malicious file → Should be rejected
4. Attacker tries to access admin functions → Should fail

**Expected**: All attacks fail

---

### Scenario 2: SQL Injection Attempt

**Setup**: Try SQL injection in all text inputs

**Test Cases**:
```
'; DROP TABLE users; --
' OR '1'='1
' UNION SELECT * FROM users--
```

**Expected**: All sanitized, no SQL execution

**Note**: Supabase uses parameterized queries, so this should be protected, but test anyway.

---

### Scenario 3: CSRF Attack

**Setup**: Test cross-site request forgery protection

**Tests**:
1. Try to perform actions without proper authentication
2. Try to use expired tokens
3. Try to modify requests

**Expected**: All fail with proper error messages

---

## 📚 **TESTING TOOLS**

### Recommended Tools:

1. **Browser DevTools**:
   - Console for XSS detection
   - Network tab for API testing
   - Application tab for storage testing

2. **Postman/Insomnia**:
   - API testing
   - Authorization testing
   - Error testing

3. **OWASP ZAP** (Optional):
   - Automated security scanning
   - XSS detection
   - SQL injection testing

---

## ✅ **SIGN-OFF CHECKLIST**

Before marking security testing complete:

- [ ] All RLS policies verified
- [ ] All XSS tests pass
- [ ] All authorization tests pass
- [ ] All file upload tests pass
- [ ] All error handling tests pass
- [ ] All critical scenarios tested
- [ ] All issues documented
- [ ] All fixes applied and retested
- [ ] Security audit report reviewed
- [ ] Ready for production

---

## 📝 **REPORTING ISSUES**

When you find security issues:

1. **Document Immediately**:
   - What was tested
   - What happened
   - Expected vs actual
   - Severity (Critical/High/Medium/Low)

2. **Fix Priority**:
   - Critical: Fix immediately
   - High: Fix before production
   - Medium: Fix in next release
   - Low: Fix when convenient

3. **Retest After Fixes**:
   - Verify fix works
   - Test for regressions
   - Update test results

---

**Last Updated**: Generated automatically  
**Next Review**: After each security fix

