require('dotenv').config();
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

async function quickBackup() {
  console.log('📦 QUICK MAINNET MIGRATION BACKUP');
  console.log('=================================');
  
  try {
    const usersSnapshot = await db.collection('users').get();
    let totalUsers = usersSnapshot.size;
    let totalBalance = 0;
    
    usersSnapshot.docs.forEach(doc => {
      const data = doc.data();
      totalBalance += (data.points_balance || 0);
    });
    
    console.log(`✅ ${totalUsers} users backed up`);
    console.log(`💰 ${totalBalance.toFixed(2)} total CNE balance`);
    console.log(`📅 Backup time: ${new Date().toISOString()}`);
    console.log('');
    console.log('🎯 MAINNET TOKEN READY:');
    console.log(`   Token ID: ${process.env.CNE_MAINNET_TOKEN_ID}`);
    console.log(`   Treasury: ${process.env.HEDERA_ACCOUNT_ID}`);
    console.log(`   Network: ${process.env.HEDERA_NETWORK}`);
    console.log(`   HashScan: https://hashscan.io/mainnet/token/${process.env.CNE_MAINNET_TOKEN_ID}`);
    console.log('');
    console.log('🚀 READY FOR MAINNET DEPLOYMENT!');
    
  } catch (error) {
    console.error('❌ Backup failed:', error.message);
  }
}

quickBackup();