# Admin System Deployment Checklist

## Pre-Deployment

- [ ] Review all code changes
- [ ] Verify admin email addresses are correct:
  - `cnesup@outlook.com` (Super Admin)
  - `cnefinance@outlook.com` (Finance Admin)  
  - `cneupdates@gmail.com` (Updates Admin)
- [ ] Confirm default password: `cneadmin1234`
- [ ] Back up current Firestore rules
- [ ] Back up current Cloud Functions

## Step 1: Create Admin Accounts

```bash
cd functions
node setup-admin-accounts.js
```

**Verify:**
- [ ] All 3 accounts created successfully
- [ ] Check Firebase Auth console shows 3 new users
- [ ] Check Firestore `admins` collection has 3 documents
- [ ] Each document has correct `role` field

## Step 2: Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

**Verify:**
- [ ] Deployment successful
- [ ] No rule syntax errors
- [ ] Test read access to admin_actions (should fail for regular users)

## Step 3: Deploy Cloud Functions

```bash
firebase deploy --only functions
```

**Functions to verify:**
- [ ] `sendTokensToUser` deployed
- [ ] Other admin functions updated
- [ ] Check deployment output for errors
- [ ] Note function URLs

## Step 4: Flutter App Build

```bash
flutter clean
flutter pub get
flutter analyze
```

**Fix any errors, then:**

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

**Verify:**
- [ ] No compilation errors
- [ ] APK/bundle generated successfully
- [ ] File size reasonable (check build output)

## Step 5: Testing

### Test Super Admin (cnesup@outlook.com)

- [ ] Can sign in successfully
- [ ] Sees full admin dashboard
- [ ] Can access user management
- [ ] Can access content management
- [ ] Can send tokens (test with small amount)
- [ ] Can view admin action logs
- [ ] Token transfer appears in admin_actions collection

### Test Finance Admin (cnefinance@outlook.com)

- [ ] Can sign in successfully
- [ ] Sees Finance Admin dashboard only
- [ ] Can send tokens
- [ ] Can view transaction history
- [ ] CANNOT access content management
- [ ] CANNOT access user management
- [ ] Transaction logged correctly

### Test Updates Admin (cneupdates@gmail.com)

- [ ] Can sign in successfully
- [ ] Sees Updates Admin dashboard only
- [ ] Can access spotlight management
- [ ] Can access content management
- [ ] CANNOT send tokens
- [ ] CANNOT access user management
- [ ] Content changes logged correctly

### Test Unauthorized Access

- [ ] Regular user sees "Access Denied" screen
- [ ] Shows correct list of authorized emails
- [ ] Cannot bypass restrictions
- [ ] Cannot access any admin functions

## Step 6: Security Verification

### Firestore Rules
- [ ] Regular users cannot read admin_actions
- [ ] Regular users cannot update admins collection
- [ ] Finance Admin cannot update spotlight_items
- [ ] Updates Admin cannot send tokens

### Cloud Functions
- [ ] sendTokensToUser rejects Updates Admin
- [ ] sendTokensToUser rejects unauthenticated requests
- [ ] Admin actions logged with correct role

### Frontend
- [ ] Role-based UI rendering works
- [ ] Permission checks function correctly
- [ ] Navigation restricted appropriately

## Step 7: Data Verification

### Firestore Collections

Check `admins` collection:
- [ ] 3 documents exist
- [ ] Each has correct role field
- [ ] Each has permissions array
- [ ] isActive is true for all

Check `admin_actions` collection after testing:
- [ ] Actions logged during testing appear
- [ ] Each log has adminRole field
- [ ] Timestamps are correct
- [ ] Details are complete

## Step 8: Password Security

⚠️ **CRITICAL - Do this immediately after testing:**

- [ ] Change Super Admin password
- [ ] Change Finance Admin password
- [ ] Change Updates Admin password
- [ ] Document new passwords securely (password manager)
- [ ] Inform authorized personnel

## Step 9: Production Deployment

### Firebase Console
- [ ] Verify all 3 accounts show in Authentication
- [ ] Check Firestore rules are active
- [ ] Verify Cloud Functions are live
- [ ] Check function logs for any errors

### App Distribution
- [ ] Upload APK/bundle to Google Play Console
- [ ] Update version number
- [ ] Add release notes mentioning admin system
- [ ] Submit for review

## Step 10: Post-Deployment Monitoring

### First 24 Hours
- [ ] Monitor admin_actions collection
- [ ] Check Cloud Function logs
- [ ] Watch for any permission errors
- [ ] Verify admin logins work
- [ ] Test token transfers in production

### First Week
- [ ] Review all admin action logs
- [ ] Confirm no unauthorized access attempts
- [ ] Verify all three roles functioning correctly
- [ ] Check for any reported issues

## Rollback Plan

If issues occur:

1. **Revert Firestore Rules:**
   ```bash
   firebase deploy --only firestore:rules
   # (use backup from pre-deployment)
   ```

2. **Revert Cloud Functions:**
   ```bash
   firebase deploy --only functions
   # (use previous version)
   ```

3. **Disable Admin Accounts:**
   ```javascript
   // In Firestore console
   admins/{uid}.isActive = false
   ```

4. **Revert App:**
   - Keep previous APK available
   - Can rollback in Play Console if needed

## Support Contacts

- **Technical Issues:** Check Firebase Console logs
- **Account Issues:** Super Admin (cnesup@outlook.com)
- **Function Errors:** Cloud Functions logs
- **Security Concerns:** Immediately disable affected accounts

## Documentation

- [ ] Update app README with admin system info
- [ ] Share ADMIN_SYSTEM_DOCUMENTATION.md with authorized personnel
- [ ] Document credential storage location
- [ ] Create admin onboarding guide

---

## Sign-Off

- [ ] Development complete
- [ ] All tests passed
- [ ] Security verified
- [ ] Documentation complete
- [ ] Passwords changed
- [ ] Production deployed
- [ ] Monitoring in place

**Deployment Date:** _________________

**Deployed By:** _________________

**Verified By:** _________________

**Notes:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
