// Admin deletion with explicit project configuration
const admin = require('firebase-admin');

async function deleteUserWithProjectConfig() {
  try {
    console.log('🔐 FIREBASE ADMIN USER DELETION');
    console.log('==============================');
    
    // Initialize with explicit project configuration
    console.log('🔧 Initializing Firebase Admin with project config...');
    
    if (!admin.apps.length) {
      admin.initializeApp({
        projectId: 'coinnewsextratv-9c75a'
      });
    }
    
    console.log('✅ Firebase Admin initialized for project: coinnewsextratv-9c75a');
    
    const email = 'yerinsmgmt@gmail.com';
    const reason = 'Account cleanup - user requested deletion after account mixing issues';
    
    console.log(`📧 Target email: ${email}`);
    console.log(`📝 Reason: ${reason}`);
    console.log('');

    // Step 1: Find user by email
    console.log('🔍 Looking up user by email...');
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
      console.log(`✅ Found user: ${userRecord.uid}`);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        console.log(`❌ No user found with email: ${email}`);
        console.log('This could mean:');
        console.log('  - The user was already deleted');
        console.log('  - The email address is incorrect');
        console.log('  - The user never signed up');
        return { success: false, message: 'User not found' };
      }
      console.error('❌ Auth error:', error.message);
      throw error;
    }

    const userId = userRecord.uid;
    console.log(`👤 User ID: ${userId}`);
    console.log(`📧 Email: ${userRecord.email}`);
    console.log(`📅 Created: ${userRecord.metadata.creationTime}`);
    console.log(`📅 Last Sign In: ${userRecord.metadata.lastSignInTime || 'Never'}`);
    console.log('');

    // Step 2: Collect user data before deletion
    console.log('📊 Collecting user data from Firestore...');
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.exists ? userDoc.data() : null;
    
    if (userData) {
      console.log('📄 User document found:');
      console.log(`  💰 Points Balance: ${userData.points_balance || 0}`);
      console.log(`  💳 Available Balance: ${userData.available_balance || 0}`);
      console.log(`  🔒 Locked Balance: ${userData.locked_balance || 0}`);
      console.log(`  📈 Total Earned: ${userData.total_earned || 0}`);
      console.log(`  🏆 Level: ${userData.level || 1}`);
      console.log(`  💎 Rank: ${userData.rank || 'Bronze'}`);
      if (userData.walletAddress) {
        console.log(`  👛 Wallet: ${userData.walletAddress}`);
      }
    } else {
      console.log('📄 No user document found in Firestore');
    }
    console.log('');

    // Step 3: Start comprehensive deletion
    console.log('🗑️ STARTING COMPREHENSIVE DELETION...');
    console.log('====================================');
    
    const deletionResults = {
      auth: false,
      userData: false,
      rewardsLog: 0,
      socialVerifications: 0,
      redemptions: 0,
      battles: 0,
      pendingTransfers: 0,
      errors: []
    };

    // Delete from Firebase Auth
    console.log('🔥 Deleting from Firebase Authentication...');
    try {
      await admin.auth().deleteUser(userId);
      deletionResults.auth = true;
      console.log('✅ Firebase Auth user deleted');
    } catch (error) {
      console.error('❌ Auth deletion failed:', error.message);
      deletionResults.errors.push(`Auth deletion: ${error.message}`);
    }

    // Delete user document
    if (userDoc.exists) {
      console.log('📄 Deleting user document from Firestore...');
      try {
        await db.collection('users').doc(userId).delete();
        deletionResults.userData = true;
        console.log('✅ User document deleted');
      } catch (error) {
        console.error('❌ User document deletion failed:', error.message);
        deletionResults.errors.push(`User document: ${error.message}`);
      }
    }

    // Delete rewards log entries
    console.log('🎁 Cleaning up rewards log...');
    try {
      const rewardsQuery = await db.collection('rewards_log')
        .where('uid', '==', userId)
        .get();
      
      if (!rewardsQuery.empty) {
        const rewardsBatch = db.batch();
        rewardsQuery.docs.forEach(doc => {
          rewardsBatch.delete(doc.ref);
        });
        await rewardsBatch.commit();
      }
      deletionResults.rewardsLog = rewardsQuery.size;
      console.log(`✅ Deleted ${rewardsQuery.size} rewards log entries`);
    } catch (error) {
      console.error('❌ Rewards cleanup failed:', error.message);
      deletionResults.errors.push(`Rewards log: ${error.message}`);
    }

    // Delete social verifications
    console.log('📱 Cleaning up social verifications...');
    try {
      const socialQuery = await db.collection('users').doc(userId)
        .collection('social_verifications').get();
      
      if (!socialQuery.empty) {
        const socialBatch = db.batch();
        socialQuery.docs.forEach(doc => {
          socialBatch.delete(doc.ref);
        });
        await socialBatch.commit();
      }
      deletionResults.socialVerifications = socialQuery.size;
      console.log(`✅ Deleted ${socialQuery.size} social verification entries`);
    } catch (error) {
      console.error('❌ Social verifications cleanup failed:', error.message);
      deletionResults.errors.push(`Social verifications: ${error.message}`);
    }

    // Delete redemptions
    console.log('💸 Cleaning up redemptions...');
    try {
      const redemptionsQuery = await db.collection('redemptions')
        .where('uid', '==', userId)
        .get();
      
      if (!redemptionsQuery.empty) {
        const redemptionsBatch = db.batch();
        redemptionsQuery.docs.forEach(doc => {
          redemptionsBatch.delete(doc.ref);
        });
        await redemptionsBatch.commit();
      }
      deletionResults.redemptions = redemptionsQuery.size;
      console.log(`✅ Deleted ${redemptionsQuery.size} redemption entries`);
    } catch (error) {
      console.error('❌ Redemptions cleanup failed:', error.message);
      deletionResults.errors.push(`Redemptions: ${error.message}`);
    }

    // Update battle rounds
    console.log('⚔️ Removing from battle rounds...');
    try {
      const battlesQuery = await db.collection('timedRounds')
        .where('players', 'array-contains-any', [{ uid: userId }])
        .get();
      
      if (!battlesQuery.empty) {
        const battlesBatch = db.batch();
        battlesQuery.docs.forEach(battleDoc => {
          const battleData = battleDoc.data();
          const updatedPlayers = battleData.players.filter(player => player.uid !== userId);
          battlesBatch.update(battleDoc.ref, { 
            players: updatedPlayers,
            totalStake: updatedPlayers.reduce((sum, p) => sum + (p.stakeAmount || 0), 0)
          });
        });
        await battlesBatch.commit();
      }
      deletionResults.battles = battlesQuery.size;
      console.log(`✅ Removed user from ${battlesQuery.size} battle rounds`);
    } catch (error) {
      console.error('❌ Battles cleanup failed:', error.message);
      deletionResults.errors.push(`Battles: ${error.message}`);
    }

    // Delete pending transfers
    console.log('💳 Cleaning up pending transfers...');
    try {
      const transfersQuery = await db.collection('pending_transfers')
        .where('uid', '==', userId)
        .get();
      
      if (!transfersQuery.empty) {
        const transfersBatch = db.batch();
        transfersQuery.docs.forEach(doc => {
          transfersBatch.delete(doc.ref);
        });
        await transfersBatch.commit();
      }
      deletionResults.pendingTransfers = transfersQuery.size;
      console.log(`✅ Deleted ${transfersQuery.size} pending transfer entries`);
    } catch (error) {
      console.error('❌ Transfers cleanup failed:', error.message);
      deletionResults.errors.push(`Transfers: ${error.message}`);
    }

    // Create audit log
    console.log('📝 Creating audit log entry...');
    try {
      await db.collection('admin_actions').add({
        action: 'delete_user_account_admin_script',
        admin_type: 'direct_admin_script',
        target_user_id: userId,
        target_user_email: email,
        reason: reason,
        user_data_snapshot: userData,
        deletion_results: deletionResults,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        execution_timestamp: new Date().toISOString()
      });
      console.log('✅ Audit log entry created');
    } catch (error) {
      console.error('❌ Audit log failed:', error.message);
      deletionResults.errors.push(`Audit log: ${error.message}`);
    }

    // Final results
    console.log('');
    console.log('🎉 DELETION PROCESS COMPLETED!');
    console.log('=============================');
    console.log(`📧 Target Account: ${email}`);
    console.log(`👤 User ID: ${userId}`);
    console.log(`🕒 Completed: ${new Date().toLocaleString()}`);
    console.log('');
    console.log('📊 RESULTS SUMMARY:');
    console.log(`   🔥 Firebase Auth: ${deletionResults.auth ? '✅ Deleted' : '❌ Failed'}`);
    console.log(`   📄 User Document: ${deletionResults.userData ? '✅ Deleted' : 'ℹ️ Not found'}`);
    console.log(`   🎁 Rewards Log: ✅ ${deletionResults.rewardsLog} entries cleaned`);
    console.log(`   📱 Social Verifications: ✅ ${deletionResults.socialVerifications} entries cleaned`);
    console.log(`   💸 Redemptions: ✅ ${deletionResults.redemptions} entries cleaned`);
    console.log(`   ⚔️ Battle Rounds: ✅ ${deletionResults.battles} rounds updated`);
    console.log(`   💳 Pending Transfers: ✅ ${deletionResults.pendingTransfers} entries cleaned`);
    
    if (deletionResults.errors.length > 0) {
      console.log('');
      console.log('⚠️ ERRORS ENCOUNTERED:');
      deletionResults.errors.forEach(error => {
        console.log(`   ❌ ${error}`);
      });
    }
    
    console.log('');
    if (deletionResults.auth && deletionResults.errors.length === 0) {
      console.log('🎯 DELETION SUCCESSFUL! User account completely removed.');
    } else if (deletionResults.auth) {
      console.log('⚠️ PARTIAL SUCCESS: User deleted but some cleanup operations failed.');
    } else {
      console.log('❌ DELETION FAILED: User account may still exist.');
    }

    return {
      success: deletionResults.auth,
      deleted_user_id: userId,
      deletion_summary: deletionResults,
      execution_time: new Date().toISOString()
    };

  } catch (error) {
    console.error('');
    console.error('💥 CRITICAL ERROR:');
    console.error('=================');
    console.error(`Message: ${error.message}`);
    console.error(`Code: ${error.code || 'N/A'}`);
    if (error.stack) {
      console.error('Stack:', error.stack);
    }
    
    return {
      success: false,
      error: error.message,
      error_code: error.code
    };
  }
}

// Execute the deletion
deleteUserWithProjectConfig().then(result => {
  if (result.success) {
    console.log('\n🏆 MISSION ACCOMPLISHED!');
    process.exit(0);
  } else {
    console.log('\n💥 MISSION FAILED!');
    console.log('Error:', result.error);
    process.exit(1);
  }
}).catch(error => {
  console.error('\n💥 UNHANDLED ERROR:', error.message);
  process.exit(1);
});
