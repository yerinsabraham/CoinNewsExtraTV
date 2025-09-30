// Simple Configuration Validation (No Firebase Dependencies)
const fs = require('fs');

function validateMainnetConfig() {
  console.log('🔍 MAINNET CONFIGURATION VALIDATION');
  console.log('==================================');
  console.log('');

  const checks = [];
  let allPassed = true;

  try {
    // 1. Check .env file
    console.log('1️⃣ Checking environment variables...');
    try {
      const envContent = fs.readFileSync('functions/.env', 'utf8');
      
      const requiredVars = [
        'HEDERA_ACCOUNT_ID=0.0.9764298',
        'CNE_MAINNET_TOKEN_ID=0.0.9764298',
        'HEDERA_NETWORK=mainnet',
        'HEDERA_PRIVATE_KEY=49a9cd3f525ae156be2653288264a7d000364041f4ef8e4f1de8b265a728ba45'
      ];
      
      const missingVars = requiredVars.filter(varCheck => !envContent.includes(varCheck.split('=')[0]));
      
      if (missingVars.length === 0) {
        // Check specific values
        const hasCorrectAccountId = envContent.includes('HEDERA_ACCOUNT_ID=0.0.9764298');
        const hasCorrectTokenId = envContent.includes('CNE_MAINNET_TOKEN_ID=0.0.9764298');
        const hasMainnetNetwork = envContent.includes('HEDERA_NETWORK=mainnet');
        const hasPrivateKey = envContent.includes('HEDERA_PRIVATE_KEY=49a9cd3f525ae156be2653288264a7d000364041f4ef8e4f1de8b265a728ba45');
        
        if (hasCorrectAccountId && hasCorrectTokenId && hasMainnetNetwork && hasPrivateKey) {
          checks.push({ name: 'Environment Variables', status: '✅ PASS', details: 'All mainnet variables configured correctly' });
        } else {
          checks.push({ name: 'Environment Variables', status: '❌ FAIL', details: 'Some variables have incorrect values' });
          allPassed = false;
        }
      } else {
        checks.push({ name: 'Environment Variables', status: '❌ FAIL', details: `Missing: ${missingVars.join(', ')}` });
        allPassed = false;
      }
    } catch (error) {
      checks.push({ name: 'Environment Variables', status: '❌ FAIL', details: 'Cannot read .env file' });
      allPassed = false;
    }

    // 2. Check functions/index.js configuration
    console.log('2️⃣ Checking functions configuration...');
    try {
      const indexContent = fs.readFileSync('functions/index.js', 'utf8');
      
      const hasMainnetClient = indexContent.includes('Client.forMainnet()');
      const hasED25519Key = indexContent.includes('PrivateKey.fromStringED25519');
      const hasCorrectTokenId = indexContent.includes('CNE_MAINNET_TOKEN_ID');
      const hasCorrectAccountId = indexContent.includes('0.0.9764298');
      
      if (hasMainnetClient && hasED25519Key && hasCorrectTokenId && hasCorrectAccountId) {
        checks.push({ name: 'Functions Configuration', status: '✅ PASS', details: 'Mainnet client and ED25519 keys configured' });
      } else {
        const issues = [];
        if (!hasMainnetClient) issues.push('Still using testnet client');
        if (!hasED25519Key) issues.push('Still using ECDSA keys');
        if (!hasCorrectTokenId) issues.push('Wrong token ID reference');
        if (!hasCorrectAccountId) issues.push('Wrong account ID');
        
        checks.push({ name: 'Functions Configuration', status: '❌ FAIL', details: issues.join(', ') });
        allPassed = false;
      }
    } catch (error) {
      checks.push({ name: 'Functions Configuration', status: '❌ FAIL', details: 'Cannot read index.js file' });
      allPassed = false;
    }

    // 3. Check mainnet config file
    console.log('3️⃣ Checking mainnet configuration file...');
    try {
      const configContent = fs.readFileSync('mainnet-config.json', 'utf8');
      const config = JSON.parse(configContent);
      
      const hasCorrectTokenId = config.token_id === '0.0.9764298';
      const hasCorrectTreasury = config.treasury_account === '0.0.9764298';
      const hasMainnetNetwork = config.network === 'mainnet';
      const hasED25519KeyType = config.key_type === 'ED25519';
      
      if (hasCorrectTokenId && hasCorrectTreasury && hasMainnetNetwork && hasED25519KeyType) {
        checks.push({ name: 'Mainnet Config File', status: '✅ PASS', details: 'All configuration values correct' });
      } else {
        checks.push({ name: 'Mainnet Config File', status: '❌ FAIL', details: 'Some configuration values incorrect' });
        allPassed = false;
      }
    } catch (error) {
      checks.push({ name: 'Mainnet Config File', status: '❌ FAIL', details: 'Cannot read or parse config file' });
      allPassed = false;
    }

    // 4. Check if functions directory has dependencies
    console.log('4️⃣ Checking Firebase Functions setup...');
    try {
      const packageJson = fs.readFileSync('functions/package.json', 'utf8');
      const nodeModules = fs.existsSync('functions/node_modules');
      
      if (nodeModules) {
        checks.push({ name: 'Functions Dependencies', status: '✅ PASS', details: 'Firebase Functions ready for deployment' });
      } else {
        checks.push({ name: 'Functions Dependencies', status: '⚠️ WARN', details: 'Run "npm install" in functions directory' });
      }
    } catch (error) {
      checks.push({ name: 'Functions Dependencies', status: '❌ FAIL', details: 'Functions directory not properly set up' });
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

    console.log('🎯 MAINNET MIGRATION STATUS');
    console.log('==========================');
    
    if (allPassed) {
      console.log('✅ READY FOR MAINNET DEPLOYMENT!');
      console.log('');
      console.log('📊 Configuration Summary:');
      console.log(`   🪙 Token ID: 0.0.9764298`);
      console.log(`   🏦 Treasury: 0.0.9764298`);
      console.log(`   🔑 Key Type: ED25519`);
      console.log(`   🌐 Network: Mainnet`);
      console.log('');
      console.log('🚀 Next Steps:');
      console.log('   1. Deploy functions: firebase deploy --only functions');
      console.log('   2. Test with small transactions');
      console.log('   3. Monitor system health');
      console.log(`   4. Check token on HashScan: https://hashscan.io/mainnet/token/0.0.9764298`);
    } else {
      console.log('❌ CONFIGURATION ISSUES FOUND');
      console.log('');
      console.log('🔧 Please resolve the issues above before deployment.');
    }

    return {
      ready: allPassed,
      checks: checks
    };

  } catch (error) {
    console.error('💥 Validation failed with error:', error.message);
    return {
      ready: false,
      error: error.message,
      checks: checks
    };
  }
}

// Run validation
validateMainnetConfig();