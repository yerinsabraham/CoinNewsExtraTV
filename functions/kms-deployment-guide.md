# KMS Deployment Guide for Mainnet CNE Token

## Overview
This guide covers the secure deployment of treasury key management for the mainnet CNE token using enterprise-grade Key Management Services.

## Treasury Details
- **Account ID**: 0.0.10007646
- **Token ID**: 0.0.10007647
- **Public Key**: cc9cad78ef35aff4560dd51da3f7f8a2c1bdb6ba5ce009b1825eec271d22c44f

## Security Architecture

### Key Management
1. **Primary Storage**: KMS/HSM for production treasury key
2. **Backup Storage**: Encrypted offline backup in secure facility
3. **Rotation Policy**: Automatic 90-day key rotation
4. **Access Control**: Multi-factor authentication required

### Implementation Steps

#### 1. KMS Provider Setup

**AWS KMS Option:**
```bash
# Create KMS key
aws kms create-key --description "CNE Treasury Key 0.0.10007646"

# Store treasury private key
aws kms encrypt --key-id alias/cne-treasury --plaintext "TREASURY_PRIVATE_KEY_HERE"
```

**Azure Key Vault Option:**
```bash
# Create key vault
az keyvault create --name cne-treasury-kv --resource-group cne-mainnet

# Store treasury key
az keyvault secret set --vault-name cne-treasury-kv --name treasury-key --value "PRIVATE_KEY"
```

#### 2. Environment Configuration
1. Copy `.env.production.template` to `.env.production`
2. Configure KMS credentials
3. Test key retrieval with `node test-kms-access.js`

#### 3. Security Verification
```javascript
// Test KMS integration
const keyManager = require('./treasury-key-manager');
const key = await keyManager.getTreasuryPrivateKey();
console.log('KMS access successful:', key ? 'YES' : 'NO');
```

#### 4. Monitoring Setup
- Configure CloudWatch/Azure Monitor alerts
- Set up transaction signing logs
- Enable audit trail for key access
- Create incident response procedures

### Emergency Recovery
1. **Backup Key Location**: Check `treasury_key_encrypted.backup`
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
Generated: 2025-09-30T17:04:37.325Z
Treasury Account: 0.0.10007646
Token ID: 0.0.10007647
