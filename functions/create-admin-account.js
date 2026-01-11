const functions = require('firebase-functions');
const admin = require('firebase-admin');

/**
 * Create Admin Accounts (Server-Side)
 * Creates Firebase Auth + Hedera accounts without signing out the admin
 */
exports.createAdminAccount = functions.https.onCall(async (data, context) => {
  // Verify admin authorization
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { email, password, adminUid } = data;

  if (!email || !password) {
    throw new functions.https.HttpsError('invalid-argument', 'Email and password required');
  }

  try {
    console.log(`Creating account for: ${email}`);

    // 1. Create Firebase Auth user (server-side, doesn't affect admin session)
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      emailVerified: false
    });

    console.log(`Firebase Auth user created: ${userRecord.uid}`);

    // 2. Call onboardUser to create Hedera wallet
    let hederaData = {
      hederaAccountId: null,
      did: null,
      initialBalance: 0
    };

    try {
      // Create user document first
      await admin.firestore().collection('users').doc(userRecord.uid).set({
        email: email,
        uid: userRecord.uid,
        displayName: email.split('@')[0],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        cneBalance: 0,
        totalEarned: 0,
        accountType: 'admin_created'
      });

      // Try to create Hedera account
      const onboardResult = await admin.functions().httpsCallable('onboardUser')({
        firebaseUid: userRecord.uid,
        publicKey: null
      });

      hederaData = {
        hederaAccountId: onboardResult.data.hederaAccountId || null,
        did: onboardResult.data.did || null,
        initialBalance: onboardResult.data.initialBalance || 0
      };

      console.log(`Hedera account created: ${hederaData.hederaAccountId}`);
    } catch (hederaError) {
      console.error('Hedera creation failed:', hederaError);
      // Continue without Hedera - we'll store with pending status
    }

    // 3. Store credentials in admin_created_accounts
    await admin.firestore().collection('admin_created_accounts').add({
      email: email,
      password: password, // Plain text as requested
      firebaseUid: userRecord.uid,
      hederaAccountId: hederaData.hederaAccountId,
      did: hederaData.did,
      cneBalance: hederaData.initialBalance,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: adminUid || context.auth.uid,
      status: hederaData.hederaAccountId ? 'active' : 'pending_hedera'
    });

    // 4. Update admin account count
    const statsRef = admin.firestore().collection('system_stats').doc('admin_accounts');
    await statsRef.set({
      totalCreated: admin.firestore.FieldValue.increment(1),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    console.log(`Account creation complete for: ${email}`);

    return {
      success: true,
      email: email,
      password: password,
      firebaseUid: userRecord.uid,
      hederaAccountId: hederaData.hederaAccountId,
      did: hederaData.did,
      message: hederaData.hederaAccountId 
        ? 'Account created successfully with Hedera wallet'
        : 'Account created but Hedera wallet pending'
    };

  } catch (error) {
    console.error('Error creating admin account:', error);
    
    // If it's an auth error, provide more detail
    if (error.code === 'auth/email-already-exists') {
      throw new functions.https.HttpsError('already-exists', 'Email already in use');
    }
    
    throw new functions.https.HttpsError('internal', error.message);
  }
});
