/**
 * KMS Security Setup for Mainnet CNE Token Treasury
 * 
 * This script sets up secure key management infrastructure for the treasury account
 * following enterprise security standards for cryptocurrency operations.
 */

const fs = require('fs');
const crypto = require('crypto');
const path = require('path');

class KMSSecuritySetup {
    constructor() {
        this.kmsReferences = require('../kms_references.json');
        this.deploymentReceipts = require('../mainnet_deployment_receipts.json');
        
        // Security configuration
        this.config = {
            keyRotationDays: 90,
            backupRequired: true,
            auditLogging: true,
            multiSignatureThreshold: 2,
            emergencyRecovery: true
        };
    }

    /**
     * Step 1: Secure the Treasury Private Key
     */
    async secureTreasuryKey() {
        console.log('🔐 SECURING TREASURY PRIVATE KEY');
        console.log('================================');

        try {
            // Read the generated treasury key
            const treasuryKeyPath = path.join(__dirname, '..', 'treasury_private_key.SECURE');
            
            if (!fs.existsSync(treasuryKeyPath)) {
                throw new Error('Treasury private key file not found');
            }

            const treasuryKey = fs.readFileSync(treasuryKeyPath, 'utf8').trim();
            console.log('✅ Treasury key located');

            // Create encrypted backup
            const encryptedKey = this.encryptKey(treasuryKey);
            
            // Save encrypted version
            const backupPath = path.join(__dirname, 'treasury_key_encrypted.backup');
            fs.writeFileSync(backupPath, JSON.stringify(encryptedKey, null, 2));
            console.log('✅ Encrypted backup created');

            // Generate KMS integration script
            this.generateKMSIntegration(treasuryKey);

            // Create security checklist
            this.generateSecurityChecklist();

            // Remove plain text key (security measure)
            console.log('⚠️  Original plaintext key should be moved to secure storage');
            console.log('   File location:', treasuryKeyPath);

            return {
                success: true,
                keyReference: this.kmsReferences.treasury_private_key_ref,
                backupPath: backupPath,
                encryptedKey: encryptedKey.keyId
            };

        } catch (error) {
            console.error('❌ Error securing treasury key:', error.message);
            throw error;
        }
    }

    /**
     * Encrypt private key for secure storage
     */
    encryptKey(privateKey) {
        const keyId = crypto.randomUUID();
        const encryptionKey = crypto.randomBytes(32);
        const iv = crypto.randomBytes(16);
        
        const cipher = crypto.createCipheriv('aes-256-cbc', encryptionKey, iv);
        
        let encrypted = cipher.update(privateKey, 'utf8', 'hex');
        encrypted += cipher.final('hex');

        return {
            keyId: keyId,
            encrypted: encrypted,
            iv: iv.toString('hex'),
            encryptionKey: encryptionKey.toString('hex'), // Store for backup decryption
            algorithm: 'aes-256-cbc',
            created: new Date().toISOString(),
            reference: this.kmsReferences.treasury_private_key_ref,
            note: 'Encrypted for secure backup storage - use KMS for production'
        };
    }

    /**
     * Generate KMS integration code
     */
    generateKMSIntegration(treasuryKey) {
        const kmsCode = `/**
 * KMS Integration for Treasury Key Management
 * 
 * Implementation for AWS KMS, Azure Key Vault, or Google Cloud KMS
 */

class TreasuryKeyManager {
    constructor(kmsProvider = 'aws') {
        this.kmsProvider = kmsProvider;
        this.keyReference = '${this.kmsReferences.treasury_private_key_ref}';
        this.accountId = '${this.kmsReferences.treasury_account_id}';
    }

    /**
     * AWS KMS Implementation
     */
    async getKeyFromAWSKMS() {
        const AWS = require('aws-sdk');
        const kms = new AWS.KMS({
            region: process.env.AWS_REGION || 'us-east-1'
        });

        try {
            const params = {
                KeyId: this.keyReference,
                EncryptionContext: {
                    'treasury-account': this.accountId,
                    'token-id': '${this.deploymentReceipts.token_id}',
                    'network': 'mainnet'
                }
            };

            const result = await kms.decrypt(params).promise();
            return result.Plaintext.toString();

        } catch (error) {
            console.error('KMS decryption failed:', error);
            throw new Error('Treasury key access denied');
        }
    }

    /**
     * Azure Key Vault Implementation
     */
    async getKeyFromAzureKV() {
        const { SecretClient } = require('@azure/keyvault-secrets');
        const { DefaultAzureCredential } = require('@azure/identity');

        const credential = new DefaultAzureCredential();
        const vaultName = process.env.AZURE_KEY_VAULT_NAME;
        const url = \`https://\${vaultName}.vault.azure.net\`;

        const client = new SecretClient(url, credential);

        try {
            const secret = await client.getSecret(this.keyReference);
            return secret.value;

        } catch (error) {
            console.error('Azure Key Vault access failed:', error);
            throw new Error('Treasury key access denied');
        }
    }

    /**
     * Get treasury private key securely
     */
    async getTreasuryPrivateKey() {
        // Environment check
        if (!process.env.KMS_ENABLED || process.env.NODE_ENV !== 'production') {
            console.warn('⚠️  Using fallback key access for development');
            return process.env.TREASURY_PRIVATE_KEY;
        }

        // Production KMS access
        switch (this.kmsProvider) {
            case 'aws':
                return await this.getKeyFromAWSKMS();
            case 'azure':
                return await this.getKeyFromAzureKV();
            default:
                throw new Error('KMS provider not configured');
        }
    }

    /**
     * Rotate treasury key (90-day policy)
     */
    async rotateKey() {
        console.log('🔄 Initiating key rotation...');
        
        // Generate new key pair
        const { PrivateKey } = require('@hashgraph/sdk');
        const newPrivateKey = PrivateKey.generate();
        const newPublicKey = newPrivateKey.publicKey;

        // Store new key in KMS
        await this.storeNewKeyInKMS(newPrivateKey.toString());

        // Update Hedera account key
        await this.updateHederaAccountKey(newPublicKey);

        console.log('✅ Key rotation completed');
        console.log('New public key:', newPublicKey.toString());

        return {
            rotated: true,
            newKeyReference: this.keyReference + '-rotated-' + Date.now(),
            publicKey: newPublicKey.toString()
        };
    }
}

module.exports = TreasuryKeyManager;
`;

        fs.writeFileSync(
            path.join(__dirname, 'treasury-key-manager.js'),
            kmsCode
        );

        console.log('✅ KMS integration code generated');
    }

    /**
     * Generate security checklist
     */
    generateSecurityChecklist() {
        const checklist = {
            timestamp: new Date().toISOString(),
            treasury_account: this.kmsReferences.treasury_account_id,
            token_id: this.deploymentReceipts.token_id,
            
            security_requirements: {
                key_management: [
                    "✅ Treasury private key generated securely",
                    "⏳ Move private key to KMS/HSM storage",
                    "⏳ Configure key rotation policy (90 days)",
                    "⏳ Set up backup recovery procedures",
                    "⏳ Implement multi-signature controls"
                ],
                
                access_controls: [
                    "⏳ Configure role-based access (RBAC)",
                    "⏳ Set up audit logging for key usage",
                    "⏳ Implement IP whitelist for KMS access",
                    "⏳ Configure emergency recovery procedures",
                    "⏳ Set up monitoring and alerting"
                ],

                operational_security: [
                    "⏳ Create incident response procedures",
                    "⏳ Set up automated backup verification",
                    "⏳ Configure transaction signing controls",
                    "⏳ Implement fraud detection monitoring",
                    "⏳ Create security audit schedule"
                ],

                compliance: [
                    "⏳ Document security architecture",
                    "⏳ Create compliance audit trail",
                    "⏳ Implement regulatory reporting",
                    "⏳ Set up data retention policies",
                    "⏳ Create incident documentation"
                ]
            },

            kms_configuration: {
                key_reference: this.kmsReferences.treasury_private_key_ref,
                rotation_policy: this.kmsReferences.key_rotation_policy,
                backup_locations: this.kmsReferences.backup_locations,
                public_key: this.kmsReferences.treasury_public_key
            },

            next_steps: [
                "1. Move treasury private key to KMS/HSM",
                "2. Configure production KMS credentials", 
                "3. Test key retrieval and signing",
                "4. Set up monitoring and alerting",
                "5. Create emergency recovery procedures",
                "6. Schedule security audit"
            ]
        };

        fs.writeFileSync(
            path.join(__dirname, 'security-checklist.json'),
            JSON.stringify(checklist, null, 2)
        );

        console.log('✅ Security checklist generated');
    }

    /**
     * Main setup execution
     */
    async execute() {
        console.log('🚀 MAINNET KMS SECURITY SETUP');
        console.log('=============================');
        console.log('Treasury Account:', this.kmsReferences.treasury_account_id);
        console.log('Token ID:', this.deploymentReceipts.token_id);
        console.log('');

        try {
            // Secure treasury key
            const keyResult = await this.secureTreasuryKey();

            // Generate environment template
            this.generateEnvTemplate();

            // Create deployment guide
            this.generateDeploymentGuide();

            console.log('');
            console.log('📊 KMS SECURITY SETUP COMPLETE');
            console.log('==============================');
            console.log('');
            console.log('🔑 Key Management:');
            console.log('   Reference ID:', keyResult.keyReference);
            console.log('   Encrypted Backup:', keyResult.backupPath);
            console.log('');
            console.log('📁 Generated Files:');
            console.log('   ✅ treasury-key-manager.js (KMS integration)');
            console.log('   ✅ security-checklist.json (compliance)');
            console.log('   ✅ .env.production.template (config)');
            console.log('   ✅ kms-deployment-guide.md (instructions)');
            console.log('');
            console.log('🚨 CRITICAL NEXT STEPS:');
            console.log('   1. Move treasury_private_key.SECURE to KMS');
            console.log('   2. Configure production KMS credentials');
            console.log('   3. Test key retrieval before going live');
            console.log('   4. Set up monitoring and alerting');

            return keyResult;

        } catch (error) {
            console.error('❌ KMS setup failed:', error.message);
            throw error;
        }
    }

    /**
     * Generate production environment template
     */
    generateEnvTemplate() {
        const envTemplate = `# Production Environment Configuration for Mainnet CNE Token
# Copy to .env.production and configure with actual values

# Hedera Network Configuration
HEDERA_NETWORK=mainnet
HEDERA_ACCOUNT_ID=${this.deploymentReceipts.operator_account}
HEDERA_PRIVATE_KEY=YOUR_OPERATOR_PRIVATE_KEY

# Treasury Configuration (DO NOT PUT PRIVATE KEY HERE IN PRODUCTION)
TREASURY_ACCOUNT_ID=${this.kmsReferences.treasury_account_id}
CNE_TOKEN_ID=${this.deploymentReceipts.token_id}

# KMS Configuration
KMS_ENABLED=true
KMS_PROVIDER=aws|azure|gcp
TREASURY_PRIVATE_KEY=NOT_USED_WHEN_KMS_ENABLED

# AWS KMS (if using AWS)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_KEY
TREASURY_KMS_KEY_ID=${this.kmsReferences.treasury_private_key_ref}

# Azure Key Vault (if using Azure)
AZURE_KEY_VAULT_NAME=your-vault-name
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_ID=your-client-id
AZURE_CLIENT_SECRET=your-client-secret

# Security Settings
NODE_ENV=production
ENABLE_AUDIT_LOGGING=true
TRANSACTION_SIGNING_REQUIRED=true
RATE_LIMITING_ENABLED=true

# Monitoring
ENABLE_MONITORING=true
ALERT_WEBHOOK_URL=your-alert-webhook
LOG_LEVEL=info
`;

        fs.writeFileSync(
            path.join(__dirname, '.env.production.template'),
            envTemplate
        );

        console.log('✅ Production environment template generated');
    }

    /**
     * Generate deployment guide
     */
    generateDeploymentGuide() {
        const guide = `# KMS Deployment Guide for Mainnet CNE Token

## Overview
This guide covers the secure deployment of treasury key management for the mainnet CNE token using enterprise-grade Key Management Services.

## Treasury Details
- **Account ID**: ${this.kmsReferences.treasury_account_id}
- **Token ID**: ${this.deploymentReceipts.token_id}
- **Public Key**: ${this.kmsReferences.treasury_public_key}

## Security Architecture

### Key Management
1. **Primary Storage**: KMS/HSM for production treasury key
2. **Backup Storage**: Encrypted offline backup in secure facility
3. **Rotation Policy**: Automatic 90-day key rotation
4. **Access Control**: Multi-factor authentication required

### Implementation Steps

#### 1. KMS Provider Setup

**AWS KMS Option:**
\`\`\`bash
# Create KMS key
aws kms create-key --description "CNE Treasury Key ${this.kmsReferences.treasury_account_id}"

# Store treasury private key
aws kms encrypt --key-id alias/cne-treasury --plaintext "TREASURY_PRIVATE_KEY_HERE"
\`\`\`

**Azure Key Vault Option:**
\`\`\`bash
# Create key vault
az keyvault create --name cne-treasury-kv --resource-group cne-mainnet

# Store treasury key
az keyvault secret set --vault-name cne-treasury-kv --name treasury-key --value "PRIVATE_KEY"
\`\`\`

#### 2. Environment Configuration
1. Copy \`.env.production.template\` to \`.env.production\`
2. Configure KMS credentials
3. Test key retrieval with \`node test-kms-access.js\`

#### 3. Security Verification
\`\`\`javascript
// Test KMS integration
const keyManager = require('./treasury-key-manager');
const key = await keyManager.getTreasuryPrivateKey();
console.log('KMS access successful:', key ? 'YES' : 'NO');
\`\`\`

#### 4. Monitoring Setup
- Configure CloudWatch/Azure Monitor alerts
- Set up transaction signing logs
- Enable audit trail for key access
- Create incident response procedures

### Emergency Recovery
1. **Backup Key Location**: Check \`treasury_key_encrypted.backup\`
2. **Recovery Process**: Use backup decryption with master key
3. **Key Rotation**: Immediate rotation if compromise suspected
4. **Incident Response**: Follow security incident procedures

### Compliance Requirements
- All key access must be logged and audited
- Multi-signature required for large transactions
- Regular security assessments (quarterly)
- Backup verification (monthly)

## Production Deployment Checklist
- [ ] KMS provider configured and tested
- [ ] Treasury key moved from plaintext storage
- [ ] Backup procedures verified
- [ ] Monitoring and alerting active
- [ ] Incident response procedures documented
- [ ] Security audit completed
- [ ] Team training completed

## Support Contacts
- **Security Team**: security@coinnewsextra.tv
- **Operations**: ops@coinnewsextra.tv
- **Emergency**: +1-XXX-XXX-XXXX (24/7)

---
Generated: ${new Date().toISOString()}
Treasury Account: ${this.kmsReferences.treasury_account_id}
Token ID: ${this.deploymentReceipts.token_id}
`;

        fs.writeFileSync(
            path.join(__dirname, 'kms-deployment-guide.md'),
            guide
        );

        console.log('✅ KMS deployment guide generated');
    }
}

// Execute setup if called directly
if (require.main === module) {
    const setup = new KMSSecuritySetup();
    setup.execute()
        .then(result => {
            console.log('🎉 KMS setup completed successfully!');
            process.exit(0);
        })
        .catch(error => {
            console.error('💥 KMS setup failed:', error);
            process.exit(1);
        });
}

module.exports = KMSSecuritySetup;