// Final Mainnet Deployment Script
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

async function deployMainnetMigration() {
  console.log('🚀 FINAL MAINNET DEPLOYMENT');
  console.log('==========================');
  console.log('');

  const steps = [
    {
      name: 'Validate Configuration',
      command: 'node scripts/validate-migration.js',
      critical: true
    },
    {
      name: 'Deploy Firebase Functions', 
      command: 'firebase deploy --only functions',
      critical: true
    },
    {
      name: 'Deploy Firestore Rules',
      command: 'firebase deploy --only firestore:rules',
      critical: false
    },
    {
      name: 'Build Flutter App',
      command: 'flutter clean && flutter pub get && flutter build apk',
      critical: true
    },
    {
      name: 'Run Post-Deploy Validation',
      command: 'node scripts/validate-migration.js',
      critical: true
    }
  ];

  let allSuccess = true;

  for (let i = 0; i < steps.length; i++) {
    const step = steps[i];
    console.log(`${i + 1}️⃣ ${step.name}...`);
    
    try {
      const { stdout, stderr } = await execAsync(step.command);
      
      if (stdout) console.log(`   📄 ${stdout.slice(0, 200)}...`);
      if (stderr && !stderr.includes('warning')) {
        console.log(`   ⚠️ ${stderr.slice(0, 200)}...`);
      }
      
      console.log(`   ✅ ${step.name} completed`);
      console.log('');
      
    } catch (error) {
      console.error(`   ❌ ${step.name} failed:`, error.message);
      
      if (step.critical) {
        console.log('');
        console.log('🛑 CRITICAL STEP FAILED - STOPPING DEPLOYMENT');
        console.log('Please resolve the issue and try again.');
        allSuccess = false;
        break;
      } else {
        console.log('   ⚠️ Non-critical step failed, continuing...');
      }
      console.log('');
    }
  }

  console.log('🎯 DEPLOYMENT SUMMARY');
  console.log('====================');
  
  if (allSuccess) {
    console.log('✅ MAINNET DEPLOYMENT SUCCESSFUL!');
    console.log('');
    console.log('🎉 Your app is now running on Hedera Mainnet!');
    console.log('');
    console.log('📊 Next Steps:');
    console.log('1. Monitor system health for 24 hours');
    console.log('2. Test with small group of users');
    console.log('3. Gradually increase user access');
    console.log('4. Monitor transaction logs and balances');
    console.log('');
    console.log('🔗 Useful Links:');
    console.log('- HashScan Explorer: https://hashscan.io/mainnet');
    console.log('- Firebase Console: https://console.firebase.google.com');
    console.log('- App Monitoring Dashboard: [Your monitoring URL]');
  } else {
    console.log('❌ DEPLOYMENT FAILED OR INCOMPLETE');
    console.log('');
    console.log('🔧 Please resolve the issues and run again:');
    console.log('   node scripts/deploy-mainnet.js');
  }

  return allSuccess;
}

// Rollback function
async function rollbackToTestnet() {
  console.log('⏪ ROLLING BACK TO TESTNET');
  console.log('=========================');
  
  try {
    // This would restore testnet configuration
    console.log('1️⃣ Restoring testnet configuration...');
    
    // Restore environment variables
    const fs = require('fs').promises;
    let functionsEnv = await fs.readFile('functions/.env', 'utf8');
    
    functionsEnv = functionsEnv.replace(
      /CNE_MAINNET_TOKEN_ID=0\.0\.\d+/g,
      'CNE_TEST_TOKEN_ID=0.0.6917127'
    );
    
    functionsEnv = functionsEnv.replace(
      /HEDERA_NETWORK=mainnet/g,
      'HEDERA_NETWORK=testnet'
    );
    
    await fs.writeFile('functions/.env', functionsEnv);
    
    console.log('2️⃣ Redeploying testnet functions...');
    await execAsync('firebase deploy --only functions');
    
    console.log('✅ ROLLBACK COMPLETED');
    console.log('System restored to testnet configuration');
    
  } catch (error) {
    console.error('❌ ROLLBACK FAILED:', error);
    console.log('Manual intervention required!');
  }
}

// Command line interface
async function main() {
  const command = process.argv[2];
  
  if (command === 'rollback') {
    await rollbackToTestnet();
  } else if (command === 'deploy') {
    await deployMainnetMigration();
  } else {
    console.log('🔧 MAINNET DEPLOYMENT TOOL');
    console.log('==========================');
    console.log('');
    console.log('Usage:');
    console.log('  node scripts/deploy-mainnet.js deploy   # Deploy to mainnet');
    console.log('  node scripts/deploy-mainnet.js rollback # Rollback to testnet');
    console.log('');
    console.log('⚠️ Make sure you have:');
    console.log('1. Created mainnet CNE token');
    console.log('2. Updated configuration with token ID');
    console.log('3. Backed up all user data');
    console.log('4. Tested configuration locally');
  }
}

if (require.main === module) {
  main();
}

module.exports = { deployMainnetMigration, rollbackToTestnet };
