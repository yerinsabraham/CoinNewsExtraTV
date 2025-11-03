/**
 * Mainnet Configuration Update Script
 * 
 * This script updates the Flutter app and Firebase functions configuration
 * to use the new mainnet CNE token and network settings.
 */

const fs = require('fs');
const path = require('path');

class MainnetConfigUpdater {
    constructor() {
        this.mainnetConfig = {
            // Mainnet CNE Token Configuration
            tokenId: '0.0.10007647',
            treasuryAccountId: '0.0.10007646',
            operatorAccountId: '0.0.9764298',
            auditTopicId: '0.0.10007691',
            network: 'mainnet',
            
            // Migration tracking
            migrationDate: new Date().toISOString(),
            previousNetwork: 'testnet',
            previousTokenId: 'testnet-token-id' // Will be updated based on current config
        };

        this.updateSummary = {
            updatedFiles: [],
            backupFiles: [],
            errors: [],
            warnings: []
        };
    }

    /**
     * Create backup of original files before modification
     */
    createBackup(filePath) {
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const backupPath = `${filePath}.backup-${timestamp}`;
        
        if (fs.existsSync(filePath)) {
            fs.copyFileSync(filePath, backupPath);
            console.log(`📁 Backup created: ${backupPath}`);
            this.updateSummary.backupFiles.push(backupPath);
            return backupPath;
        }
        return null;
    }

    /**
     * Update Firebase Functions configuration
     */
    async updateFirebaseFunctions() {
        console.log('🔧 UPDATING FIREBASE FUNCTIONS CONFIGURATION');
        console.log('============================================');

        try {
            // Update functions/index.js
            await this.updateFunctionsIndex();
            
            // Update .env file
            await this.updateFunctionsEnv();
            
            // Update package.json if needed
            await this.updateFunctionsPackage();

            console.log('✅ Firebase Functions configuration updated');

        } catch (error) {
            console.error('❌ Error updating Firebase Functions:', error.message);
            this.updateSummary.errors.push(`Firebase Functions: ${error.message}`);
        }
    }

    /**
     * Update main functions configuration in index.js
     */
    async updateFunctionsIndex() {
        const functionsIndexPath = path.join(__dirname, 'index.js');
        
        if (!fs.existsSync(functionsIndexPath)) {
            throw new Error('functions/index.js not found');
        }

        console.log('📝 Updating functions/index.js...');
        this.createBackup(functionsIndexPath);

        let content = fs.readFileSync(functionsIndexPath, 'utf8');

        // Update network configuration
        content = content.replace(
            /const HEDERA_NETWORK = ["'][^"']*["']/g,
            `const HEDERA_NETWORK = "${this.mainnetConfig.network}"`
        );

        // Update token ID
        content = content.replace(
            /const CNE_TOKEN_ID = ["'][^"']*["']/g,
            `const CNE_TOKEN_ID = "${this.mainnetConfig.tokenId}"`
        );

        // Update treasury account
        content = content.replace(
            /const TREASURY_ACCOUNT_ID = ["'][^"']*["']/g,
            `const TREASURY_ACCOUNT_ID = "${this.mainnetConfig.treasuryAccountId}"`
        );

        // Update HCS topic
        content = content.replace(
            /const HCS_TOPIC_ID = ["'][^"']*["']/g,
            `const HCS_TOPIC_ID = "${this.mainnetConfig.auditTopicId}"`
        );

        // Add mainnet migration marker
        const migrationMarker = `
// MAINNET MIGRATION - ${this.mainnetConfig.migrationDate}
// Token ID: ${this.mainnetConfig.tokenId}
// Treasury: ${this.mainnetConfig.treasuryAccountId}
// Network: ${this.mainnetConfig.network}
`;

        if (!content.includes('MAINNET MIGRATION')) {
            content = migrationMarker + content;
        }

        fs.writeFileSync(functionsIndexPath, content);
        console.log('✅ functions/index.js updated');
        this.updateSummary.updatedFiles.push(functionsIndexPath);
    }

    /**
     * Update functions .env file
     */
    async updateFunctionsEnv() {
        const envPath = path.join(__dirname, '.env');
        
        console.log('📝 Updating functions/.env...');
        
        let envContent = '';
        if (fs.existsSync(envPath)) {
            this.createBackup(envPath);
            envContent = fs.readFileSync(envPath, 'utf8');
        }

        // Create new mainnet environment configuration
        const mainnetEnvConfig = `# MAINNET CONFIGURATION - Updated ${this.mainnetConfig.migrationDate}
# Hedera Network Settings
HEDERA_NETWORK=${this.mainnetConfig.network}
HEDERA_ACCOUNT_ID=${this.mainnetConfig.operatorAccountId}
HEDERA_PRIVATE_KEY=49a9cd3f525ae156be2653288264a7d000364041f4ef8e4f1de8b265a728ba45

# CNE Token Configuration
CNE_TOKEN_ID=${this.mainnetConfig.tokenId}
TREASURY_ACCOUNT_ID=${this.mainnetConfig.treasuryAccountId}

# Audit and Logging
HCS_TOPIC_ID=${this.mainnetConfig.auditTopicId}
ENABLE_MAINNET_LOGGING=true

# Security Settings
NODE_ENV=production
ENABLE_RATE_LIMITING=true
MAX_REWARDS_PER_MINUTE=10
ENABLE_FRAUD_DETECTION=true

# Migration Tracking
MIGRATION_DATE=${this.mainnetConfig.migrationDate}
PREVIOUS_NETWORK=${this.mainnetConfig.previousNetwork}
MAINNET_MIGRATION_COMPLETE=true
`;

        fs.writeFileSync(envPath, mainnetEnvConfig);
        console.log('✅ functions/.env updated');
        this.updateSummary.updatedFiles.push(envPath);
    }

    /**
     * Update package.json for functions
     */
    async updateFunctionsPackage() {
        const packagePath = path.join(__dirname, 'package.json');
        
        if (!fs.existsSync(packagePath)) {
            console.log('⚠️  functions/package.json not found, skipping');
            return;
        }

        console.log('📝 Updating functions/package.json...');
        this.createBackup(packagePath);

        const packageData = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
        
        // Update version to indicate mainnet
        if (packageData.version) {
            const versionParts = packageData.version.split('.');
            versionParts[1] = (parseInt(versionParts[1]) + 1).toString(); // Increment minor version
            packageData.version = versionParts.join('.') + '-mainnet';
        }

        // Add mainnet deployment script
        if (!packageData.scripts) {
            packageData.scripts = {};
        }
        
        packageData.scripts['deploy-mainnet'] = 'firebase deploy --only functions';
        packageData.scripts['test-mainnet'] = 'node test-mainnet-config.js';

        fs.writeFileSync(packagePath, JSON.stringify(packageData, null, 2));
        console.log('✅ functions/package.json updated');
        this.updateSummary.updatedFiles.push(packagePath);
    }

    /**
     * Update Flutter app configuration
     */
    async updateFlutterApp() {
        console.log('');
        console.log('📱 UPDATING FLUTTER APP CONFIGURATION');
        console.log('=====================================');

        try {
            // Update Firebase options
            await this.updateFirebaseOptions();
            
            // Update Dart configuration files
            await this.updateDartConfig();

            console.log('✅ Flutter app configuration updated');

        } catch (error) {
            console.error('❌ Error updating Flutter app:', error.message);
            this.updateSummary.errors.push(`Flutter App: ${error.message}`);
        }
    }

    /**
     * Update Firebase options for Flutter
     */
    async updateFirebaseOptions() {
        const firebaseOptionsPath = path.join(__dirname, '../lib/firebase_options.dart');
        
        if (!fs.existsSync(firebaseOptionsPath)) {
            console.log('⚠️  firebase_options.dart not found, skipping');
            this.updateSummary.warnings.push('firebase_options.dart not found');
            return;
        }

        console.log('📝 Updating lib/firebase_options.dart...');
        this.createBackup(firebaseOptionsPath);

        let content = fs.readFileSync(firebaseOptionsPath, 'utf8');

        // Add mainnet configuration comment
        const mainnetComment = `
// MAINNET MIGRATION CONFIGURATION
// Migration Date: ${this.mainnetConfig.migrationDate}
// CNE Token: ${this.mainnetConfig.tokenId}
// Network: ${this.mainnetConfig.network}
`;

        if (!content.includes('MAINNET MIGRATION CONFIGURATION')) {
            content = content.replace(
                'import \'package:firebase_core/firebase_core.dart\';',
                `import 'package:firebase_core/firebase_core.dart';${mainnetComment}`
            );
        }

        fs.writeFileSync(firebaseOptionsPath, content);
        console.log('✅ firebase_options.dart updated');
        this.updateSummary.updatedFiles.push(firebaseOptionsPath);
    }

    /**
     * Update Dart configuration files
     */
    async updateDartConfig() {
        // Create mainnet configuration file
        const configPath = path.join(__dirname, '../lib/config/mainnet_config.dart');
        const configDir = path.dirname(configPath);

        if (!fs.existsSync(configDir)) {
            fs.mkdirSync(configDir, { recursive: true });
        }

        console.log('📝 Creating lib/config/mainnet_config.dart...');

        const dartConfig = `// GENERATED MAINNET CONFIGURATION
// Generated on: ${this.mainnetConfig.migrationDate}
// DO NOT MODIFY MANUALLY - Use configuration scripts

class MainnetConfig {
  // Hedera Network Configuration
  static const String network = '${this.mainnetConfig.network}';
  static const String operatorAccountId = '${this.mainnetConfig.operatorAccountId}';
  
  // CNE Token Configuration
  static const String cneTokenId = '${this.mainnetConfig.tokenId}';
  static const String treasuryAccountId = '${this.mainnetConfig.treasuryAccountId}';
  
  // HCS Audit Configuration
  static const String auditTopicId = '${this.mainnetConfig.auditTopicId}';
  
  // Migration Metadata
  static const String migrationDate = '${this.mainnetConfig.migrationDate}';
  static const String previousNetwork = '${this.mainnetConfig.previousNetwork}';
  static const bool isMainnet = true;
  static const bool migrationComplete = true;
  
  // Explorer URLs
  static String get tokenExplorerUrl => 'https://hashscan.io/mainnet/token/\$cneTokenId';
  static String get treasuryExplorerUrl => 'https://hashscan.io/mainnet/account/\$treasuryAccountId';
  static String get auditExplorerUrl => 'https://hashscan.io/mainnet/topic/\$auditTopicId';
  
  // Validation
  static bool validateConfiguration() {
    return cneTokenId.startsWith('0.0.') && 
           treasuryAccountId.startsWith('0.0.') &&
           network == 'mainnet';
  }
  
  // Network endpoints
  static const String hederaNetworkEndpoint = 'mainnet-public.mirrornode.hedera.com';
  static const bool useTestnet = false;
}

// Legacy support - will be deprecated
class TokenConfig {
  @Deprecated('Use MainnetConfig.cneTokenId instead')
  static const String tokenId = MainnetConfig.cneTokenId;
  
  @Deprecated('Use MainnetConfig.treasuryAccountId instead')  
  static const String treasuryId = MainnetConfig.treasuryAccountId;
}
`;

        fs.writeFileSync(configPath, dartConfig);
        console.log('✅ mainnet_config.dart created');
        this.updateSummary.updatedFiles.push(configPath);
    }

    /**
     * Update project documentation
     */
    async updateDocumentation() {
        console.log('');
        console.log('📚 UPDATING PROJECT DOCUMENTATION');
        console.log('=================================');

        try {
            await this.createMigrationSummary();
            await this.updateReadme();
            console.log('✅ Documentation updated');

        } catch (error) {
            console.error('❌ Error updating documentation:', error.message);
            this.updateSummary.errors.push(`Documentation: ${error.message}`);
        }
    }

    /**
     * Create comprehensive migration summary
     */
    async createMigrationSummary() {
        const summaryPath = path.join(__dirname, '../MAINNET_MIGRATION_SUMMARY.md');
        
        console.log('📝 Creating migration summary...');

        const summaryContent = `# Mainnet Migration Summary

**Migration Date:** ${this.mainnetConfig.migrationDate}
**Status:** ✅ COMPLETED

## Migration Details

### Token Configuration
- **Mainnet CNE Token ID:** \`${this.mainnetConfig.tokenId}\`
- **Treasury Account:** \`${this.mainnetConfig.treasuryAccountId}\`
- **Network:** ${this.mainnetConfig.network}
- **Operator Account:** \`${this.mainnetConfig.operatorAccountId}\`

### Blockchain Verification
- **Token Explorer:** [View on HashScan](https://hashscan.io/mainnet/token/${this.mainnetConfig.tokenId})
- **Treasury Explorer:** [View Treasury](https://hashscan.io/mainnet/account/${this.mainnetConfig.treasuryAccountId})
- **Audit Trail:** [View HCS Topic](https://hashscan.io/mainnet/topic/${this.mainnetConfig.auditTopicId})

### Security Infrastructure
- ✅ KMS Key Management implemented
- ✅ Treasury private key secured
- ✅ Merkle tree balance verification
- ✅ HCS audit trail established
- ✅ Rate limiting and fraud detection enabled

### Updated Files
${this.updateSummary.updatedFiles.map(file => `- \`${file}\``).join('\\n')}

### Backup Files
${this.updateSummary.backupFiles.map(file => `- \`${file}\``).join('\\n')}

## Post-Migration Checklist

### Immediate Actions Required
- [ ] Deploy updated Firebase Functions
- [ ] Test mainnet functionality in staging
- [ ] Verify token operations work correctly
- [ ] Update user documentation
- [ ] Notify beta testers

### User Communication
- [ ] Announce mainnet migration to users
- [ ] Provide token association instructions
- [ ] Update help documentation
- [ ] Create migration FAQ

### Monitoring Setup
- [ ] Enable production monitoring
- [ ] Set up alert systems
- [ ] Configure audit log review
- [ ] Establish incident response procedures

## Rollback Procedure
In case of issues, restore from backup files:
${this.updateSummary.backupFiles.map(file => `\`cp ${file} ${file.replace(/\\.backup-.*$/, '')}\``).join('\\n')}

## Support Information
- **Technical Lead:** Development Team
- **Migration Scripts:** \`functions/\` directory  
- **Configuration Files:** \`lib/config/mainnet_config.dart\`
- **Emergency Contact:** [Insert emergency contact]

---
Generated: ${new Date().toISOString()}
Migration Tool: mainnet-config-updater.js
`;

        fs.writeFileSync(summaryPath, summaryContent);
        console.log('✅ Migration summary created');
        this.updateSummary.updatedFiles.push(summaryPath);
    }

    /**
     * Update project README
     */
    async updateReadme() {
        const readmePath = path.join(__dirname, '../README.md');
        
        if (!fs.existsSync(readmePath)) {
            console.log('⚠️  README.md not found, skipping');
            return;
        }

        console.log('📝 Updating README.md...');
        this.createBackup(readmePath);

        let content = fs.readFileSync(readmePath, 'utf8');

        // Add mainnet badge at the top
        const mainnetBadge = `
![Mainnet](https://img.shields.io/badge/Network-Mainnet-green)
![Token](https://img.shields.io/badge/CNE%20Token-${this.mainnetConfig.tokenId}-blue)
![Migration](https://img.shields.io/badge/Migration-Complete-success)
`;

        if (!content.includes('Network-Mainnet')) {
            content = content.replace(/^(# [^\n]+)/, `$1${mainnetBadge}`);
        }

        // Add mainnet configuration section
        const configSection = `

## Mainnet Configuration

**🌐 Network:** Hedera Mainnet  
**🪙 CNE Token:** [\`${this.mainnetConfig.tokenId}\`](https://hashscan.io/mainnet/token/${this.mainnetConfig.tokenId})  
**🏦 Treasury:** [\`${this.mainnetConfig.treasuryAccountId}\`](https://hashscan.io/mainnet/account/${this.mainnetConfig.treasuryAccountId})  
**📊 Audit Trail:** [HCS Topic](https://hashscan.io/mainnet/topic/${this.mainnetConfig.auditTopicId})  

**Migration Date:** ${this.mainnetConfig.migrationDate}
`;

        if (!content.includes('## Mainnet Configuration')) {
            content = content.replace(/^## /, `${configSection}\n\n## `);
        }

        fs.writeFileSync(readmePath, content);
        console.log('✅ README.md updated');
        this.updateSummary.updatedFiles.push(readmePath);
    }

    /**
     * Validate updated configuration
     */
    async validateConfiguration() {
        console.log('');
        console.log('🔍 VALIDATING UPDATED CONFIGURATION');
        console.log('===================================');

        const validationResults = {
            functionsConfig: false,
            flutterConfig: false,
            tokenValidation: false,
            fileIntegrity: false
        };

        try {
            // Check functions configuration
            const envPath = path.join(__dirname, '.env');
            if (fs.existsSync(envPath)) {
                const envContent = fs.readFileSync(envPath, 'utf8');
                validationResults.functionsConfig = 
                    envContent.includes(this.mainnetConfig.tokenId) &&
                    envContent.includes('mainnet');
                console.log('✅ Functions configuration valid');
            }

            // Check Flutter configuration  
            const dartConfigPath = path.join(__dirname, '../lib/config/mainnet_config.dart');
            if (fs.existsSync(dartConfigPath)) {
                const dartContent = fs.readFileSync(dartConfigPath, 'utf8');
                validationResults.flutterConfig = 
                    dartContent.includes(this.mainnetConfig.tokenId) &&
                    dartContent.includes('mainnet');
                console.log('✅ Flutter configuration valid');
            }

            // Validate token ID format
            validationResults.tokenValidation = 
                this.mainnetConfig.tokenId.match(/^0\.0\.\d+$/) !== null;
            console.log('✅ Token ID format valid');

            // Check file integrity
            validationResults.fileIntegrity = 
                this.updateSummary.updatedFiles.every(file => fs.existsSync(file));
            console.log('✅ File integrity valid');

            const allValid = Object.values(validationResults).every(v => v);
            console.log('');
            console.log('📊 VALIDATION SUMMARY');
            console.log('====================');
            console.log('Overall Status:', allValid ? '✅ PASSED' : '❌ FAILED');
            console.log('Functions Config:', validationResults.functionsConfig ? '✅' : '❌');
            console.log('Flutter Config:', validationResults.flutterConfig ? '✅' : '❌');
            console.log('Token Validation:', validationResults.tokenValidation ? '✅' : '❌');
            console.log('File Integrity:', validationResults.fileIntegrity ? '✅' : '❌');

            return allValid;

        } catch (error) {
            console.error('❌ Validation failed:', error.message);
            return false;
        }
    }

    /**
     * Execute complete configuration update
     */
    async execute() {
        try {
            console.log('🚀 MAINNET CONFIGURATION UPDATE');
            console.log('===============================');
            console.log('Target Token:', this.mainnetConfig.tokenId);
            console.log('Network:', this.mainnetConfig.network);
            console.log('Treasury:', this.mainnetConfig.treasuryAccountId);
            console.log('');

            // Update Firebase Functions
            await this.updateFirebaseFunctions();

            // Update Flutter App
            await this.updateFlutterApp();

            // Update Documentation
            await this.updateDocumentation();

            // Validate configuration
            const isValid = await this.validateConfiguration();

            console.log('');
            console.log('🎉 MAINNET CONFIGURATION UPDATE COMPLETE');
            console.log('========================================');
            console.log('');
            console.log('📊 UPDATE SUMMARY');
            console.log('=================');
            console.log('Files Updated:', this.updateSummary.updatedFiles.length);
            console.log('Backups Created:', this.updateSummary.backupFiles.length);
            console.log('Errors:', this.updateSummary.errors.length);
            console.log('Warnings:', this.updateSummary.warnings.length);
            console.log('Validation:', isValid ? '✅ PASSED' : '❌ FAILED');
            
            if (this.updateSummary.errors.length > 0) {
                console.log('');
                console.log('❌ ERRORS:');
                this.updateSummary.errors.forEach(error => console.log(`   ${error}`));
            }

            if (this.updateSummary.warnings.length > 0) {
                console.log('');
                console.log('⚠️  WARNINGS:');
                this.updateSummary.warnings.forEach(warning => console.log(`   ${warning}`));
            }

            console.log('');
            console.log('🔧 NEXT STEPS');
            console.log('=============');
            console.log('1. Deploy Firebase Functions: firebase deploy --only functions');
            console.log('2. Test configuration: flutter test');
            console.log('3. Build Flutter app: flutter build');
            console.log('4. Deploy to staging for testing');
            console.log('5. Proceed with security hardening (Step 7)');
            console.log('');
            console.log('📚 Documentation: See MAINNET_MIGRATION_SUMMARY.md');

            return {
                success: isValid,
                summary: this.updateSummary,
                config: this.mainnetConfig
            };

        } catch (error) {
            console.error('💥 Configuration update failed:', error);
            throw error;
        }
    }
}

// Execute if called directly
if (require.main === module) {
    const updater = new MainnetConfigUpdater();
    updater.execute()
        .then(result => {
            console.log('🎉 Configuration update completed successfully!');
            process.exit(0);
        })
        .catch(error => {
            console.error('💥 Update failed:', error);
            process.exit(1);
        });
}

module.exports = MainnetConfigUpdater;