# 🧪 Chat Sanitization Test - Quick Start

## Step 1: Start Dev Server (if not running)

Open a new terminal and run:

```powershell
cd C:\Users\mahad\TantalusBoxingClubExpo\tantalus-boxing-club
npm start
```

Wait for: `Compiled successfully!` and the browser to open.

---

## Step 2: Open Chat Page

1. **Browser should open automatically** to `http://localhost:3000`
2. **If not**, manually open: `http://localhost:3000`
3. **Log in** (or create a test account if needed)
4. **Click "Social"** in the navigation menu
5. You should see the chat interface with a message input box

---

## Step 3: Open Browser DevTools

**Press `F12`** (or right-click → Inspect)

This opens the Developer Tools. We'll watch the Console tab for any errors.

---

## Step 4: Test Payload #1 (The Most Important)

### Copy this exactly:
```
<script>alert('XSS')</script>
```

### Steps:
1. **Paste** into the chat message input box
2. **Click "Send"** button
3. **Watch for**:
   - ✅ **GOOD**: Message appears as plain text showing `<script>alert('XSS')</script>`
   - ❌ **BAD**: An alert box pops up (this means sanitization failed!)

### Expected Result:
- ✅ Message displays as text (you can see the HTML tags)
- ✅ **NO alert box appears**
- ✅ Console (F12) shows no errors

---

## Step 5: Test More Payloads

Try these one by one (copy from `CHAT_XSS_TEST_PAYLOADS.txt`):

### Test 2:
```
<img src=x onerror=alert('XSS')>
```
**Expected**: Shows as plain text, no image, no alert

### Test 3:
```
javascript:alert('XSS')
```
**Expected**: Shows as plain text

### Test 4:
```
<svg onload=alert('XSS')>
```
**Expected**: Shows as plain text, no alert

---

## Step 6: Check Results

### ✅ **SUCCESS** if:
- All messages appear as plain text
- No alert boxes pop up
- Browser console is clean (no red errors)
- Messages are stored and displayed safely

### ❌ **FAILURE** if:
- Any alert box appears
- Scripts execute
- Console shows XSS warnings

---

## Step 7: Report Results

**If all tests pass**: ✅ Chat sanitization is working!

**If any test fails**: 
1. Note which payload failed
2. Take a screenshot if possible
3. Check browser console for errors
4. Let me know and I'll fix it immediately

---

## Quick Checklist:

- [ ] Dev server running
- [ ] Browser open to Social/Chat page
- [ ] DevTools open (F12)
- [ ] Test 1: `<script>alert('XSS')</script>` - ✅ Pass / ❌ Fail
- [ ] Test 2: `<img src=x onerror=alert('XSS')>` - ✅ Pass / ❌ Fail
- [ ] Test 3: `javascript:alert('XSS')` - ✅ Pass / ❌ Fail
- [ ] Test 4: `<svg onload=alert('XSS')>` - ✅ Pass / ❌ Fail
- [ ] All tests passed? ✅ / ❌

---

## Need Help?

**If dev server won't start**:
- Check if port 3000 is in use
- Try: `npm start` again
- Check for error messages

**If chat page won't load**:
- Make sure you're logged in
- Check browser console for errors
- Try refreshing the page

**If you see an alert box**:
- That means sanitization failed
- Note which payload triggered it
- Let me know immediately!

---

**Ready? Let's test!** 🚀

Start with Step 1 and work through each step. The most important test is #1 - if that passes, the others should too!

