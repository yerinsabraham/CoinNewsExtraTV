# Admin Account Creator - Setup Guide

## 🎯 Feature Overview

The **Account Creator** is a powerful admin tool that allows you to bulk-create user accounts with automatic Hedera wallet creation. Each generated account includes:

- ✅ Firebase Authentication account
- ✅ Hedera blockchain wallet (with private key)
- ✅ Decentralized Identity (DID)
- ✅ Initial CNE balance (signup bonus)
- ✅ Secure credential storage in Firestore

## 📍 Access Points

### 1. Direct URL
```
https://coinnewsextratv-9c75a.web.app/admin/accounts
```

### 2. From Admin Dashboard
1. Navigate to: `/admin`
2. Click "🎯 Create Accounts" in Quick Actions section

## 🔑 Admin Access Setup

To access the Account Creator, you need admin privileges:

### Step 1: Set Admin Role in Firestore

1. Go to Firebase Console: https://console.firebase.google.com/project/coinnewsextratv-9c75a/firestore

2. Navigate to `users` collection

3. Find your user document (by your UID)

4. Add one of these fields:
   ```json
   {
     "role": "admin"
   }
   ```
   **OR**
   ```json
   {
     "isAdmin": true
   }
   ```

5. Save changes

6. Refresh the web app and navigate to `/admin/accounts`

## 🚀 How to Use

### Creating Accounts

1. **Generate Credentials**
   - Click "Generate Credentials" button
   - Random email (format: `cne_user_[timestamp]_[random]@gmail.com`)
   - Random strong password (12 characters with special chars)

2. **Create Account**
   - Review the generated credentials
   - Click "Create Account" button
   - Wait for confirmation (creates both Firebase Auth + Hedera wallet)

3. **Copy Credentials**
   - Email and password are displayed
   - Click copy icons to copy individual credentials
   - Full Hedera account ID is shown once created

### Viewing Created Accounts

The accounts table shows:
- Email address
- Password (hidden by default, click eye icon to reveal)
- Hedera Account ID
- CNE Balance
- Status (Active/Pending)
- Creation date

### Exporting Credentials

**CSV Export:**
- Click "Export CSV" button
- Downloads file: `admin_accounts_[timestamp].csv`
- Contains: Email, Password, Firebase UID, Hedera Account ID, DID, Balance, Created Date, Status

**TXT Export:**
- Click "Export TXT" button
- Downloads file: `admin_accounts_[timestamp].txt`
- Human-readable format with all credentials

## 📊 Statistics

The dashboard displays:
- **Admin Created Accounts**: Total accounts created via admin panel
- **Total Platform Users**: All registered users (normal signups + admin-created)

## 🔒 Security Notes

### Credential Storage
- ⚠️ **Passwords are stored in PLAIN TEXT** in Firestore as requested
- Collection: `admin_created_accounts`
- Each document contains: email, password, firebaseUid, hederaAccountId, did, cneBalance, createdAt, createdBy, status

### Access Control
- Only users with `role: "admin"` or `isAdmin: true` can access
- Non-admin users are redirected to home page
- Admin check happens on component mount

### Firestore Security Rules
Add these rules to protect the admin collection:

```javascript
match /admin_created_accounts/{accountId} {
  allow read, write: if request.auth != null && 
    (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' ||
     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true);
}
```

## 🔧 Technical Details

### Hedera Integration

The account creation process:

1. Creates Firebase Auth account with email/password
2. Calls Firebase Function `onboardUser` which:
   - Generates ED25519 keypair
   - Creates Hedera account on network (testnet/mainnet)
   - Stores account data in Firestore
   - Assigns DID (Decentralized Identity)
   - Credits initial CNE balance

3. Stores credentials in `admin_created_accounts` collection

### Firestore Collections

**Collection: `admin_created_accounts`**
```javascript
{
  email: string,              // e.g., "cne_user_1234567890_5678@gmail.com"
  password: string,           // Plain text password
  firebaseUid: string,        // Firebase Auth UID
  hederaAccountId: string,    // e.g., "0.0.12345678"
  did: string,                // e.g., "did:hedera:0.0.12345678"
  cneBalance: number,         // Initial balance (usually 100 or 700)
  createdAt: Timestamp,       // When account was created
  createdBy: string,          // Admin UID who created it
  status: string              // "active" | "pending_hedera"
}
```

**Collection: `system_stats`**
Document: `admin_accounts`
```javascript
{
  totalCreated: number,       // Total count of admin-created accounts
  lastUpdated: Timestamp      // Last update time
}
```

### Error Handling

If Hedera account creation fails:
- Firebase Auth account is still created
- Status is set to `pending_hedera`
- Error message is stored
- Account can be manually processed later

## 🧪 Testing

### Test Account Creation

1. Log in with admin account
2. Navigate to `/admin/accounts`
3. Generate credentials
4. Create account
5. Verify in Firebase Console:
   - Check `users` collection for new user
   - Check `admin_created_accounts` for credentials
   - Verify Hedera account ID is valid

### Verify Hedera Wallet

Use Hedera Explorer to verify account creation:
- **Testnet**: https://hashscan.io/testnet
- **Mainnet**: https://hashscan.io/mainnet

Search for the Hedera Account ID to see:
- Account balance
- Transaction history
- Associated tokens

## 📱 UI Features

### Account Generator Component
- Clean, modern interface
- One-click credential generation
- Copy-to-clipboard functionality
- Real-time feedback
- Last created account display

### Accounts Table Component
- Password visibility toggle
- Individual credential copying
- Sortable columns
- Status indicators
- Bulk export options

### Stats Cards
- Admin created count
- Total platform users
- Color-coded metrics
- Real-time updates

## 🐛 Troubleshooting

### Issue: "Access Denied"
**Solution**: Ensure your user document has `role: "admin"` or `isAdmin: true` in Firestore

### Issue: "Hedera wallet creation failed"
**Possible causes**:
- Firebase Function timeout
- Hedera network issues
- Insufficient operator balance
- Invalid Hedera credentials

**Check**:
- Firebase Functions logs
- Hedera operator account balance
- Environment variables (HEDERA_ACCOUNT_ID, HEDERA_PRIVATE_KEY)

### Issue: "Email already in use"
**Solution**: Generate new credentials (click "Generate Credentials" again)

### Issue: "Cannot read after logout"
**Solution**: The account creation process signs out the newly created user. You may need to log back in with your admin credentials.

## 🔄 Firebase Functions Required

Ensure these Firebase Functions are deployed:

### `onboardUser` Function
This function must be deployed and working:
```bash
firebase deploy --only functions:onboardUser
```

The function should:
- Create Hedera account
- Generate DID
- Set initial balance
- Store user data in Firestore

## 📈 Best Practices

1. **Regular Exports**: Export credentials regularly as backup
2. **Secure Storage**: Store exported files securely
3. **Monitor Stats**: Check account creation counts regularly
4. **Test Accounts**: Verify Hedera accounts are created successfully
5. **Access Control**: Limit admin access to trusted users only

## 🎯 Future Enhancements

Potential improvements:
- Email delivery of credentials
- Batch account creation (multiple at once)
- Custom email format configuration
- Password encryption option
- Account deletion/management
- Hedera account funding
- Token association automation

## 📞 Support

For issues or questions:
- Check Firebase Functions logs
- Review Firestore security rules
- Verify Hedera network status
- Check browser console for errors

---

**Live URL**: https://coinnewsextratv-9c75a.web.app/admin/accounts

**Admin Dashboard**: https://coinnewsextratv-9c75a.web.app/admin
