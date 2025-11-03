# Multi-Level Admin Access System - CoinNewsExtraTV

## Overview

A comprehensive three-tier role-based admin system with granular permissions and secure access control for the CoinNewsExtraTV mobile application.

---

## Admin Roles

### 1. Super Admin
**Email:** `cnesup@outlook.com`  
**Default Password:** `cneadmin1234`  
**Badge Color:** Green (#006833)

**Full Access Includes:**
- ✅ All Finance Admin capabilities
- ✅ All Updates Admin capabilities
- ✅ Admin user management (create, disable, modify roles)
- ✅ System settings and configuration
- ✅ User management
- ✅ Support ticket management
- ✅ View all admin action logs
- ✅ Access to full comprehensive dashboard

### 2. Finance Admin
**Email:** `cnefinance@outlook.com`  
**Default Password:** `cneadmin1234`  
**Badge Color:** Orange

**Limited Access:**
- ✅ Send CNE tokens to users
- ✅ View transaction history
- ✅ View token transfer logs
- ✅ View own admin action history
- ❌ NO content management
- ❌ NO user management
- ❌ NO admin management
- ❌ NO system settings

**Dashboard Features:**
- Send CNE Tokens form (user email + amount + reason)
- Recent transaction history
- Personal action log

### 3. Updates Admin
**Email:** `cneupdates@gmail.com`  
**Default Password:** `cneadmin1234`  
**Badge Color:** Blue

**Content Management Access:**
- ✅ Upload and manage videos (live and recorded)
- ✅ Update program schedules
- ✅ Manage spotlight content
- ✅ Edit quiz questions
- ✅ Update news and events
- ✅ Moderate user comments
- ✅ Update homepage content
- ✅ Manage live stream links
- ❌ NO token/finance operations
- ❌ NO user management
- ❌ NO admin management

**Dashboard Features:**
- Video management
- Spotlight management
- Program scheduling
- Quiz editor
- News management
- Comment moderation

---

## Security Implementation

### Frontend (Flutter)

#### Files Created/Modified:
1. **`lib/models/admin_role.dart`**
   - AdminRole enum (superAdmin, financeAdmin, updatesAdmin)
   - AdminUser model
   - AdminPermissions class with 16 permission checks
   - Role-to-permission mappings

2. **`lib/services/admin_auth_service.dart`**
   - Role-based authentication
   - Email verification against authorized list
   - Firestore admin document management
   - Admin action logging
   - Permission checking utilities

3. **`lib/provider/admin_provider.dart`** (Updated)
   - Added AdminRole field
   - Added AdminUser field
   - Role-based status checking
   - Permission helper methods

4. **`lib/admin/screens/role_based_admin_dashboard.dart`** (New)
   - Smart routing based on admin role
   - Unauthorized access screen
   - Loading state handling

5. **`lib/admin/screens/finance_admin_screen.dart`** (New)
   - Send CNE Tokens interface
   - Transaction history view
   - Form validation
   - Cloud Function integration

6. **`lib/admin/screens/updates_admin_screen.dart`** (New)
   - Content management grid
   - Moderation tools access
   - Navigation to existing content screens

7. **`lib/screens/profile_screen.dart`** (Updated)
   - Now uses RoleBasedAdminDashboard instead of direct AdminDashboardScreen

### Backend (Cloud Functions)

#### New Cloud Function:
**`sendTokensToUser`** (Added to both index-full.js and index_complex.js)

**Endpoint:** `https://us-central1-coinnewsextratv-9c75a.cloudfunctions.net/sendTokensToUser`

**Access:** Super Admin and Finance Admin only

**Parameters:**
```javascript
{
  userEmail: string,  // Target user's email
  amount: number,     // CNE amount to send (positive number)
  reason: string      // Optional transfer reason
}
```

**Response:**
```javascript
{
  success: true,
  message: "Successfully sent X CNE to user@email.com",
  userId: "user_uid",
  newBalance: 1234.56
}
```

**Security:**
- Checks admin authentication
- Verifies admin role (super_admin or finance_admin only)
- Validates input parameters
- Finds user by email
- Updates user balance
- Logs transaction in rewards_log
- Logs admin action with full audit trail

#### Updated Functions:
All existing admin functions now check for role in admin document:
- `configureRewardRates`
- `toggleRewardType`
- `bulkAirdrop`
- `getSystemOverview`
- `getSystemHealth`
- etc.

### Database (Firestore)

#### Admin Document Structure:
```javascript
admins/{uid}
{
  email: "cnesup@outlook.com",
  role: "super_admin",  // or "finance_admin" or "updates_admin"
  displayName: "Super Admin",
  description: "Full system access",
  isActive: true,
  permissions: [
    "manage_admins",
    "send_tokens",
    "manage_content",
    // ... 16 total permissions
  ],
  createdAt: Timestamp,
  lastLogin: Timestamp,
  createdBy: "system_setup"
}
```

#### Admin Actions Log:
```javascript
admin_actions/{action_id}
{
  adminUid: "uid",
  adminEmail: "admin@example.com",
  adminRole: "finance_admin",
  action: "send_tokens",
  details: {
    userEmail: "user@example.com",
    userId: "user_uid",
    amount: 100,
    reason: "Promotional bonus"
  },
  timestamp: Timestamp
}
```

### Firestore Security Rules (Updated)

```javascript
// Admins collection
match /admins/{adminId} { 
  allow read: if request.auth != null;
  allow create: if request.auth != null && request.auth.uid == adminId;
  allow update: if request.auth.email in [
    'yerinssaibs@gmail.com',
    'elitepr@coinnewsextra.com',
    'cnesup@outlook.com'
  ];
}

// Admin actions - readable by authorized admins only
match /admin_actions/{id} { 
  allow read: if request.auth.email in [
    'cnesup@outlook.com',
    'cnefinance@outlook.com',
    'cneupdates@gmail.com',
    // ... legacy admins
  ];
  allow write: if false; // Cloud Functions only
}

// Spotlight management
match /spotlight_items/{itemId} {
  allow create, update, delete: if request.auth.email in [
    'cnesup@outlook.com',
    'cneupdates@gmail.com',
    // ... legacy admins
  ];
}

// Support (Super Admin only)
match /support_tickets/{ticketId} {
  allow list: if request.auth.email in [
    'cnesup@outlook.com',
    // ... legacy admins
  ];
}
```

---

## Setup Instructions

### 1. Create Admin Accounts

Run the setup script:
```bash
cd functions
node setup-admin-accounts.js
```

This will:
- Create 3 Firebase Auth users
- Set up Firestore admin documents
- Assign roles and permissions
- Display account credentials

### 2. Deploy Cloud Functions

```bash
firebase deploy --only functions
```

Updated functions:
- `sendTokensToUser` (NEW)
- All existing admin functions (updated with role checking)

### 3. Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

### 4. Build and Deploy Flutter App

```bash
flutter clean
flutter pub get
flutter build apk --release
# or
flutter build appbundle --release
```

---

## Testing Checklist

### Super Admin (`cnesup@outlook.com`)
- [ ] Can access full admin dashboard
- [ ] Can send CNE tokens
- [ ] Can manage spotlight content
- [ ] Can manage videos
- [ ] Can view all admin actions
- [ ] Can access user management
- [ ] Can access support tickets
- [ ] Can access system settings

### Finance Admin (`cnefinance@outlook.com`)
- [ ] Can access Finance Admin dashboard only
- [ ] Can send CNE tokens to users
- [ ] Can view transaction history
- [ ] Can view own admin actions
- [ ] CANNOT access content management
- [ ] CANNOT access user management
- [ ] CANNOT access system settings
- [ ] CANNOT manage admins

### Updates Admin (`cneupdates@gmail.com`)
- [ ] Can access Updates Admin dashboard only
- [ ] Can manage spotlight content
- [ ] Can manage videos
- [ ] Can manage programs
- [ ] Can manage quiz questions
- [ ] Can moderate comments
- [ ] CANNOT send tokens
- [ ] CANNOT view transaction logs
- [ ] CANNOT access user management
- [ ] CANNOT manage admins

### Unauthorized User
- [ ] Regular users see "Access Denied" screen
- [ ] Shows list of authorized admin emails
- [ ] Cannot bypass role restrictions

---

## Permission Matrix

| Feature | Super Admin | Finance Admin | Updates Admin |
|---------|------------|---------------|---------------|
| Send CNE Tokens | ✅ | ✅ | ❌ |
| View Transaction Logs | ✅ | ✅ | ❌ |
| Manage Videos | ✅ | ❌ | ✅ |
| Manage Spotlight | ✅ | ❌ | ✅ |
| Manage Programs | ✅ | ❌ | ✅ |
| Manage Quiz | ✅ | ❌ | ✅ |
| Moderate Comments | ✅ | ❌ | ✅ |
| Manage News | ✅ | ❌ | ✅ |
| User Management | ✅ | ❌ | ❌ |
| Admin Management | ✅ | ❌ | ❌ |
| System Settings | ✅ | ❌ | ❌ |
| Support Tickets | ✅ | ❌ | ❌ |

---

## API Endpoints

### Send Tokens to User
**Function:** `sendTokensToUser`  
**Method:** POST (Cloud Function)  
**Auth:** Firebase Auth required  
**Role:** Super Admin or Finance Admin

**Request:**
```json
{
  "userEmail": "user@example.com",
  "amount": 100.50,
  "reason": "Promotional bonus"
}
```

**Success Response:**
```json
{
  "success": true,
  "message": "Successfully sent 100.50 CNE to user@example.com",
  "userId": "abc123",
  "newBalance": 1234.56
}
```

**Error Response:**
```json
{
  "error": "Unauthorized - Finance Admin or Super Admin access required"
}
```

---

## Security Best Practices

### 1. Password Management
- ⚠️ **CRITICAL:** Change default password `cneadmin1234` immediately
- Use strong, unique passwords for each admin
- Enable 2FA when available
- Store credentials in secure password manager

### 2. Access Control
- Only share credentials with authorized personnel
- Revoke access immediately when personnel leave
- Regularly audit admin action logs
- Monitor unusual activity patterns

### 3. Audit Trail
- All admin actions are logged to `admin_actions` collection
- Review logs regularly for suspicious activity
- Each log includes: admin email, role, action, timestamp, details

### 4. Role Principle
- Use least privilege principle
- Finance staff should use Finance Admin account
- Content staff should use Updates Admin account
- Only key personnel should have Super Admin access

---

## Troubleshooting

### Admin Cannot Login
1. Verify email is exactly: `cnesup@outlook.com`, `cnefinance@outlook.com`, or `cneupdates@gmail.com`
2. Check Firebase Auth console for account existence
3. Verify password is correct
4. Check Firestore `admins/{uid}` document exists

### "Unauthorized Access" Error
1. Confirm admin account exists in Firebase Auth
2. Check admin document in Firestore has correct `role` field
3. Verify `isActive` is `true`
4. Check Firestore rules are deployed

### Send Tokens Not Working
1. Verify admin role is `super_admin` or `finance_admin`
2. Check Cloud Function `sendTokensToUser` is deployed
3. Verify user email exists in users collection
4. Check Cloud Function logs for errors

### Content Management Not Accessible
1. Verify admin role is `super_admin` or `updates_admin`
2. Check Firestore rules allow spotlight/content access
3. Verify `permissions` array includes required permissions

---

## Maintenance

### Adding New Admin
Currently requires manual setup (Super Admin feature coming soon):
1. Create Firebase Auth account
2. Create admin document in Firestore
3. Set appropriate role and permissions
4. Document credentials securely

### Disabling Admin
```javascript
// In Firestore console or via Cloud Function
admins/{uid}.update({
  isActive: false
})
```

### Viewing Admin Actions
```javascript
// Query Firestore
admin_actions
  .where('adminEmail', '==', 'admin@example.com')
  .orderBy('timestamp', 'desc')
  .limit(50)
```

---

## Files Modified/Created

### Flutter (lib/)
- `models/admin_role.dart` (NEW)
- `services/admin_auth_service.dart` (NEW)
- `provider/admin_provider.dart` (UPDATED)
- `admin/screens/role_based_admin_dashboard.dart` (NEW)
- `admin/screens/finance_admin_screen.dart` (NEW)
- `admin/screens/updates_admin_screen.dart` (NEW)
- `screens/profile_screen.dart` (UPDATED)

### Cloud Functions (functions/)
- `index-full.js` (UPDATED - added sendTokensToUser)
- `index_complex.js` (UPDATED - added sendTokensToUser)
- `setup-admin-accounts.js` (NEW)

### Configuration
- `firestore.rules` (UPDATED - role-based permissions)

---

## Support

For issues or questions:
1. Check admin action logs in Firestore
2. Review Cloud Function logs in Firebase Console
3. Verify all deployment steps completed
4. Check Flutter analyze output for compilation errors

---

**Last Updated:** November 3, 2025  
**System Version:** CoinNewsExtraTV v2.0 - Multi-Level Admin System  
**Status:** Ready for Testing and Deployment
