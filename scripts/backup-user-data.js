// Pre-Migration User Data Backup Script
const admin = require('firebase-admin');
const fs = require('fs').promises;

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

async function backupUserData() {
  console.log('🔄 Starting user data backup...');
  
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupFile = `user-backup-${timestamp}.json`;
  
  try {
    // Get all users
    const usersSnapshot = await db.collection('users').get();
    const userData = [];
    
    for (const userDoc of usersSnapshot.docs) {
      const data = userDoc.data();
      userData.push({
        uid: userDoc.id,
        email: data.email || 'unknown',
        points_balance: data.points_balance || 0,
        available_balance: data.available_balance || 0,
        locked_balance: data.locked_balance || 0,
        total_earned: data.total_earned || 0,
        level: data.level || 1,
        rank: data.rank || 'Bronze',
        walletAddress: data.walletAddress || null,
        createdAt: data.createdAt,
        lastActive: data.lastActive
      });
    }
    
    // Get rewards log
    const rewardsSnapshot = await db.collection('rewards_log').get();
    const rewardsData = [];
    
    for (const rewardDoc of rewardsSnapshot.docs) {
      rewardsData.push({
        id: rewardDoc.id,
        ...rewardDoc.data()
      });
    }
    
    // Create comprehensive backup
    const backup = {
      backup_date: new Date().toISOString(),
      users_count: userData.length,
      rewards_count: rewardsData.length,
      total_balance: userData.reduce((sum, user) => sum + (user.points_balance || 0), 0),
      users: userData,
      rewards_log: rewardsData
    };
    
    // Save to file
    await fs.writeFile(backupFile, JSON.stringify(backup, null, 2));
    
    console.log(`✅ Backup completed successfully!`);
    console.log(`📁 File: ${backupFile}`);
    console.log(`👥 Users: ${userData.length}`);
    console.log(`🎁 Rewards: ${rewardsData.length}`);
    console.log(`💰 Total Balance: ${backup.total_balance.toFixed(2)} CNE`);
    
    return backup;
    
  } catch (error) {
    console.error('❌ Backup failed:', error);
    throw error;
  }
}

// Run backup
backupUserData().then(() => {
  console.log('🎯 Backup process completed');
  process.exit(0);
}).catch(error => {
  console.error('💥 Backup process failed:', error);
  process.exit(1);
});
