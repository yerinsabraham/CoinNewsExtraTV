const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { Client, PrivateKey, AccountCreateTransaction, AccountId, Hbar } = require("@hashgraph/sdk");

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// ==================================================
// Agora RTC token generator (HTTPS)
// ==================================================
try {
  let RtcTokenBuilder, RtcRole;
  try {
    // Prefer the official agora-token package (newer, maintained)
    ({ RtcTokenBuilder, RtcRole } = require('agora-token'));
  } catch (innerErr) {
    console.warn('agora-token not available; falling back to local agora_token_builder');
    const localBuilder = require('./agora_token_builder');
    // Support different shapes exported by vendored builders
    if (localBuilder && localBuilder.RtcTokenBuilder && localBuilder.RtcRole) {
      RtcTokenBuilder = localBuilder.RtcTokenBuilder;
      RtcRole = localBuilder.RtcRole;
    } else if (localBuilder && localBuilder.RtcTokenBuilder) {
      RtcTokenBuilder = localBuilder.RtcTokenBuilder;
      RtcRole = localBuilder.RtcRole || { PUBLISHER: 1, SUBSCRIBER: 2 };
    } else {
      // legacy shape: module directly exports builder function
      RtcTokenBuilder = localBuilder;
      RtcRole = (localBuilder && localBuilder.RtcRole) || { PUBLISHER: 1, SUBSCRIBER: 2 };
    }
  }

  // Public endpoint to generate short-lived RTC tokens for a channel.
  // This endpoint verifies Firebase ID tokens (caller authentication) and
  // returns an Agora RTC token signed with the project's App Certificate.
  exports.generateAgoraToken = onRequest(async (req, res) => {
    try {
      // Allow simple health check
      if (req.method === 'GET' && req.query.health === '1') {
        return res.status(200).send({ ok: true, now: Date.now() });
      }

      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Only POST supported' });
      }

      // Basic request validation
      const body = req.body || {};
      const channel = body.channel;
      const reqUid = body.uid; // optional numeric uid
      const ttl = Number(body.ttl || 3600); // default 1 hour
      const role = (body.role === 'subscriber') ? RtcRole.SUBSCRIBER : RtcRole.PUBLISHER;

      if (!channel) return res.status(400).json({ error: 'channel is required' });

      // Verify Firebase ID token (Authorization: Bearer <idToken>)
      const authHeader = req.get('Authorization') || req.get('authorization') || '';
      if (!authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Missing Authorization Bearer token' });
      }
      const idToken = authHeader.split('Bearer ')[1];
      let decoded;
      try {
        decoded = await admin.auth().verifyIdToken(idToken);
      } catch (err) {
        console.error('Failed to verify ID token', err);
        return res.status(401).json({ error: 'Invalid ID token' });
      }

      // Read Agora credentials from functions config
      const agoraConfig = (process.env.FUNCTIONS_EMULATOR) ? functions.config().agora : functions.config().agora;
      const appId = agoraConfig?.app_id;
      const appCertificate = agoraConfig?.app_certificate;
      if (!appId || !appCertificate) {
        console.error('Agora config missing in functions config');
        return res.status(500).json({ error: 'Agora config not set. Run: firebase functions:config:set agora.app_id="..." agora.app_certificate="..."' });
      }

      const agoraUid = Number(reqUid || 0);
      const currentTs = Math.floor(Date.now() / 1000);
      const expireTs = currentTs + Math.max(30, Math.min(ttl, 86400));

      const token = RtcTokenBuilder.buildTokenWithUid(appId, appCertificate, channel, agoraUid, role, expireTs);

      return res.json({ token, appId, channel, uid: agoraUid, expiresAt: expireTs, requestedBy: decoded.uid });
    } catch (err) {
      console.error('generateAgoraToken error', err);
      return res.status(500).json({ error: String(err) });
    }
  });
  } catch (e) {
  // If module not installed yet, export a placeholder that returns a helpful error
  console.warn('agora-token not installed; generateAgoraToken will not be available until installed');
}

// Hedera configuration
const HEDERA_NETWORK = 'testnet';
const HEDERA_OPERATOR_ID = '0.0.4506257';
const HEDERA_OPERATOR_KEY = 'YOUR_HEDERA_PRIVATE_KEY_HERE'; // You'll need to set this

// processSignup function with Hedera wallet creation
exports.processSignup = onCall({
    cors: true
}, async (request) => {
    console.log('🎯 processSignup called with Hedera wallet creation');
    
    if (!request.auth || !request.auth.uid) {
        throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = request.auth.uid;
    const email = request.auth.token.email || '';
    
    try {
        console.log('Creating Hedera custodian wallet for user:', uid);
        
        // Create Hedera client
        const client = Client.forTestnet();
        client.setOperator(HEDERA_OPERATOR_ID, HEDERA_OPERATOR_KEY);
        
        // Generate new key pair for the user
        const userPrivateKey = PrivateKey.generateED25519();
        const userPublicKey = userPrivateKey.publicKey;
        
        console.log('Generated keypair for user');
        
        // Create new Hedera account (custodian wallet)
        const transaction = new AccountCreateTransaction()
            .setKey(userPublicKey)
            .setInitialBalance(new Hbar(0.1)) // Minimum required balance
            .setAccountMemo(`CNE-User-${uid.substring(0, 8)}`);
        
        const response = await transaction.execute(client);
        const receipt = await response.getReceipt(client);
        const newAccountId = receipt.accountId;
        
        console.log('Created Hedera account:', newAccountId.toString());
        
        // Prepare user data with Hedera wallet info
        const userData = {
            uid: uid,
            email: email,
            cneBalance: 700, // Signup bonus
            signupBonusProcessed: true,
            signupTimestamp: admin.firestore.FieldValue.serverTimestamp(),
            // Hedera wallet data (custodian - private key stored server-side)
            hederaWallet: {
                accountId: newAccountId.toString(),
                publicKey: userPublicKey.toString(),
                privateKey: userPrivateKey.toString(), // Stored securely server-side
                network: HEDERA_NETWORK,
                custodianWallet: true,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            }
        };

        // Save to Firestore
        await db.collection('users').doc(uid).set(userData, { merge: true });
        
        console.log('User data saved with Hedera wallet:', newAccountId.toString());

        return {
            success: true,
            cneBalance: 700,
            hederaAccountId: newAccountId.toString(),
            message: 'Signup completed with Hedera wallet created'
        };
        
    } catch (error) {
        console.error('Error creating Hedera wallet:', error);
        
        // Fallback: Create user without Hedera wallet but still give bonus
        const fallbackData = {
            uid: uid,
            email: email,
            cneBalance: 700,
            signupBonusProcessed: true,
            signupTimestamp: admin.firestore.FieldValue.serverTimestamp(),
            hederaWalletCreationFailed: true,
            hederaWalletError: error.message
        };

        await db.collection('users').doc(uid).set(fallbackData, { merge: true });

        return {
            success: true,
            cneBalance: 700,
            hederaAccountId: null,
            message: 'Signup completed (Hedera wallet creation failed but user created)',
            error: error.message
        };
    }
});

// Import bypass functions
const bypass = require('./bypass');
exports.getBalanceHttp = bypass.getBalanceHttp;
exports.claimRewardHttp = bypass.claimRewardHttp;
exports.processSignupHttp = bypass.processSignupHttp;

// ================================
// PUSH NOTIFICATION FUNCTIONS
// ================================

/**
 * Cloud Function to send push notifications when announcements are created
 * Triggers when a document is created in the 'admin_notifications' collection
 */
exports.sendAnnouncementPushNotification = onDocumentCreated('admin_notifications/{notificationId}', async (event) => {
  const snap = event.data;
  try {
      const notificationData = snap.data();
      
      // Check if push notification should be sent
      if (!notificationData.sendPush) {
        console.log('Push notification not requested for notification:', event.params.notificationId);
        return null;
      }

      console.log('Processing push notification for announcement:', notificationData.title);

      // Get all users with FCM tokens
      const usersSnapshot = await admin.firestore()
        .collection('users')
        .where('fcmToken', '!=', null)
        .get();

      if (usersSnapshot.empty) {
        console.log('No users with FCM tokens found');
        return null;
      }

      const tokens = [];
      const tokenUserMap = new Map();

      usersSnapshot.forEach(doc => {
        const userData = doc.data();
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
          tokenUserMap.set(userData.fcmToken, doc.id);
        }
      });

      if (tokens.length === 0) {
        console.log('No valid FCM tokens found');
        return null;
      }

      // Prepare notification payload
      const payload = {
        notification: {
          title: notificationData.title || 'CoinNewsExtra Announcement',
          body: notificationData.message || 'New announcement available',
          icon: '/assets/icons/app_icon_white_bg.png',
          badge: '/assets/icons/app_icon_white_bg.png'
        },
        data: {
          type: 'announcement',
          notificationId: event.params.notificationId,
          priority: notificationData.priority || 'normal',
          createdAt: notificationData.createdAt?.toMillis?.()?.toString() || Date.now().toString(),
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        },
        android: {
          notification: {
            channelId: 'coinnewsextra_notifications',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
            icon: 'ic_launcher'
          }
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default'
            }
          }
        }
      };

      // Send notifications in batches (FCM limit is 500 tokens per batch)
      const batchSize = 500;
      const batches = [];
      
      for (let i = 0; i < tokens.length; i += batchSize) {
        const batchTokens = tokens.slice(i, i + batchSize);
        batches.push(batchTokens);
      }

      let totalSuccessful = 0;
      let totalFailed = 0;
      const failedTokens = [];

      // Process each batch
      for (const batchTokens of batches) {
        try {
          const response = await admin.messaging().sendMulticast({
            tokens: batchTokens,
            ...payload
          });

          totalSuccessful += response.successCount;
          totalFailed += response.failureCount;

          // Collect failed tokens for cleanup
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              const failedToken = batchTokens[idx];
              const error = resp.error;
              
              console.error(`Failed to send to token ${failedToken}:`, error?.code);
              
              // If token is invalid, mark for removal
              if (error?.code === 'messaging/registration-token-not-registered' ||
                  error?.code === 'messaging/invalid-registration-token') {
                failedTokens.push(failedToken);
              }
            }
          });

          console.log(`Batch processed: ${response.successCount} successful, ${response.failureCount} failed`);
        } catch (error) {
          console.error('Error sending batch:', error);
          totalFailed += batchTokens.length;
        }
      }

      // Clean up invalid tokens
      if (failedTokens.length > 0) {
        console.log(`Cleaning up ${failedTokens.length} invalid tokens`);
        await cleanupInvalidTokens(failedTokens, tokenUserMap);
      }

      // Update notification document with delivery stats
      await snap.ref.update({
        pushNotificationSent: true,
        deliveryStats: {
          totalTokens: tokens.length,
          successful: totalSuccessful,
          failed: totalFailed,
          sentAt: admin.firestore.FieldValue.serverTimestamp()
        }
      });

      console.log(`Push notification sent successfully: ${totalSuccessful} delivered, ${totalFailed} failed`);
      return { success: true, delivered: totalSuccessful, failed: totalFailed };

    } catch (error) {
      console.error('Error sending push notification:', error);
      
      // Update notification document with error
      await snap.ref.update({
        pushNotificationSent: false,
        pushNotificationError: error.message,
        errorAt: admin.firestore.FieldValue.serverTimestamp()
      });

      throw error;
    }
});

/**
 * Clean up invalid FCM tokens from user documents
 */
async function cleanupInvalidTokens(invalidTokens, tokenUserMap) {
  const batch = admin.firestore().batch();

  invalidTokens.forEach(token => {
    const userId = tokenUserMap.get(token);
    if (userId) {
      const userRef = admin.firestore().collection('users').doc(userId);
      batch.update(userRef, {
        fcmToken: admin.firestore.FieldValue.delete(),
        tokenRemovedAt: admin.firestore.FieldValue.serverTimestamp(),
        tokenRemovalReason: 'invalid_token'
      });
    }
  });

  try {
    await batch.commit();
    console.log(`Cleaned up ${invalidTokens.length} invalid tokens`);
  } catch (error) {
    console.error('Error cleaning up invalid tokens:', error);
  }
}

/**
 * Callable function to send custom push notifications
 * Can be called from admin panel for immediate notifications
 */
exports.sendCustomPushNotification = onCall({
  cors: true
}, async (request) => {
  // Verify admin authentication
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  // Check if user is admin
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(request.auth.uid)
    .get();

  const userData = userDoc.data();
  if (!userData?.isAdmin && !userData?.isSuperAdmin) {
    throw new HttpsError('permission-denied', 'User must be admin');
  }

  try {
    const { title, message, targetUsers, priority = 'normal' } = request.data;

    if (!title || !message) {
      throw new HttpsError('invalid-argument', 'Title and message are required');
    }

    // Get target user tokens
    let tokensQuery = admin.firestore().collection('users').where('fcmToken', '!=', null);
    
    // If specific users targeted, filter by user IDs
    if (targetUsers && targetUsers.length > 0) {
      tokensQuery = tokensQuery.where(admin.firestore.FieldPath.documentId(), 'in', targetUsers);
    }

    const usersSnapshot = await tokensQuery.get();
    const tokens = usersSnapshot.docs
      .map(doc => doc.data().fcmToken)
      .filter(token => token);

    if (tokens.length === 0) {
      return { success: false, message: 'No valid FCM tokens found for target users' };
    }

    // Prepare notification payload
    const payload = {
      notification: {
        title: title,
        body: message,
        icon: '/assets/icons/app_icon_white_bg.png'
      },
      data: {
        type: 'custom',
        priority: priority,
        createdAt: Date.now().toString(),
        sentBy: request.auth.uid,
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      }
    };

    // Send notification
    const response = await admin.messaging().sendMulticast({
      tokens: tokens,
      ...payload
    });

    return {
      success: true,
      delivered: response.successCount,
      failed: response.failureCount,
      totalTokens: tokens.length
    };

  } catch (error) {
    console.error('Error sending custom push notification:', error);
    throw new HttpsError('internal', 'Failed to send push notification');
  }
});

/**
 * Function to handle user token updates
 * Ensures tokens are properly managed
 */
exports.updateUserToken = onCall({
  cors: true
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  try {
    const { fcmToken, platform } = request.data;

    if (!fcmToken) {
      throw new HttpsError('invalid-argument', 'FCM token is required');
    }

    // Update user document with new token
    await admin.firestore()
      .collection('users')
      .doc(request.auth.uid)
      .update({
        fcmToken: fcmToken,
        platform: platform || 'unknown',
        tokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

    return { success: true, message: 'Token updated successfully' };

  } catch (error) {
    console.error('Error updating user token:', error);
    throw new HttpsError('internal', 'Failed to update token');
  }
});

// Export the askOpenAI function implementation
try {
  exports.askOpenAI = require('./ask_openai').askOpenAI;
} catch (e) {
  console.warn('ask_openai not available to export:', e.message);
}

