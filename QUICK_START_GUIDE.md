# Quick Start Guide - Multi-Project Setup
## Get Your 5 Firebase Projects Running in 30 Minutes

**Date:** December 19, 2025  
**Goal:** 50,000 accounts across 5 projects  
**Time Required:** 30-45 minutes

---

## 🚀 Step 1: Create Firebase Projects (15 minutes)

### 1.1 Open Firebase Console
```
https://console.firebase.google.com/
```

### 1.2 Create 5 Projects Quickly
For **each project** (do this 5 times):

1. Click **"Add project"**
2. Name: `coinnewsextratv-batch-01` (then 02, 03, 04, 05)
3. **Disable** Google Analytics
4. Click **"Create project"**
5. Wait 30 seconds
6. Click **"Continue"**

✅ **You should now have 5 projects**

---

## 🔧 Step 2: Enable Services (10 minutes)

### For EACH of the 5 projects, do this:

#### A. Enable Authentication (2 mins per project)
1. Click **"Authentication"** → **"Get started"**
2. Click **"Email/Password"**
3. Toggle **ON** → Click **"Save"**

#### B. Enable Firestore (2 mins per project)
1. Click **"Firestore Database"** → **"Create database"**
2. Choose **"Production mode"** → **"Next"**
3. Location: **us-central** → **"Enable"**

✅ **All 5 projects should now have Auth + Firestore enabled**

---

## ⚙️ Step 3: Get Firebase Configs (5 minutes)

### For EACH project:

1. Click ⚙️ **"Project settings"**
2. Scroll to **"Your apps"**
3. Click **Web icon** (</>)
4. App nickname: `Bulk Creator 01` (or 02, 03, 04, 05)
5. Click **"Register app"**
6. **COPY the config** and save it in a text file

Example config:
```javascript
{
  apiKey: "AIzaSyA...",
  authDomain: "coinnewsextratv-batch-01.firebaseapp.com",
  projectId: "coinnewsextratv-batch-01",
  storageBucket: "coinnewsextratv-batch-01.firebasestorage.app",
  messagingSenderId: "889552494681",
  appId: "1:889552494681:web:..."
}
```

**IMPORTANT:** Save all 5 configs in a file called `firebase-configs.txt`

---

## 📝 Step 4: Update Firestore Rules (2 minutes)

### For EACH project:

1. Go to **"Firestore Database"** → **"Rules"** tab
2. Replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

3. Click **"Publish"**

---

## 🔑 Step 5: Add Projects to Firebase CLI (3 minutes)

In your terminal (PowerShell), run:

```powershell
# Add all 5 projects
firebase use --add
# Select: coinnewsextratv-batch-01, Alias: batch-01

firebase use --add
# Select: coinnewsextratv-batch-02, Alias: batch-02

firebase use --add
# Select: coinnewsextratv-batch-03, Alias: batch-03

firebase use --add
# Select: coinnewsextratv-batch-04, Alias: batch-04

firebase use --add
# Select: coinnewsextratv-batch-05, Alias: batch-05
```

Verify:
```powershell
firebase projects:list
```

You should see all 5 projects listed.

---

## 🚀 Step 6: Deploy to First Project (TEST) (5 minutes)

Let's deploy to project #1 first to test:

```powershell
firebase deploy --project coinnewsextratv-batch-01
```

Wait 2-3 minutes for deployment.

---

## ✅ Step 7: Test First Project (2 minutes)

1. Open: `https://coinnewsextratv-batch-01.web.app/bulk-creator.html`
2. Enter: **10** accounts
3. Click **"Create Accounts"**
4. Wait for completion
5. Check Firebase Console:
   - Authentication → Should see 10 users
   - Firestore → admin_created_accounts → 10 documents

✅ **If test works, proceed to deploy all projects**

---

## 🎯 Step 8: Deploy to All Projects (10 minutes)

### Option A: Deploy All at Once (Automated)
```powershell
.\deploy-all-projects.ps1
```

### Option B: Deploy One by One (Manual)
```powershell
firebase deploy --project coinnewsextratv-batch-01
firebase deploy --project coinnewsextratv-batch-02
firebase deploy --project coinnewsextratv-batch-03
firebase deploy --project coinnewsextratv-batch-04
firebase deploy --project coinnewsextratv-batch-05
```

---

## 🎉 You're Done!

### Access Your Bulk Creators:
```
https://coinnewsextratv-batch-01.web.app/bulk-creator.html
https://coinnewsextratv-batch-02.web.app/bulk-creator.html
https://coinnewsextratv-batch-03.web.app/bulk-creator.html
https://coinnewsextratv-batch-04.web.app/bulk-creator.html
https://coinnewsextratv-batch-05.web.app/bulk-creator.html
```

### Access Multi-Project Dashboard:
```
https://coinnewsextratv-9c75a.web.app/multi-project-dashboard.html
```
(After you update the Firebase configs in the dashboard)

---

## 📊 Next Steps

### Today:
- [ ] Test each project with 10 accounts
- [ ] Verify all accounts created successfully
- [ ] Bookmark all URLs

### This Week:
- [ ] Create 500 accounts per project (2,500 total)
- [ ] Monitor Firebase quotas
- [ ] Fix any issues

### This Month:
- [ ] Scale to 10,000 accounts per project
- [ ] Reach 50,000 total accounts
- [ ] Set up backup system

---

## 🆘 Troubleshooting

### Deployment Failed?
```powershell
firebase login --reauth
firebase deploy --project coinnewsextratv-batch-01 --debug
```

### Can't Access bulk-creator.html?
- Wait 5 minutes after deployment
- Clear browser cache
- Check Hosting is enabled in Firebase Console

### Account Creation Failed?
- Check Firestore rules are set to allow writes
- Verify Hedera credentials are set
- Check Cloud Functions logs in Firebase Console

---

## 📞 Support Files

- **Full Documentation:** `MULTI_FIREBASE_ACCOUNT_CREATION_SYSTEM.md`
- **Detailed Setup:** `setup-firebase-projects.md`
- **Deployment Scripts:** `deploy-all-projects.ps1`, `deploy-single-project.ps1`
- **Dashboard:** `web/public/multi-project-dashboard.html`

---

**Total Setup Time:** ~30-45 minutes  
**Projects Created:** 5  
**Total Capacity:** 50,000 accounts  
**Ready to Scale:** YES ✅

**Good luck!** 🚀
