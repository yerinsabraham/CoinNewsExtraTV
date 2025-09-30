// Mainnet Migration Validation Script (Functions Directory)
require('dotenv').config();
const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function validateMigrationReadiness() {
  console.log('🔍 MAINNET MIGRATION VALIDATION');
  console.log('==============================');
  console.log('');

  const checks = [];
  let allPassed = true;

  try {
    // 1. Check Firebase connection
    console.log('1️⃣ Checking Firebase connection...');
    try {
      await db.collection('users').limit(1).get();
      checks.push({ name: 'Firebase Connection', status: '✅ PASS', details: 'Connected successfully' });
    } catch (error) {
      checks.push({ name: 'Firebase Connection', status: '❌ FAIL', details: error.message });
      allPassed = false;
    }

    // 2. Check environment variables
    console.log('2️⃣ Checking environment variables...');
    try {
      const requiredEnvVars = [
        'HEDERA_ACCOUNT_ID',
        'HEDERA_PRIVATE_KEY',
        'CNE_MAINNET_TOKEN_ID'
      ];
      
      const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
      
      if (missingVars.length === 0) {
        checks.push({ name: 'Environment Variables', status: '✅ PASS', details: 'All required variables present' });
        console.log(`   📍 Token ID: ${process.env.CNE_MAINNET_TOKEN_ID}`);
        console.log(`   🏦 Account ID: ${process.env.HEDERA_ACCOUNT_ID}`);
        console.log(`   🌐 Network: ${process.env.HEDERA_NETWORK}`);
      } else {
        checks.push({ 
          name: 'Environment Variables', 
          status: '❌ FAIL', 
          details: `Missing: ${missingVars.join(', ')}` 
        });
        allPassed = false;
      }
    } catch (error) {
      checks.push({ name: 'Environment Variables', status: '❌ FAIL', details: error.message });
      allPassed = false;
    }

    // 3. Check user data integrity
    console.log('3️⃣ Checking user data integrity...');
    try {
      const usersSnapshot = await db.collection('users').get();
      const userCount = usersSnapshot.size;
      
      let totalBalance = 0;
      let usersWithBalances = 0;

      usersSnapshot.docs.forEach(doc => {
        const data = doc.data();
        const balance = data.points_balance || 0;
        totalBalance += balance;
        
        if (balance > 0) usersWithBalances++;
      });

      checks.push({ 
        name: 'User Data Integrity', 
        status: '✅ PASS', 
        details: `${userCount} users, ${totalBalance.toFixed(2)} total CNE, ${usersWithBalances} with balances` 
      });

      console.log(`   👥 Users: ${userCount}`);
      console.log(`   💰 Total Balance: ${totalBalance.toFixed(2)} CNE`);
      console.log(`   📊 Users with Balances: ${usersWithBalances}`);

    } catch (error) {
      checks.push({ name: 'User Data Integrity', status: '❌ FAIL', details: error.message });
      allPassed = false;
    }

    // Summary
    console.log('');
    console.log('📋 VALIDATION SUMMARY');
    console.log('===================');
    console.log('');
    
    checks.forEach(check => {
      console.log(`${check.status} ${check.name}`);
      console.log(`   ${check.details}`);
      console.log('');
    });

    console.log('🎯 MAINNET MIGRATION READINESS');
    console.log('=============================');
    
    if (allPassed) {
      console.log('✅ READY FOR MAINNET DEPLOYMENT!');
      console.log('');
      console.log('🔗 Token Details:');
      console.log(`   Token ID: ${process.env.CNE_MAINNET_TOKEN_ID}`);
      console.log(`   Treasury: ${process.env.HEDERA_ACCOUNT_ID}`);
      console.log(`   Network: ${process.env.HEDERA_NETWORK}`);
      console.log(`   HashScan: https://hashscan.io/mainnet/token/${process.env.CNE_MAINNET_TOKEN_ID}`);
      console.log('');
      console.log('🚀 READY TO DEPLOY!');
    } else {
      console.log('❌ NOT READY FOR MIGRATION');
      console.log('Please resolve the failed checks before proceeding.');
    }

    return { ready: allPassed, checks: checks };

  } catch (error) {
    console.error('💥 Validation failed with error:', error);
    return { ready: false, error: error.message, checks: checks };
  }
}

// Run validation
validateMigrationReadiness().then(result => {
  if (result.ready) {
    console.log('');
    console.log('🎉 NEXT: Run deployment with:');
    console.log('   firebase deploy --only functions');
    console.log('   flutter clean && flutter run');
    process.exit(0);
  } else {
    console.log('');
    console.log('🔧 Fix issues first before deployment');
    process.exit(1);
  }
}).catch(error => {
  console.error('💥 Validation script error:', error);
  process.exit(1);
});