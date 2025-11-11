# 🚨 Supabase Email Rate Limit Fix

## **Current Issue:**
- `AuthApiError: email rate limit exceeded`
- Too many registration attempts in short time
- Supabase temporarily blocking email sending

## **Solutions:**

### **Option 1: Wait and Retry (15-30 minutes)**
- Rate limit will reset automatically
- Try registration again after waiting

### **Option 2: Disable Email Confirmation (Development)**
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Authentication** → **Settings**
4. **UNCHECK** "Enable email confirmations"
5. **Save changes**

### **Option 3: Use Admin API for Testing**
- Use service role key to create users without email confirmation
- Bypass rate limits for development testing

## **Prevention:**
- Use different email addresses for testing
- Wait between registration attempts
- Disable email confirmation during development
- Re-enable for production

---

**Recommended: Disable email confirmation for development, then re-enable for production!**
