# 🚀 Quick Start - Admin System Testing

## ✅ What's Deployed

- ✅ Cloud Functions (sendTokensToUser)
- ✅ Firestore Security Rules
- 🔄 Flutter APK (building now)

---

## 🔴 NEXT: Create Admin Accounts

### Quick Steps:

1. **Open Firebase Console**: https://console.firebase.google.com
2. **Go to**: Authentication > Users > **Add user**
3. **Create 3 accounts with password `cneadmin1234`**:
   - `cnesup@outlook.com` (Super Admin)
   - `cnefinance@outlook.com` (Finance Admin)
   - `cneupdates@gmail.com` (Updates Admin)

4. **Copy each UID** after creation

5. **Go to**: Firestore Database > `admins` collection

6. **Add 3 documents** (one per admin):

---

### Super Admin Document

**Document ID:** [Paste Super Admin UID]

```
role: "super_admin"
email: "cnesup@outlook.com"
displayName: "Super Administrator"
permissions: [
  "manage_admins", "manage_finance", "send_tokens", 
  "view_transaction_logs", "manage_content", "upload_videos",
  "manage_programs", "manage_schedules", "manage_spotlight",
  "manage_quiz", "moderate_comments", "manage_news",
  "update_homepage", "system_settings", "user_management",
  "support_management"
]
isActive: true
createdAt: [Set to current time]
lastLogin: [Set to current time]
```

---

### Finance Admin Document

**Document ID:** [Paste Finance Admin UID]

```
role: "finance_admin"
email: "cnefinance@outlook.com"
displayName: "Finance Administrator"
permissions: [
  "manage_finance",
  "send_tokens",
  "view_transaction_logs"
]
isActive: true
createdAt: [Set to current time]
lastLogin: [Set to current time]
```

---

### Updates Admin Document

**Document ID:** [Paste Updates Admin UID]

```
role: "updates_admin"
email: "cneupdates@gmail.com"
displayName: "Updates Administrator"
permissions: [
  "manage_content", "upload_videos", "manage_programs",
  "manage_schedules", "manage_spotlight", "manage_quiz",
  "moderate_comments", "manage_news", "update_homepage"
]
isActive: true
createdAt: [Set to current time]
lastLogin: [Set to current time]
```

---

## 📱 When APK is Ready

1. **Find APK**: `build/app/outputs/flutter-apk/app-release.apk`
2. **Install** on test device
3. **Test each admin** using testing checklist

---

## 🧪 Quick Test

### Test Super Admin
- Login: `cnesup@outlook.com` / `cneadmin1234`
- Should see: Full admin dashboard (all features)
- Try: Send tokens to a user

### Test Finance Admin
- Login: `cnefinance@outlook.com` / `cneadmin1234`
- Should see: Finance dashboard only (orange badge)
- Try: Send tokens (should work)
- Try: Access content management (should be blocked)

### Test Updates Admin
- Login: `cneupdates@gmail.com` / `cneadmin1234`
- Should see: Updates dashboard only (blue badge)
- Try: Manage spotlight (should work)
- Try: Send tokens (should be blocked)

---

## 🔐 After Testing

**IMMEDIATELY change all passwords from `cneadmin1234`**

---

## 📚 Full Documentation

- Setup Details: `MANUAL_ADMIN_SETUP.md`
- Complete Docs: `ADMIN_SYSTEM_DOCUMENTATION.md`
- Deployment Checklist: `ADMIN_DEPLOYMENT_CHECKLIST.md`
- Current Status: `DEPLOYMENT_STATUS.md`

---

## ❓ Need Help?

Check Firebase Console:
- **Functions Logs**: Functions > sendTokensToUser > Logs
- **Firestore Data**: Firestore Database > Collections
- **Auth Users**: Authentication > Users

---

**Current Status**: Waiting for Flutter build to complete ⏳
