const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const cors = require("cors");

// Configure CORS to allow Authorization headers
const corsOptions = {
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
};

const corsMiddleware = cors(corsOptions);

// NUCLEAR AUTH BYPASS - Direct HTTP endpoint with proper CORS
exports.getBalanceHttp = onRequest(async (req, res) => {
  return new Promise((resolve, reject) => {
    corsMiddleware(req, res, async () => {
      console.log('🚀 HTTP Direct getBalance called');
      console.log('🚀 Method:', req.method);
      console.log('🚀 Headers authorization:', req.headers.authorization ? 'Authorization present' : 'No auth header');
      console.log('🚀 All headers:', Object.keys(req.headers));
      
      // Handle preflight OPTIONS request
      if (req.method === 'OPTIONS') {
        console.log('🚀 Handling CORS preflight');
        res.status(204).send('');
        resolve();
        return;
      }
      
      try {
        // Extract ID token from Authorization header
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
          console.error('❌ No Authorization header or invalid format');
          res.status(401).json({ error: 'No valid authorization header' });
          resolve();
          return;
        }
        
        const idToken = authHeader.substring(7); // Remove 'Bearer ' prefix
        console.log('🔍 ID Token length:', idToken.length);
        
        // Verify the ID token directly with Firebase Admin
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const uid = decodedToken.uid;
        console.log('✅ Token verified successfully! UID:', uid);
        
        // Get balance from Firestore
        const userDoc = await admin.firestore().collection('users').doc(uid).get();
        const userData = userDoc.data() || {};
        const balance = userData.cneBalance || 0;
        
        console.log('✅ Balance retrieved:', balance);
        res.status(200).json({
          success: true,
          balance: balance,
          uid: uid
        });
        resolve();
        
      } catch (error) {
        console.error('❌ Error in getBalanceHttp:', error);
        res.status(500).json({
          success: false,
          error: error.message
        });
        resolve();
      }
    });
  });
});

// NUCLEAR AUTH BYPASS - Direct HTTP claim endpoint with proper CORS  
exports.claimRewardHttp = onRequest(async (req, res) => {
  return new Promise((resolve, reject) => {
    corsMiddleware(req, res, async () => {
      console.log('🎯 HTTP Direct claimReward called');
      console.log('🎯 Method:', req.method);
      console.log('🎯 Headers authorization:', req.headers.authorization ? 'Authorization present' : 'No auth header');
      
      // Handle preflight OPTIONS request
      if (req.method === 'OPTIONS') {
        console.log('🎯 Handling CORS preflight');
        res.status(204).send('');
        resolve();
        return;
      }
      
      try {
        // Extract ID token from Authorization header
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
          console.error('❌ No Authorization header or invalid format');
          res.status(401).json({ error: 'No valid authorization header' });
          resolve();
          return;
        }
        
        const idToken = authHeader.substring(7);
        console.log('🔍 ID Token length:', idToken.length);
        
        // Verify the ID token directly with Firebase Admin
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const uid = decodedToken.uid;
        console.log('✅ Token verified successfully! UID:', uid);
        
        // Parse request body
        const { source = 'http_direct', amount = 10 } = req.body || {};
        console.log('🎯 Claim request - source:', source, 'amount:', amount);
        
        if (!amount || amount <= 0) {
          res.status(400).json({ error: 'Invalid amount' });
          resolve();
          return;
        }
        
        // Update balance in Firestore
        const userDocRef = admin.firestore().collection('users').doc(uid);
        
        await admin.firestore().runTransaction(async (transaction) => {
          const userDoc = await transaction.get(userDocRef);
          const userData = userDoc.data() || {};
          const currentBalance = userData.cneBalance || 0;
          const newBalance = currentBalance + amount;
          
          transaction.set(userDocRef, {
            ...userData,
            cneBalance: newBalance,
            lastRewardClaim: admin.firestore.FieldValue.serverTimestamp(),
            totalRewardsClaimed: (userData.totalRewardsClaimed || 0) + amount
          }, { merge: true });
          
          console.log('✅ Balance updated:', currentBalance, '->', newBalance);
        });
        
        res.status(200).json({
          success: true,
          message: 'Reward claimed successfully',
          amount: amount,
          uid: uid
        });
        resolve();
        
      } catch (error) {
        console.error('❌ Error in claimRewardHttp:', error);
        res.status(500).json({
          success: false,
          error: error.message
        });
        resolve();
      }
    });
  });
});
