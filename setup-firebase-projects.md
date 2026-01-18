# Firebase Projects Setup Guide
## Creating 5 Batch Account Projects

**Date:** December 19, 2025  
**Account:** yerinssaibs@gmail.com  
**Target:** 50,000 accounts across 5 projects

---

## 📋 Projects to Create

| # | Project ID | Purpose | Target Accounts | URL |
|---|------------|---------|-----------------|-----|
| 1 | coinnewsextratv-batch-01 | Batch creation #1 | 10,000 | https://coinnewsextratv-batch-01.web.app |
| 2 | coinnewsextratv-batch-02 | Batch creation #2 | 10,000 | https://coinnewsextratv-batch-02.web.app |
| 3 | coinnewsextratv-batch-03 | Batch creation #3 | 10,000 | https://coinnewsextratv-batch-03.web.app |
| 4 | coinnewsextratv-batch-04 | Batch creation #4 | 10,000 | https://coinnewsextratv-batch-04.web.app |
| 5 | coinnewsextratv-batch-05 | Batch creation #5 | 10,000 | https://coinnewsextratv-batch-05.web.app |

---

## 🚀 Step-by-Step Setup

### Step 1: Create Each Firebase Project

For **each project** (01 through 05), follow these steps:

#### 1.1 Open Firebase Console
```
https://console.firebase.google.com/
```

#### 1.2 Create New Project
1. Click **"Add project"** or **"Create a project"**
2. Enter project name: `coinnewsextratv-batch-01` (then 02, 03, 04, 05)
3. Click **Continue**

#### 1.3 Google Analytics (Optional)
- **Recommended:** Disable Google Analytics
- Reason: Faster setup, not needed for batch accounts
- Click **"Disable Google Analytics"**
- Click **"Create project"**

#### 1.4 Wait for Project Creation
- Takes 30-60 seconds
- Click **"Continue"** when ready

---

### Step 2: Enable Required Services (For Each Project)

#### 2.1 Enable Authentication

1. In Firebase Console, click **"Authentication"**
2. Click **"Get started"**
3. Click **"Email/Password"** under Sign-in method
4. Toggle **"Email/Password"** to **ENABLED**
5. Click **"Save"**

#### 2.2 Enable Cloud Firestore

1. Click **"Firestore Database"** in left menu
2. Click **"Create database"**
3. Select **"Start in production mode"** (we'll add rules later)
4. Click **"Next"**
5. Choose location: **us-central (or your region)**
6. Click **"Enable"**

#### 2.3 Enable Cloud Functions

1. Click **"Functions"** in left menu
2. Click **"Get started"**
3. Click **"Continue"** (will be enabled when you deploy)

#### 2.4 Enable Hosting

1. Click **"Hosting"** in left menu
2. Click **"Get started"**
3. Click through the wizard (will be configured when you deploy)

---

### Step 3: Get Firebase Config for Each Project

For **each project**, you need to get the configuration:

#### 3.1 Open Project Settings
1. Click ⚙️ gear icon → **"Project settings"**
2. Scroll down to **"Your apps"** section
3. Click **Web icon** (</>) to add a web app

#### 3.2 Register Web App
1. App nickname: `Bulk Account Creator 01` (or 02, 03, etc.)
2. **Do NOT** check "Also set up Firebase Hosting"
3. Click **"Register app"**

#### 3.3 Copy Firebase Config
You'll see something like this:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyA...",
  authDomain: "coinnewsextratv-batch-01.firebaseapp.com",
  projectId: "coinnewsextratv-batch-01",
  storageBucket: "coinnewsextratv-batch-01.firebasestorage.app",
  messagingSenderId: "889552494681",
  appId: "1:889552494681:web:..."
};
```

**SAVE THIS!** You'll need it for each project.

#### 3.4 Store Configs
Create a file to save all configs: `firebase-configs.txt`

```
# Project 1
PROJECT: coinnewsextratv-batch-01
apiKey: ...
authDomain: ...
projectId: ...
messagingSenderId: ...
appId: ...

# Project 2
PROJECT: coinnewsextratv-batch-02
apiKey: ...
authDomain: ...
...
```

---

### Step 4: Set Firestore Security Rules (For Each Project)

#### 4.1 Open Firestore Rules
1. Go to **Firestore Database**
2. Click **"Rules"** tab

#### 4.2 Update Rules
Replace default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Admin created accounts collection
    match /admin_created_accounts/{document=**} {
      allow read, write: if true; // Adjust for production security
    }
    
    // Users collection
    match /users/{userId} {
      allow read, write: if true; // Adjust for production security
    }
    
    // System stats
    match /system_stats/{document=**} {
      allow read, write: if true; // Adjust for production security
    }
  }
}
```

#### 4.3 Publish Rules
Click **"Publish"**

---

### Step 5: Configure Hedera Settings (For Each Project)

You can use the **same Hedera account** for all projects or create separate ones.

#### Option A: Shared Hedera Account (Easier)

Use your existing Hedera account for all 5 projects:

```bash
# For each project (01-05)
firebase functions:config:set \
  hedera.account_id="0.0.9764298" \
  hedera.private_key="YOUR_HEDERA_PRIVATE_KEY" \
  --project coinnewsextratv-batch-01

firebase functions:config:set \
  hedera.account_id="0.0.9764298" \
  hedera.private_key="YOUR_HEDERA_PRIVATE_KEY" \
  --project coinnewsextratv-batch-02

# ... repeat for batch-03, batch-04, batch-05
```

#### Option B: Separate Hedera Accounts (Better Isolation)

Create 5 Hedera accounts, one per project.

---

### Step 6: Add Projects to Firebase CLI

Add all projects to your local Firebase configuration:

```bash
# Add project 1
firebase use --add
# Select: coinnewsextratv-batch-01
# Alias: batch-01

# Add project 2
firebase use --add
# Select: coinnewsextratv-batch-02
# Alias: batch-02

# Add project 3
firebase use --add
# Select: coinnewsextratv-batch-03
# Alias: batch-03

# Add project 4
firebase use --add
# Select: coinnewsextratv-batch-04
# Alias: batch-04

# Add project 5
firebase use --add
# Select: coinnewsextratv-batch-05
# Alias: batch-05
```

Verify all projects:
```bash
firebase projects:list
```

---

### Step 7: Deploy to Each Project

#### Option A: Deploy All at Once (Automated)
```powershell
.\deploy-all-projects.ps1
```

#### Option B: Deploy One at a Time
```powershell
.\deploy-single-project.ps1 -ProjectNumber 1
.\deploy-single-project.ps1 -ProjectNumber 2
.\deploy-single-project.ps1 -ProjectNumber 3
.\deploy-single-project.ps1 -ProjectNumber 4
.\deploy-single-project.ps1 -ProjectNumber 5
```

#### Option C: Manual Deployment
```bash
firebase deploy --project coinnewsextratv-batch-01
firebase deploy --project coinnewsextratv-batch-02
firebase deploy --project coinnewsextratv-batch-03
firebase deploy --project coinnewsextratv-batch-04
firebase deploy --project coinnewsextratv-batch-05
```

---

### Step 8: Test Each Project

For each project, test the account creator:

1. **Open URL:**
   ```
   https://coinnewsextratv-batch-01.web.app/bulk-creator.html
   ```

2. **Create Test Batch:**
   - Enter: 10 accounts
   - Click "Create Accounts"
   - Wait for completion

3. **Verify in Firebase Console:**
   - Authentication → Should see 10 new users
   - Firestore → admin_created_accounts → Should see 10 documents
   - Check Hedera account IDs are valid

4. **Repeat for all 5 projects**

---

## ✅ Verification Checklist

After setup, verify each project:

### Project 1: coinnewsextratv-batch-01
- [ ] Firebase project created
- [ ] Authentication enabled (Email/Password)
- [ ] Firestore database created
- [ ] Firestore rules updated
- [ ] Cloud Functions enabled
- [ ] Hosting enabled
- [ ] Firebase config saved
- [ ] Hedera credentials configured
- [ ] Code deployed successfully
- [ ] Test batch (10 accounts) created
- [ ] bulk-creator.html accessible

### Project 2: coinnewsextratv-batch-02
- [ ] Same checklist as Project 1

### Project 3: coinnewsextratv-batch-03
- [ ] Same checklist as Project 1

### Project 4: coinnewsextratv-batch-04
- [ ] Same checklist as Project 1

### Project 5: coinnewsextratv-batch-05
- [ ] Same checklist as Project 1

---

## 📊 Expected Results

After completing setup:

| Project | Status | Test Accounts | URL Status |
|---------|--------|---------------|------------|
| batch-01 | ✅ Ready | 10 created | ✅ Live |
| batch-02 | ✅ Ready | 10 created | ✅ Live |
| batch-03 | ✅ Ready | 10 created | ✅ Live |
| batch-04 | ✅ Ready | 10 created | ✅ Live |
| batch-05 | ✅ Ready | 10 created | ✅ Live |

**Total Test Accounts:** 50  
**Total Capacity:** 50,000 accounts

---

## 🎯 Next Steps After Setup

1. **Create Production Schedule**
   - Plan daily account creation targets
   - Distribute load across projects

2. **Monitor Quotas**
   - Check Firebase usage daily
   - Ensure no project hits limits

3. **Begin Production Creation**
   - Start with 500-1,000 accounts/day per project
   - Gradually scale up

4. **Track Progress**
   - Use multi-project dashboard
   - Export account lists regularly

---

## 🔗 Quick Links

### Firebase Console Links
```
https://console.firebase.google.com/project/coinnewsextratv-batch-01
https://console.firebase.google.com/project/coinnewsextratv-batch-02
https://console.firebase.google.com/project/coinnewsextratv-batch-03
https://console.firebase.google.com/project/coinnewsextratv-batch-04
https://console.firebase.google.com/project/coinnewsextratv-batch-05
```

### Bulk Creator Links
```
https://coinnewsextratv-batch-01.web.app/bulk-creator.html
https://coinnewsextratv-batch-02.web.app/bulk-creator.html
https://coinnewsextratv-batch-03.web.app/bulk-creator.html
https://coinnewsextratv-batch-04.web.app/bulk-creator.html
https://coinnewsextratv-batch-05.web.app/bulk-creator.html
```

---

## 💡 Tips

1. **Save All Configs:** Keep firebase-configs.txt in a secure location
2. **Bookmark URLs:** Save all bulk-creator URLs for quick access
3. **Stagger Creation:** Don't create accounts in all projects simultaneously
4. **Monitor Daily:** Check quotas and errors every day
5. **Backup Regularly:** Export account lists weekly

---

## 🆘 Troubleshooting

### Issue: "Project already exists"
**Solution:** Choose a different project name or number

### Issue: "Deployment failed"
**Solution:** Check that you're logged into Firebase CLI with correct account:
```bash
firebase login --reauth
```

### Issue: "Permission denied"
**Solution:** Ensure you're the owner of all projects in Firebase Console

### Issue: "Quota exceeded"
**Solution:** Switch to a different project or wait 24 hours

---

**Setup Time Estimate:** 2-3 hours for all 5 projects  
**Difficulty:** Intermediate  
**Required Skills:** Firebase Console navigation, Basic CLI commands

**Good luck with your setup!** 🚀
