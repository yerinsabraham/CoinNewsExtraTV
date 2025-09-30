// Mainnet Migration Configuration Update Script
const fs = require('fs').promises;
const path = require('path');

async function updateMainnetConfiguration(newTokenId, treasuryAccountId) {
  console.log('🚀 STARTING MAINNET MIGRATION CONFIGURATION');
  console.log('==========================================');
  console.log(`📍 New Token ID: ${newTokenId}`);
  console.log(`🏦 Treasury Account: ${treasuryAccountId}`);
  console.log('');

  const updates = [];

  try {
    // 1. Update Firebase Functions environment variables
    console.log('1️⃣ Updating Firebase Functions configuration...');
    
    const functionsEnvPath = 'functions/.env';
    try {
      let functionsEnv = await fs.readFile(functionsEnvPath, 'utf8');
      
      // Update token ID
      functionsEnv = functionsEnv.replace(
        /CNE_TEST_TOKEN_ID=0\.0\.\d+/g,
        `CNE_MAINNET_TOKEN_ID=${newTokenId}`
      );
      
      // Update network to mainnet
      functionsEnv = functionsEnv.replace(
        /HEDERA_NETWORK=testnet/g,
        'HEDERA_NETWORK=mainnet'
      );
      
      // Update treasury account if provided
      if (treasuryAccountId) {
        functionsEnv = functionsEnv.replace(
          /HEDERA_ACCOUNT_ID=0\.0\.\d+/g,
          `HEDERA_ACCOUNT_ID=${treasuryAccountId}`
        );
      }
      
      await fs.writeFile(functionsEnvPath, functionsEnv);
      updates.push('✅ Functions .env updated');
    } catch (error) {
      updates.push(`❌ Functions .env update failed: ${error.message}`);
    }

    // 2. Update Firebase Functions index.js
    console.log('2️⃣ Updating Cloud Functions code...');
    
    const functionsIndexPath = 'functions/index.js';
    try {
      let functionsIndex = await fs.readFile(functionsIndexPath, 'utf8');
      
      // Update token ID reference
      functionsIndex = functionsIndex.replace(
        /const CNE_TOKEN_ID = process\.env\.CNE_TEST_TOKEN_ID \|\| "0\.0\.\d+";/g,
        `const CNE_TOKEN_ID = process.env.CNE_MAINNET_TOKEN_ID || "${newTokenId}";`
      );
      
      // Update network client initialization
      functionsIndex = functionsIndex.replace(
        /hederaClient = Client\.forTestnet\(\);/g,
        'hederaClient = Client.forMainnet();'
      );
      
      await fs.writeFile(functionsIndexPath, functionsIndex);
      updates.push('✅ Cloud Functions updated');
    } catch (error) {
      updates.push(`❌ Cloud Functions update failed: ${error.message}`);
    }

    // 3. Update Flutter app configuration
    console.log('3️⃣ Updating Flutter app configuration...');
    
    // Update any Dart configuration files that might have token references
    const dartFiles = [
      'lib/services/reward_service.dart',
      'lib/services/user_balance_service.dart',
      'lib/firebase_options.dart'
    ];
    
    for (const dartFile of dartFiles) {
      try {
        let dartContent = await fs.readFile(dartFile, 'utf8');
        
        // Look for any hardcoded token IDs and update them
        if (dartContent.includes('0.0.6917127') || dartContent.includes('testnet')) {
          dartContent = dartContent.replace(/0\.0\.6917127/g, newTokenId);
          dartContent = dartContent.replace(/testnet/g, 'mainnet');
          
          await fs.writeFile(dartFile, dartContent);
          updates.push(`✅ ${dartFile} updated`);
        }
      } catch (error) {
        // File might not exist or not need updates
        console.log(`ℹ️ ${dartFile} - no updates needed or file not found`);
      }
    }

    // 4. Update documentation files
    console.log('4️⃣ Updating documentation...');
    
    const docFiles = [
      'REWARD_LOGIC_FRAMEWORK.md',
      'FLUTTER_TOKENOMICS_INTEGRATION.md',
      'DEPLOYMENT_SUCCESS_REPORT.md'
    ];
    
    for (const docFile of docFiles) {
      try {
        let docContent = await fs.readFile(docFile, 'utf8');
        
        if (docContent.includes('0.0.6917127') || docContent.includes('testnet')) {
          docContent = docContent.replace(/0\.0\.6917127/g, newTokenId);
          docContent = docContent.replace(/testnet/g, 'mainnet');
          docContent = docContent.replace(/CNE_TEST/g, 'CNE_MAINNET');
          
          await fs.writeFile(docFile, docContent);
          updates.push(`✅ ${docFile} updated`);
        }
      } catch (error) {
        console.log(`ℹ️ ${docFile} - no updates needed or file not found`);
      }
    }

    // 5. Create mainnet environment configuration
    console.log('5️⃣ Creating mainnet environment config...');
    
    const mainnetConfig = {
      environment: 'mainnet',
      token_id: newTokenId,
      treasury_account: treasuryAccountId,
      network: 'mainnet',
      migration_date: new Date().toISOString(),
      hedera_endpoints: {
        network: 'mainnet',
        mirror_node: 'https://mainnet-public.mirrornode.hedera.com',
        consensus_nodes: [
          '35.237.200.180:50211',
          '35.186.191.247:50211', 
          '35.192.2.25:50211'
        ]
      }
    };
    
    await fs.writeFile('mainnet-config.json', JSON.stringify(mainnetConfig, null, 2));
    updates.push('✅ Mainnet configuration file created');

    // 6. Update package.json scripts if needed
    console.log('6️⃣ Checking package.json scripts...');
    
    try {
      const packageJson = JSON.parse(await fs.readFile('package.json', 'utf8'));
      
      // Add mainnet deployment script if not exists
      if (!packageJson.scripts['deploy:mainnet']) {
        packageJson.scripts['deploy:mainnet'] = 'firebase use coinnewsextratv-9c75a && firebase deploy --only functions';
        packageJson.scripts['backup:users'] = 'node scripts/backup-user-data.js';
        
        await fs.writeFile('package.json', JSON.stringify(packageJson, null, 2));
        updates.push('✅ Package.json scripts updated');
      }
    } catch (error) {
      console.log('ℹ️ Package.json - no updates needed');
    }

    // Summary
    console.log('');
    console.log('🎉 MAINNET CONFIGURATION UPDATE COMPLETED');
    console.log('========================================');
    console.log('');
    console.log('📊 Update Summary:');
    updates.forEach(update => console.log(`   ${update}`));
    console.log('');
    console.log('🎯 Next Steps:');
    console.log('   1. Review all updated files');
    console.log('   2. Test configuration locally');
    console.log('   3. Deploy to Firebase Functions');
    console.log('   4. Update Flutter app');
    console.log('   5. Test with pilot users');
    console.log('');
    console.log('⚠️  IMPORTANT: Test thoroughly before full deployment!');

    return {
      success: true,
      updates_applied: updates.length,
      new_token_id: newTokenId,
      treasury_account: treasuryAccountId
    };

  } catch (error) {
    console.error('❌ MIGRATION CONFIGURATION FAILED:', error);
    return {
      success: false,
      error: error.message,
      updates_applied: updates.length
    };
  }
}

// Command line execution
async function main() {
  const args = process.argv.slice(2);
  
  if (args.length < 1) {
    console.log('🔧 MAINNET MIGRATION CONFIGURATION TOOL');
    console.log('=====================================');
    console.log('');
    console.log('Usage: node scripts/update-mainnet-config.js <NEW_TOKEN_ID> [TREASURY_ACCOUNT_ID]');
    console.log('');
    console.log('Example:');
    console.log('  node scripts/update-mainnet-config.js 0.0.1234567');
    console.log('  node scripts/update-mainnet-config.js 0.0.1234567 0.0.7654321');
    console.log('');
    console.log('📋 Steps:');
    console.log('  1. Create mainnet CNE token in HashPack');
    console.log('  2. Copy the Token ID');
    console.log('  3. Run this script with the Token ID');
    console.log('  4. Review and deploy changes');
    return;
  }

  const newTokenId = args[0];
  const treasuryAccountId = args[1] || null;

  // Validate token ID format
  if (!/^0\.0\.\d+$/.test(newTokenId)) {
    console.error('❌ Invalid token ID format. Expected: 0.0.XXXXXX');
    process.exit(1);
  }

  const result = await updateMainnetConfiguration(newTokenId, treasuryAccountId);
  
  if (result.success) {
    console.log('🎯 Configuration update completed successfully!');
    process.exit(0);
  } else {
    console.error('💥 Configuration update failed!');
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { updateMainnetConfiguration };
