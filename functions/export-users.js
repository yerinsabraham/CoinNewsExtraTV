const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const cors = require('cors')({origin: true});

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Export all Firebase Authentication users (CORS enabled)
 */
exports.exportUsers = functions
  .runWith({
    timeoutSeconds: 540,
    memory: '1GB'
  })
  .https.onCall(async (data, context) => {
    
    console.log('Starting user export...');
    
    const allUsers = [];
    
    try {
      // List all users (up to 1000 at a time)
      let nextPageToken;
      let totalFetched = 0;
      
      do {
        const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
        
        listUsersResult.users.forEach((userRecord) => {
          allUsers.push({
            uid: userRecord.uid,
            email: userRecord.email || '',
            displayName: userRecord.displayName || '',
            phoneNumber: userRecord.phoneNumber || '',
            photoURL: userRecord.photoURL || '',
            emailVerified: userRecord.emailVerified,
            disabled: userRecord.disabled,
            creationTime: userRecord.metadata.creationTime,
            lastSignInTime: userRecord.metadata.lastSignInTime || '',
            providerData: userRecord.providerData.map(p => p.providerId).join('; '),
          });
        });
        
        totalFetched += listUsersResult.users.length;
        nextPageToken = listUsersResult.pageToken;
        
        console.log(`Fetched ${totalFetched} users so far...`);
        
      } while (nextPageToken);
      
      console.log(`✅ Total users exported: ${allUsers.length}`);
      
      return {
        success: true,
        users: allUsers,
        count: allUsers.length
      };
      
    } catch (error) {
      console.error('Error exporting users:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });
