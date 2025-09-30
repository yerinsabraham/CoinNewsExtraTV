# 🧪 User Account Testing Plan

## Step 1: Create New Test Account
1. **Sign out** of current account in the app
2. **Create new account** with email like `testuser2025@gmail.com`
3. **Complete signup** process
4. **Verify** user document is auto-created (check logs)

## Step 2: Test Social Media Verification
1. Navigate to **Earning Page**
2. Check **Social Media section** loads without permission errors
3. Click on **Twitter/X verification**
4. **Submit verification proof** (test text)
5. Verify **status updates** correctly

## Step 3: Test Other Features
1. **Spin-to-Earn Game** - verify rewards work
2. **Quiz Challenge** - test balance deduction
3. **Video Watching** - check Firebase video loading
4. **Live Stream** - test countdown functionality
5. **Wallet Creation** - verify automatic Hedera wallet

## Step 4: Monitor Debug Logs
Watch for these success messages:
```
🔍 Getting verification status for platform: twitter, user: [USER_ID]
✅ Basic user document created for: [USER_ID]
✅ Social verification document created successfully
```

## Step 5: Check Firebase Console
1. Go to Firebase Console > Firestore
2. Navigate to `users/[NEW_USER_ID]`
3. Verify user document exists with proper fields
4. Check `social_verifications` subcollection is accessible

## Expected Results ✅
- ✅ No permission denied errors
- ✅ Social verification tiles load properly
- ✅ User can submit verification proofs
- ✅ All reward systems function correctly
- ✅ Automatic wallet creation works
- ✅ Backend functions respond properly

## If Issues Persist 🔧
1. Check Firebase Console logs
2. Verify Firestore rules deployment
3. Test Firebase Functions directly
4. Check user authentication status

---
**Test Date**: September 30, 2025
**Recommended**: Create fresh account for clean testing
