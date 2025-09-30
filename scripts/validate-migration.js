// Mainnet Migration Validation Script
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

    // 2. Check user data integrity
    console.log('2️⃣ Checking user data integrity...');
    try {
      const usersSnapshot = await db.collection('users').get();
      const userCount = usersSnapshot.size;
      
      let totalBalance = 0;
      let usersWithBalances = 0;
      let usersWithWallets = 0;

      usersSnapshot.docs.forEach(doc => {
        const data = doc.data();
        const balance = data.points_balance || 0;
        totalBalance += balance;
        
        if (balance > 0) usersWithBalances++;
        if (data.walletAddress) usersWithWallets++;
      });

      checks.push({ 
        name: 'User Data Integrity', 
        status: '✅ PASS', 
        details: `${userCount} users, ${totalBalance.toFixed(2)} total CNE, ${usersWithBalances} with balances` 
      });

      console.log(`   📊 Users: ${userCount}`);
      console.log(`   💰 Total Balance: ${totalBalance.toFixed(2)} CNE`);
      console.log(`   👥 Users with Balances: ${usersWithBalances}`);
      console.log(`   👛 Users with Wallets: ${usersWithWallets}`);

    } catch (error) {
      checks.push({ name: 'User Data Integrity', status: '❌ FAIL', details: error.message });
      allPassed = false;
    }

    // 3. Check rewards log
    console.log('3️⃣ Checking rewards log...');
    try {
      const rewardsSnapshot = await db.collection('rewards_log').limit(100).get();
      const rewardCount = rewardsSnapshot.size;
      
      checks.push({ 
        name: 'Rewards Log', 
        status: '✅ PASS', 
        details: `${rewardCount} recent reward entries found` 
      });
    } catch (error) {
      checks.push({ name: 'Rewards Log', status: '❌ FAIL', details: error.message });
      allPassed = false;
    }

    // 4. Check admin accounts
    console.log('4️⃣ Checking admin accounts...');
    try {
      const adminsSnapshot = await db.collection('admins').get();
      const adminCount = adminsSnapshot.size;
      
      checks.push({ 
        name: 'Admin Accounts', 
        status: adminCount > 0 ? '✅ PASS' : '⚠️ WARN', 
        details: `${adminCount} admin accounts configured` 
      });
    } catch (error) {
      checks.push({ name: 'Admin Accounts', status: '❌ FAIL', details: error.message });
    }

    // 5. Check system configuration
    console.log('5️⃣ Checking system configuration...');
    try {
      const configDocs = await Promise.all([
        db.doc('config/halving').get(),
        db.doc('config/system').get()
      ]);
      
      const halvingConfig = configDocs[0].exists;
      const systemConfig = configDocs[1].exists;
      
      checks.push({ 
        name: 'System Configuration', 
        status: (halvingConfig && systemConfig) ? '✅ PASS' : '⚠️ WARN', 
        details: `Halving: ${halvingConfig ? 'OK' : 'Missing'}, System: ${systemConfig ? 'OK' : 'Missing'}` 
      });
    } catch (error) {
      checks.push({ name: 'System Configuration', status: '❌ FAIL', details: error.message });
    }

    // 6. Check environment variables
    console.log('6️⃣ Checking environment variables...');
    try {
      const requiredEnvVars = [
        'HEDERA_ACCOUNT_ID',
        'HEDERA_PRIVATE_KEY',
        'CNE_MAINNET_TOKEN_ID'
      ];
      
      const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
      
      if (missingVars.length === 0) {
        checks.push({ name: 'Environment Variables', status: '✅ PASS', details: 'All required variables present' });
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

    console.log('🎯 MIGRATION READINESS');
    console.log('=====================');
    
    if (allPassed) {
      console.log('✅ READY FOR MIGRATION');
      console.log('All critical checks passed. You can proceed with mainnet migration.');
    } else {
      console.log('❌ NOT READY FOR MIGRATION');
      console.log('Please resolve the failed checks before proceeding.');
    }

    return {
      ready: allPassed,
      checks: checks,
      summary: {
        total_checks: checks.length,
        passed: checks.filter(c => c.status.includes('✅')).length,
        warnings: checks.filter(c => c.status.includes('⚠️')).length,
        failed: checks.filter(c => c.status.includes('❌')).length
      }
    };

  } catch (error) {
    console.error('💥 Validation failed with error:', error);
    return {
      ready: false,
      error: error.message,
      checks: checks
    };
  }
}

// Token validation function
async function validateTokenCreation(tokenId) {
  console.log('🪙 VALIDATING MAINNET TOKEN');
  console.log(`Token ID: ${tokenId}`);
  console.log('========================');
  
  try {
    // Note: This would require Hedera SDK to actually validate
    // For now, we'll do basic format validation
    
    if (!/^0\.0\.\d+$/.test(tokenId)) {
      console.log('❌ Invalid token ID format');
      return false;
    }
    
    console.log('✅ Token ID format valid');
    console.log(`🔗 Check on HashScan: https://hashscan.io/mainnet/token/${tokenId}`);
    
    return true;
    
  } catch (error) {
    console.error('❌ Token validation failed:', error);
    return false;
  }
}

// Run validation
async function main() {
  const result = await validateMigrationReadiness();
  
  if (result.ready) {
    console.log('');
    console.log('🚀 NEXT STEPS:');
    console.log('1. Create mainnet CNE token');
    console.log('2. Run: node scripts/update-mainnet-config.js <TOKEN_ID>');
    console.log('3. Deploy updated functions');
    console.log('4. Test with pilot users');
    console.log('5. Full migration');
    process.exit(0);
  } else {
    console.log('');
    console.log('🔧 RESOLVE ISSUES FIRST:');
    result.checks.filter(c => c.status.includes('❌')).forEach(check => {
      console.log(`- ${check.name}: ${check.details}`);
    });
    process.exit(1);
  }
}

// Export for use in other scripts
module.exports = { validateMigrationReadiness, validateTokenCreation };

// Run if called directly
if (require.main === module) {
  main();
}
