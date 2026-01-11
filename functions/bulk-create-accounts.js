const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Bulk Create Admin Accounts (Server-Side)
 * Creates multiple Firebase Auth + Hedera accounts efficiently
 * Avoids client-side rate limiting by using Firebase Admin SDK
 */
exports.bulkCreateAccounts = functions.https.onCall(
  {
    timeoutSeconds: 300, // 5 minutes for large batches
    memory: '512MiB', // More memory for better performance
    invoker: 'public' // Allow unauthenticated calls
  },
  async (data, context) => {
  // Allow unauthenticated calls from the standalone page
  // In production, you might want to add a secret key check

  console.log('bulkCreateAccounts called. Full data object keys:', Object.keys(data || {}));
  console.log('data.count value:', data.count, 'type:', typeof data.count);
  
  // Handle both direct count and nested count
  const countValue = data.count || data.data?.count || data;
  console.log('Extracted countValue:', countValue, 'type:', typeof countValue);
  
  const count = parseInt(countValue, 10);

  console.log('Parsed count:', count, 'isNaN:', isNaN(count));

  if (isNaN(count) || count < 1 || count > 100) {
    console.error('Invalid count validation failed. Count:', count, 'Raw:', data.count);
    throw new functions.https.HttpsError('invalid-argument', `Count must be between 1 and 100 (received: ${data.count}, parsed: ${count})`);
  }

  console.log('Validation passed, proceeding with count:', count);

  const results = {
    successful: [],
    failed: [],
    total: count
  };

  // Real human names for email generation
  const firstNames = [
    'john', 'fred', 'rachel', 'janet', 'nneka', 'tunde', 'ali', 'sarah', 'michael', 'david',
    'maria', 'james', 'linda', 'robert', 'patricia', 'amina', 'chidi', 'ada', 'emeka', 'fatima',
    'omar', 'zainab', 'yusuf', 'aisha', 'ibrahim', 'grace', 'peter', 'mary', 'paul', 'esther',
    'daniel', 'ruth', 'samuel', 'hannah', 'joshua', 'deborah', 'benjamin', 'rebecca', 'isaac', 'leah',
    'jacob', 'sophia', 'noah', 'olivia', 'lucas', 'emma', 'mason', 'ava', 'ethan', 'isabella'
  ];

  const lastNames = [
    'smith', 'johnson', 'williams', 'brown', 'jones', 'garcia', 'miller', 'davis', 'rodriguez', 'martinez',
    'hernandez', 'lopez', 'gonzalez', 'wilson', 'anderson', 'thomas', 'taylor', 'moore', 'jackson', 'martin',
    'lee', 'perez', 'thompson', 'white', 'harris', 'sanchez', 'clark', 'ramirez', 'lewis', 'robinson',
    'walker', 'young', 'allen', 'king', 'wright', 'scott', 'torres', 'nguyen', 'hill', 'flores',
    'green', 'adams', 'nelson', 'baker', 'hall', 'rivera', 'campbell', 'mitchell', 'carter', 'roberts'
  ];

  const emailProviders = [
    'gmail.com', 'yahoo.com', 'outlook.com', 'hotmail.com', 'icloud.com', 
    'protonmail.com', 'zoho.com', 'aol.com', 'mail.com', 'yandex.com'
  ];

  function generateRandomEmail() {
    const formats = [
      // Format 1: firstname.lastname@domain
      () => {
        const first = firstNames[Math.floor(Math.random() * firstNames.length)];
        const last = lastNames[Math.floor(Math.random() * lastNames.length)];
        const provider = emailProviders[Math.floor(Math.random() * emailProviders.length)];
        return `${first}.${last}@${provider}`;
      },
      // Format 2: firstname.lastname.number@domain
      () => {
        const first = firstNames[Math.floor(Math.random() * firstNames.length)];
        const last = lastNames[Math.floor(Math.random() * lastNames.length)];
        const num = Math.floor(Math.random() * 999) + 1;
        const provider = emailProviders[Math.floor(Math.random() * emailProviders.length)];
        return `${first}.${last}.${num}@${provider}`;
      },
      // Format 3: firstnamelastname.number@domain
      () => {
        const first = firstNames[Math.floor(Math.random() * firstNames.length)];
        const last = lastNames[Math.floor(Math.random() * lastNames.length)];
        const num = Math.floor(Math.random() * 9999) + 1;
        const provider = emailProviders[Math.floor(Math.random() * emailProviders.length)];
        return `${first}${last}${num}@${provider}`;
      },
      // Format 4: firstname_lastname@domain
      () => {
        const first = firstNames[Math.floor(Math.random() * firstNames.length)];
        const last = lastNames[Math.floor(Math.random() * lastNames.length)];
        const provider = emailProviders[Math.floor(Math.random() * emailProviders.length)];
        return `${first}_${last}@${provider}`;
      },
      // Format 5: firstname.number@domain
      () => {
        const first = firstNames[Math.floor(Math.random() * firstNames.length)];
        const num = Math.floor(Math.random() * 99999) + 1;
        const provider = emailProviders[Math.floor(Math.random() * emailProviders.length)];
        return `${first}.${num}@${provider}`;
      },
      // Format 6: firstname-lastname@domain
      () => {
        const first = firstNames[Math.floor(Math.random() * firstNames.length)];
        const last = lastNames[Math.floor(Math.random() * lastNames.length)];
        const provider = emailProviders[Math.floor(Math.random() * emailProviders.length)];
        return `${first}-${last}@${provider}`;
      },
      // Format 7: firstinitial.lastname.number@domain
      () => {
        const first = firstNames[Math.floor(Math.random() * firstNames.length)];
        const last = lastNames[Math.floor(Math.random() * lastNames.length)];
        const num = Math.floor(Math.random() * 999) + 1;
        const provider = emailProviders[Math.floor(Math.random() * emailProviders.length)];
        return `${first[0]}.${last}.${num}@${provider}`;
      },
      // Format 8: lastname.firstname@domain
      () => {
        const first = firstNames[Math.floor(Math.random() * firstNames.length)];
        const last = lastNames[Math.floor(Math.random() * lastNames.length)];
        const provider = emailProviders[Math.floor(Math.random() * emailProviders.length)];
        return `${last}.${first}@${provider}`;
      }
    ];

    const format = formats[Math.floor(Math.random() * formats.length)];
    return format();
  }

  function generateRandomPassword() {
    const length = 12;
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
    let password = '';
    
    password += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[Math.floor(Math.random() * 26)];
    password += 'abcdefghijklmnopqrstuvwxyz'[Math.floor(Math.random() * 26)];
    password += '0123456789'[Math.floor(Math.random() * 10)];
    password += '!@#$%^&*'[Math.floor(Math.random() * 8)];
    
    for (let i = password.length; i < length; i++) {
      password += charset[Math.floor(Math.random() * charset.length)];
    }
    
    return password.split('').sort(() => Math.random() - 0.5).join('');
  }

  console.log(`Starting bulk creation of ${count} accounts`);

  // Create accounts sequentially with small delay
  for (let i = 0; i < count; i++) {
    const email = generateRandomEmail();
    const password = generateRandomPassword();

    try {
      console.log(`Creating account ${i + 1}/${count}: ${email}`);

      // 1. Create Firebase Auth user (Admin SDK - no rate limit issues)
      const userRecord = await admin.auth().createUser({
        email: email,
        password: password,
        emailVerified: false
      });

      console.log(`✅ Firebase Auth user created: ${userRecord.uid}`);

      // 2. Create user document
      await admin.firestore().collection('users').doc(userRecord.uid).set({
        email: email,
        uid: userRecord.uid,
        displayName: email.split('@')[0],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        cneBalance: 0,
        totalEarned: 0,
        accountType: 'admin_created'
      });

      // 3. Hedera account will be created automatically by processSignup trigger
      // We just set it as pending for now
      let hederaAccountId = 'Pending';
      let did = null;
      
      console.log(`ℹ️  Hedera account will be created by background process for ${email}`);

      // 4. Store in admin_created_accounts
      await admin.firestore().collection('admin_created_accounts').add({
        email: email,
        password: password,
        firebaseUid: userRecord.uid,
        hederaAccountId: hederaAccountId,
        did: did,
        cneBalance: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: context.auth?.uid || 'bulk_creator',
        status: hederaAccountId !== 'Pending' ? 'active' : 'pending_hedera'
      });

      results.successful.push({
        email: email,
        password: password,
        firebaseUid: userRecord.uid,
        hederaAccountId: hederaAccountId,
        did: did
      });

      console.log(`✅ Account ${i + 1}/${count} completed: ${email}`);

      // Small delay to avoid overwhelming the system (250ms for faster batch creation)
      if (i < count - 1) {
        await new Promise(resolve => setTimeout(resolve, 250));
      }

    } catch (error) {
      console.error(`❌ Failed to create account ${i + 1}/${count}:`, error);
      
      results.failed.push({
        email: email,
        error: error.message
      });
    }
  }

  // Update system stats
  try {
    const statsDoc = await admin.firestore().collection('system_stats').doc('admin_accounts').get();
    const currentTotal = statsDoc.exists ? (statsDoc.data().totalCreated || 0) : 0;
    
    await admin.firestore().collection('system_stats').doc('admin_accounts').set({
      totalCreated: currentTotal + results.successful.length,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      lastBulkCreate: {
        count: count,
        successful: results.successful.length,
        failed: results.failed.length,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      }
    }, { merge: true });
  } catch (statsError) {
    console.error('Failed to update stats:', statsError);
  }

  console.log(`Bulk creation complete: ${results.successful.length} successful, ${results.failed.length} failed`);

  return results;
});
