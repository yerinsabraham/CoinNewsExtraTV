# Manual Admin Account Setup

Since the automated script requires Firebase Admin SDK credentials, follow these steps to create admin accounts manually:

## Step 1: Create Accounts in Firebase Console

### 1. Go to Firebase Console
- Open: https://console.firebase.google.com
- Select your CoinNewsExtraTV project

### 2. Create Super Admin Account
1. Go to **Authentication** > **Users** > **Add user**
2. Email: `cnesup@outlook.com`
3. Password: `cneadmin1234`
4. Click **Add user**
5. Copy the **UID** (you'll need this)

### 3. Create Finance Admin Account
1. Click **Add user** again
2. Email: `cnefinance@outlook.com`
3. Password: `cneadmin1234`
4. Click **Add user**
5. Copy the **UID**

### 4. Create Updates Admin Account
1. Click **Add user** again
2. Email: `cneupdates@gmail.com`
3. Password: `cneadmin1234`
4. Click **Add user**
5. Copy the **UID**

## Step 2: Create Firestore Admin Documents

### 1. Go to Firestore Database
- Click **Firestore Database** in left sidebar
- Navigate to or create **admins** collection

### 2. Add Super Admin Document
1. Click **Add document**
2. Document ID: `[Paste Super Admin UID]`
3. Add fields:

```
role: string = "super_admin"
email: string = "cnesup@outlook.com"
displayName: string = "Super Administrator"
permissions: array = [
  "manage_admins",
  "manage_finance",
  "send_tokens",
  "view_transaction_logs",
  "manage_content",
  "upload_videos",
  "manage_programs",
  "manage_schedules",
  "manage_spotlight",
  "manage_quiz",
  "moderate_comments",
  "manage_news",
  "update_homepage",
  "system_settings",
  "user_management",
  "support_management"
]
isActive: boolean = true
createdAt: timestamp = [Click "Set to current time"]
lastLogin: timestamp = [Click "Set to current time"]
```

4. Click **Save**

### 3. Add Finance Admin Document
1. Click **Add document**
2. Document ID: `[Paste Finance Admin UID]`
3. Add fields:

```
role: string = "finance_admin"
email: string = "cnefinance@outlook.com"
displayName: string = "Finance Administrator"
permissions: array = [
  "manage_finance",
  "send_tokens",
  "view_transaction_logs"
]
isActive: boolean = true
createdAt: timestamp = [Click "Set to current time"]
lastLogin: timestamp = [Click "Set to current time"]
```

4. Click **Save**

### 4. Add Updates Admin Document
1. Click **Add document**
2. Document ID: `[Paste Updates Admin UID]`
3. Add fields:

```
role: string = "updates_admin"
email: string = "cneupdates@gmail.com"
displayName: string = "Updates Administrator"
permissions: array = [
  "manage_content",
  "upload_videos",
  "manage_programs",
  "manage_schedules",
  "manage_spotlight",
  "manage_quiz",
  "moderate_comments",
  "manage_news",
  "update_homepage"
]
isActive: boolean = true
createdAt: timestamp = [Click "Set to current time"]
lastLogin: timestamp = [Click "Set to current time"]
```

4. Click **Save**

## Step 3: Verify Setup

### Check Authentication
- All 3 accounts should appear in **Authentication** > **Users**
- Each should have email verified (optional, can enable manually)

### Check Firestore
- **admins** collection should have 3 documents
- Each document ID should match the UID from Authentication
- All fields should be populated correctly

## Step 4: Record Credentials

**Super Admin:**
- Email: cnesup@outlook.com
- Password: cneadmin1234
- UID: `____________` (fill in)

**Finance Admin:**
- Email: cnefinance@outlook.com
- Password: cneadmin1234
- UID: `____________` (fill in)

**Updates Admin:**
- Email: cneupdates@gmail.com
- Password: cneadmin1234
- UID: `____________` (fill in)

## ⚠️ Security Reminder

**Change these passwords immediately after first login!**

Default password `cneadmin1234` is only for initial setup.

---

## Alternative: Use Firebase CLI

If you prefer command line:

```bash
# Install Firebase CLI if needed
npm install -g firebase-tools

# Login
firebase login

# Create users (requires proper permissions)
firebase auth:import users.json --project your-project-id
```

Create `users.json`:
```json
{
  "users": [
    {
      "uid": "auto",
      "email": "cnesup@outlook.com",
      "passwordHash": "cneadmin1234",
      "emailVerified": true,
      "disabled": false
    },
    {
      "uid": "auto",
      "email": "cnefinance@outlook.com",
      "passwordHash": "cneadmin1234",
      "emailVerified": true,
      "disabled": false
    },
    {
      "uid": "auto",
      "email": "cneupdates@gmail.com",
      "passwordHash": "cneadmin1234",
      "emailVerified": true,
      "disabled": false
    }
  ]
}
```

Note: You'll still need to create Firestore documents manually.
