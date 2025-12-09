# Notification Bell Sound Troubleshooting Guide

## Issue: No Sound When Notifications or Announcements Arrive

The notification bell sound should play automatically when:
- ✅ A new notification arrives (via real-time subscription)
- ✅ A new announcement is posted (creates notifications for all fighters)
- ✅ Any notification is created for your user

---

## Common Causes & Solutions

### 1. Browser Autoplay Blocking (MOST COMMON)

**Problem**: Modern browsers block autoplay audio until the user interacts with the page.

**Solution**:
1. **Click anywhere on the page** (button, link, etc.) to "unlock" audio
2. After clicking, the sound should work for future notifications
3. This is a browser security feature, not a bug

**Test**:
- Click anywhere on the page
- Have someone send you a notification
- Sound should play

---

### 2. Audio File Not Loading

**Check if file exists**:
- File should be at: `tantalus-boxing-club/public/boxing-bell-signals-6115 (1).mp3`
- ✅ File exists in your project

**Check browser console** (F12 → Console):
- Look for: `✅ Notification sound loaded successfully`
- If you see: `⚠️ Notification sound file not found` → File is missing or path is wrong

**Solution if file not found**:
1. Verify file exists: `public/boxing-bell-signals-6115 (1).mp3`
2. Check file name matches exactly (including spaces and parentheses)
3. Restart your dev server after adding the file

---

### 3. Real-Time Subscription Not Working

**Problem**: If CORS is blocking requests, real-time subscriptions won't work, so you won't get notifications.

**Check**:
1. Open browser console (F12)
2. Look for CORS errors
3. If you see CORS errors → Fix CORS in Supabase (see CORS_ERROR_EXPLANATION.md)

**Solution**:
- Fix CORS in Supabase Dashboard
- Add your domain to allowed origins
- Real-time subscriptions will then work

---

### 4. Volume Too Low or Muted

**Check**:
1. Browser volume settings
2. System volume
3. Tab volume (some browsers allow per-tab volume)

**Solution**:
- Increase browser/system volume
- Check if tab is muted (look for mute icon in browser tab)

---

### 5. Notifications Not Being Created

**Problem**: If announcements don't create notifications, the sound won't play.

**Check**:
1. When an announcement is posted, does a notification appear in the bell?
2. If no notification appears → Database trigger might not be set up

**Solution**:
1. Go to Supabase SQL Editor
2. Run: `database/FIX-NEWS-NOTIFICATIONS-COMPLETE.sql`
3. This sets up triggers to create notifications when news is posted

---

## Step-by-Step Diagnostic

### Step 1: Check Audio File
```bash
# Verify file exists
ls public/boxing-bell-signals-6115\ \(1\).mp3
```

**Expected**: File should exist

### Step 2: Check Browser Console
1. Open app in browser
2. Press F12 → Console tab
3. Look for:
   - ✅ `Notification sound loaded successfully: /boxing-bell-signals-6115 (1).mp3`
   - ❌ `Notification sound file not found` → File issue

### Step 3: Test Audio Loading
1. Open browser console (F12)
2. Type:
   ```javascript
   const audio = new Audio('/boxing-bell-signals-6115%20(1).mp3');
   audio.play();
   ```
3. **Expected**: Sound should play
4. **If error**: Check file path and browser console

### Step 4: Test Notification Creation
1. Login as Admin
2. Post a new announcement
3. Check if notification appears in bell (for other users)
4. If no notification → Database trigger issue

### Step 5: Test Real-Time Subscription
1. Open browser console (F12)
2. Look for Supabase connection errors
3. If CORS errors → Fix CORS first
4. Real-time subscription should show: `Subscribed to notifications_changes`

---

## Quick Fixes

### Fix 1: Unlock Audio (Most Common)
1. **Click anywhere on the page** (button, link, etc.)
2. This "unlocks" audio for the session
3. Future notifications will play sound

### Fix 2: Check File Path
1. Verify file is at: `public/boxing-bell-signals-6115 (1).mp3`
2. Restart dev server: `npm start`
3. Hard refresh browser: Ctrl+Shift+R

### Fix 3: Fix CORS (If Real-Time Not Working)
1. Go to Supabase Dashboard
2. Settings → API → Allowed Origins
3. Add: `https://tantalus-boxing-club.vercel.app`
4. Save and wait 1-2 minutes

### Fix 4: Set Up Database Triggers
1. Go to Supabase SQL Editor
2. Run: `database/FIX-NEWS-NOTIFICATIONS-COMPLETE.sql`
3. This ensures notifications are created when announcements are posted

---

## How It Works

### Notification Flow:
1. **Admin posts announcement** → Database trigger fires
2. **Trigger creates notifications** → One notification per fighter
3. **Real-time subscription detects** → New notification in database
4. **NotificationBell component** → Receives notification via subscription
5. **Sound plays** → `playNotificationSound()` is called
6. **Badge updates** → Unread count increases

### Sound Loading:
1. Component mounts → Tries to load audio file
2. Tries multiple paths → Handles different file locations
3. On success → Logs: `✅ Notification sound loaded successfully`
4. On failure → Logs: `⚠️ Notification sound file not found`

---

## Testing Checklist

- [ ] Audio file exists: `public/boxing-bell-signals-6115 (1).mp3`
- [ ] Browser console shows: `✅ Notification sound loaded successfully`
- [ ] Clicked on page to unlock audio
- [ ] CORS is fixed (no CORS errors in console)
- [ ] Database triggers are set up (for announcements)
- [ ] Real-time subscription is active (check console)
- [ ] Browser/system volume is up
- [ ] Tab is not muted

---

## Still Not Working?

### Debug Steps:
1. **Open browser console** (F12)
2. **Check for errors**:
   - Audio loading errors
   - CORS errors
   - Real-time subscription errors
3. **Test audio manually**:
   ```javascript
   // In browser console
   const audio = new Audio('/boxing-bell-signals-6115%20(1).mp3');
   audio.volume = 0.8;
   audio.play().then(() => console.log('Sound works!')).catch(e => console.error('Sound error:', e));
   ```
4. **Check notification creation**:
   - Go to Supabase Dashboard → Database → notifications table
   - See if notifications are being created when announcements are posted

---

## Summary

**Most Common Issues:**
1. **Browser autoplay blocking** → Click on page to unlock
2. **CORS blocking real-time** → Fix CORS in Supabase
3. **Database triggers not set up** → Run FIX-NEWS-NOTIFICATIONS-COMPLETE.sql
4. **Audio file not loading** → Check file path and console

**Quick Test:**
1. Click anywhere on the page (unlocks audio)
2. Have someone send you a notification
3. Sound should play

If it still doesn't work, check the browser console for specific error messages!
