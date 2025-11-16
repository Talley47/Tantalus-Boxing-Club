# Rules/Guidelines Page - Explanation

## 🔍 **Why Rules Appear on Localhost but Not on Vercel**

### **The Issue**

You have **two different applications**:

1. **Old React App** (Material-UI, port 3005 or similar)
   - ✅ Has Rules/Guidelines component at `/rules` route
   - ✅ Uses `RulesGuidelines` component from `src/components/RulesGuidelines/`
   - ✅ Integrated into the old React app's navigation

2. **New Next.js App** (port 3000, deployed to Vercel)
   - ❌ **Did NOT have** a Rules/Guidelines page
   - ❌ Simple homepage with no rules content
   - ❌ No `/rules` route

### **What You're Seeing**

- **`http://localhost:3000/`** - If you're seeing rules here, you might be:
  - Looking at the old React app on a different port
  - Or the rules are embedded in the HomePage component (old React app)
  
- **`https://tantalus-boxing-club.vercel.app/`** - This is the **new Next.js app**:
  - Simple landing page (no rules)
  - No `/rules` route existed

---

## ✅ **Solution Implemented**

I've created a **Rules/Guidelines page** for the Next.js app:

1. ✅ **Created:** `src/app/rules/page.tsx`
   - Full Rules & Guidelines content
   - Based on `CREATIVE_FIGHTER_LEAGUE_RULES_AND_GUIDELINES.md`
   - Styled with Tailwind CSS (matches Next.js app design)

2. ✅ **Added to Navigation:**
   - Added "Rules" link to the navigation menu
   - Accessible from the main navigation bar

3. ✅ **Added to Homepage:**
   - Added "Rules & Guidelines" button on the landing page
   - Users can access rules without logging in

---

## 🚀 **Next Steps**

### **1. Deploy the Changes**

```bash
cd tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs
git add src/app/rules/page.tsx src/components/navigation/Navigation.tsx src/app/page.tsx
git commit -m "Add Rules/Guidelines page to Next.js app"
git push
```

### **2. Verify on Vercel**

After deployment:
1. Visit: `https://tantalus-boxing-club.vercel.app/rules`
2. You should see the full Rules & Guidelines page
3. The homepage should have a "Rules & Guidelines" button

### **3. Test Locally**

```bash
cd tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs
npm run dev
```

Then visit:
- `http://localhost:3000/` - Should have "Rules & Guidelines" button
- `http://localhost:3000/rules` - Should show full rules page

---

## 📋 **What's Included in the Rules Page**

The Rules page includes all sections from the Creative Fighter League Rules:

1. ✅ Introduction
2. ✅ Tier System (with full table)
3. ✅ Points System
4. ✅ Rankings System
5. ✅ Matchmaking Rules
6. ✅ Tournament Rules
7. ✅ Training Camp System
8. ✅ Callout/Rematch System
9. ✅ Fight Scheduling Rules
10. ✅ Demotion and Promotion System
11. ✅ Code of Conduct
12. ✅ General Guidelines

---

## 🔍 **Verification Checklist**

After deployment, verify:

- [ ] `https://tantalus-boxing-club.vercel.app/rules` loads correctly
- [ ] All sections are visible and readable
- [ ] Navigation menu includes "Rules" link
- [ ] Homepage has "Rules & Guidelines" button
- [ ] Links work correctly (table of contents)
- [ ] Styling matches the rest of the app

---

## 📝 **Note**

The old React app and new Next.js app are **separate applications**:
- Old React app: Uses Material-UI, has its own Rules component
- New Next.js app: Now has its own Rules page (just created)

Both can coexist, but the Vercel deployment is the **new Next.js app**, which now has the Rules page.

---

**Last Updated:** 2025-01-16

