# 🧪 Quick Security Test - Step by Step

Follow this guide to test chat sanitization and verify RLS in 30 minutes.

---

## ✅ **TEST 1: Chat Sanitization (10 minutes)**

### Step 1: Start Your Dev Server

```bash
cd C:\Users\mahad\TantalusBoxingClubExpo\tantalus-boxing-club
npm start
```

Wait for the app to load in your browser.

---

### Step 2: Navigate to Chat

1. **Open your app** in browser (usually `http://localhost:3000`)
2. **Log in** (or create a test account)
3. **Click on "Social"** in the navigation menu
4. You should see the chat interface

---

### Step 3: Test XSS Payloads

Try sending each of these messages one by one. **Expected**: All should be sanitized (no scripts execute).

#### Test 1: Basic Script Tag
```
<script>alert('XSS')</script>
```
**Expected Result**: 
- ✅ Message appears as plain text: `<script>alert('XSS')</script>`
- ✅ No alert box appears
- ✅ Browser console shows no errors

#### Test 2: Image with onerror
```
<img src=x onerror=alert('XSS')>
```
**Expected Result**:
- ✅ Message appears as plain text (no image)
- ✅ No alert box appears

#### Test 3: JavaScript Protocol
```
javascript:alert('XSS')
```
**Expected Result**:
- ✅ Message appears as plain text
- ✅ If it becomes a link, clicking it should do nothing (or be blocked)

#### Test 4: SVG with onload
```
<svg onload=alert('XSS')>
```
**Expected Result**:
- ✅ Message appears as plain text
- ✅ No alert box appears

#### Test 5: Event Handler
```
<div onclick=alert('XSS')>Click me</div>
```
**Expected Result**:
- ✅ Message appears as plain text
- ✅ Clicking it does nothing

#### Test 6: Mixed Content
```
Hello <script>alert('XSS')</script> world!
```
**Expected Result**:
- ✅ Message shows: "Hello <script>alert('XSS')</script> world!"
- ✅ No alert box appears

---

### Step 4: Check Browser Console

1. **Open DevTools**: Press `F12` or right-click → Inspect
2. **Go to Console tab**
3. **Look for**:
   - ✅ No XSS warnings
   - ✅ No script execution errors
   - ✅ Messages about sanitization (if logged)

---

### Step 5: Verify in Database (Optional)

If you have access to Supabase:

1. Go to Supabase Dashboard → Table Editor
2. Open `chat_messages` table
3. Find your test messages
4. **Verify**: The `message` column shows sanitized content (HTML tags removed)

---

### ✅ **Success Criteria**

- ✅ All test payloads are sanitized
- ✅ No alert boxes appear
- ✅ No scripts execute
- ✅ Messages display as safe text
- ✅ Browser console is clean

**If any test fails**: Note which one and we'll fix it.

---

## ✅ **TEST 2: RLS Verification (20 minutes)**

### Step 1: Open Supabase Dashboard

1. **Go to**: https://supabase.com/dashboard
2. **Sign in** (if needed)
3. **Select your project**: `andmtvsqqomgwphotdwf`

---

### Step 2: Open SQL Editor

1. **Click "SQL Editor"** in the left sidebar
2. **Click "New Query"** button (top right)
3. You should see an empty SQL editor

---

### Step 3: Copy Verification Script

1. **Open this file** in your code editor:
   - `database/COMPLETE_RLS_VERIFICATION.sql`

2. **Select All** (Ctrl+A)

3. **Copy** (Ctrl+C)

---

### Step 4: Paste and Run

1. **Paste** into Supabase SQL Editor (Ctrl+V)

2. **Click "Run"** button (or press `Ctrl+Enter`)

3. **Wait** for results (may take 10-30 seconds)

---

### Step 5: Review Results

The script will show **7 sections**. Review each:

#### **Section 1: Tables WITHOUT RLS** 🔴
- **Expected**: Should show **0 rows**
- **If you see tables**: ⚠️ Those need RLS enabled!

#### **Section 2: All Tables with RLS Status** ✅
- **Look for**: All should show `✅ RLS Enabled`
- **Check**: Policy count should be > 0

#### **Section 3: All RLS Policies** 📋
- **Review**: Lists all policies
- **Verify**: Critical tables have policies

#### **Section 4: Critical Tables Status** 🔴
- **Expected**: All should show `✅ Protected`
- **Critical tables**: fighter_profiles, fight_records, chat_messages, etc.

#### **Section 5: Tables with RLS but NO POLICIES** ⚠️
- **Expected**: Should show **0 rows**
- **If you see tables**: ⚠️ They're locked! Need policies.

#### **Section 6: Policy Coverage Analysis** 📊
- **Review**: Shows which operations are covered
- **Verify**: SELECT, INSERT, UPDATE, DELETE policies exist

#### **Section 7: Summary Report** 📊
- **Look at the bottom**: Should see green checkmarks
- **Check for warnings**: Fix any issues mentioned

---

### Step 6: Fix Any Issues

**If Section 1 shows unprotected tables**:

```sql
-- For each table shown, run:
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
```

**If Section 5 shows locked tables**:

```sql
-- Create a basic policy (example):
CREATE POLICY "Users can view own data" ON table_name
    FOR SELECT
    USING (auth.uid() = user_id);
```

**After fixing, re-run the verification script** to confirm.

---

### Step 7: Manual Authorization Test (Optional)

1. **Create two test accounts**:
   - User A: `testuser1@test.com`
   - User B: `testuser2@test.com`

2. **Log in as User A**

3. **Try to access User B's data**:
   - Try viewing User B's profile
   - Try modifying User B's data
   - **Expected**: All should be denied

4. **Log in as User B**

5. **Try to access User A's data**:
   - Try viewing User A's profile
   - Try modifying User A's data
   - **Expected**: All should be denied

---

### ✅ **Success Criteria**

- ✅ Section 1: **0 rows** (no unprotected tables)
- ✅ Section 4: All critical tables show `✅ Protected`
- ✅ Section 5: **0 rows** (no locked tables)
- ✅ Section 7: Summary shows all green checkmarks
- ✅ Manual tests: Users can't access each other's data

---

## 📋 **TEST RESULTS CHECKLIST**

After completing both tests, check off:

### Chat Sanitization:
- [ ] Test 1: `<script>` tag sanitized
- [ ] Test 2: `<img onerror>` sanitized
- [ ] Test 3: `javascript:` protocol blocked
- [ ] Test 4: `<svg onload>` sanitized
- [ ] Test 5: Event handlers removed
- [ ] Test 6: Mixed content sanitized
- [ ] Browser console clean
- [ ] No scripts executed

### RLS Verification:
- [ ] Section 1: 0 unprotected tables
- [ ] Section 2: All tables have RLS
- [ ] Section 4: All critical tables protected
- [ ] Section 5: 0 locked tables
- [ ] Section 7: All green checkmarks
- [ ] Manual authorization test passed

---

## 🚨 **IF YOU FIND ISSUES**

### Chat Sanitization Issues:

**If an alert box appears**:
1. Note which test payload triggered it
2. Check browser console for errors
3. Let me know and I'll fix it

**If messages don't display**:
1. Check browser console for errors
2. Verify `sanitizeText` is imported
3. Check if there are TypeScript errors

### RLS Issues:

**If tables are unprotected**:
1. Note which tables
2. Enable RLS (see Step 6 above)
3. Create policies
4. Re-run verification

**If tables are locked**:
1. Note which tables
2. Create policies (see Step 6 above)
3. Re-run verification

---

## 📝 **REPORT YOUR RESULTS**

After testing, note:

1. **Chat Tests**: Which tests passed/failed?
2. **RLS Verification**: What did Section 7 summary say?
3. **Issues Found**: Any problems?
4. **All Good**: ✅ Ready for production?

---

## 🎯 **QUICK REFERENCE**

### Test Chat Sanitization:
1. Go to Social page
2. Send: `<script>alert('XSS')</script>`
3. Verify: No alert appears

### Verify RLS:
1. Open Supabase SQL Editor
2. Run: `database/COMPLETE_RLS_VERIFICATION.sql`
3. Check: Section 7 summary

---

**Estimated Time**: 30 minutes total  
**Difficulty**: Easy  
**Priority**: 🔴 Critical

Good luck! Let me know what you find. 🚀

