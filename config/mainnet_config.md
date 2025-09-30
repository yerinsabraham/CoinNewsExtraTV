# Mainnet Configuration File
# CNE Token Reward System - Production Environment

## Environment Variables for Mainnet Deployment

### Hedera Mainnet Configuration
```bash
# Hedera Network
HEDERA_NETWORK=mainnet
APP_ENV=mainnet

# Operator Account (Production)
HEDERA_MAINNET_OPERATOR_ID=[TO_BE_SET]
HEDERA_MAINNET_OPERATOR_KEY=[TO_BE_SET]

# Pool Treasury Account (Production)
POOL_MAINNET_ACCOUNT_ID=[TO_BE_SET]
POOL_MAINNET_PRIVATE_KEY=[TO_BE_SET]

# Token and Contract IDs (Production)
CNE_MAINNET_TOKEN_ID=[TO_BE_DEPLOYED]
HCS_MAINNET_TOPIC_ID=[TO_BE_DEPLOYED]
REWARD_CONTRACT_MAINNET_ID=[TO_BE_DEPLOYED]
STAKING_CONTRACT_MAINNET_ID=[TO_BE_DEPLOYED]
DID_REGISTRY_MAINNET_ID=[TO_BE_DEPLOYED]

# Mirror Node (Production)
MIRROR_NODE_MAINNET_URL=https://mainnet-public.mirrornode.hedera.com

# Firebase Configuration (Production)
FIREBASE_PROJECT_ID=coinnewsextra-tv-prod
FIREBASE_REGION=us-central1
```

### Smart Contract Deployment Steps

1. **Deploy CNE Token Contract**
   ```bash
   # Using Hedera SDK
   node scripts/deploy-cne-token.js --network mainnet
   ```

2. **Deploy Reward Distribution Contract**
   ```bash
   node scripts/deploy-reward-contract.js --network mainnet
   ```

3. **Deploy DID Registry Contract**
   ```bash
   node scripts/deploy-did-registry.js --network mainnet
   ```

4. **Verify All Contracts**
   ```bash
   # Verify on Hedera Explorer
   node scripts/verify-contracts.js --network mainnet
   ```

### Security Configuration

```yaml
# Production Security Settings
ENABLE_RATE_LIMITING: true
ENABLE_FRAUD_DETECTION: true
ENABLE_DID_VERIFICATION: true
ENABLE_AUDIT_LOGGING: true
ENABLE_BIOMETRIC_AUTH: true

# Rate Limits (Production)
MAX_DAILY_CLAIMS_PER_USER: 50
MAX_CLAIMS_PER_MINUTE: 5
MAX_FAILED_ATTEMPTS: 10

# Gas Configuration (Production)
GAS_LIMIT: 3000000
GAS_PRICE: 30  # gwei

# Session Configuration
SESSION_TIMEOUT: 1800000  # 30 minutes
PIN_CERTIFICATE: true
DEBUG_LOGS: false
```

### Database Configuration

```yaml
# Firestore Production
firestore:
  project: coinnewsextra-tv-prod
  databaseId: default
  region: us-central1
  
# Collection Structure
collections:
  - users
  - security_logs
  - security_violations
  - user_devices
  - reward_claims
  - did_documents
  - audit_trails
```

### CDN and Performance

```yaml
# Content Delivery Network
cdn:
  provider: firebase-hosting
  domains:
    - app.coinnewsextra.tv
    - api.coinnewsextra.tv
  ssl: true
  compression: true
  
# Performance Optimization
caching:
  static_assets: 31536000  # 1 year
  api_responses: 300       # 5 minutes
  did_documents: 3600      # 1 hour
```

### Monitoring Configuration

```yaml
# Application Performance Monitoring
monitoring:
  firebase_performance: true
  crashlytics: true
  analytics: true
  
# Custom Metrics
custom_metrics:
  - reward_claim_success_rate
  - did_verification_success_rate
  - smart_contract_success_rate
  - security_violation_rate
  - user_engagement_rate

# Alerts
alerts:
  - error_rate_threshold: 1%
  - response_time_threshold: 2000ms
  - security_violations_threshold: 10/hour
  - failed_claims_threshold: 5%
```

### Backup and Recovery

```yaml
# Backup Strategy
backup:
  firestore:
    frequency: daily
    retention: 30_days
    location: us-central1
    
  user_keys:
    frequency: realtime
    encryption: aes-256
    retention: indefinite
    
  audit_logs:
    frequency: hourly
    retention: 7_years
    compliance: required
```

### Legal and Compliance

```yaml
# Compliance Configuration
compliance:
  gdpr: enabled
  ccpa: enabled
  data_retention: 
    user_data: 7_years
    logs: 7_years
    analytics: 2_years
  
  privacy:
    data_encryption: required
    user_consent: required
    data_portability: enabled
    right_to_deletion: enabled
```

## Deployment Checklist

### Pre-Deployment
- [ ] External security audit completed
- [ ] Smart contracts audited by certified firm
- [ ] Load testing completed on mainnet mirror
- [ ] Legal review and compliance verification
- [ ] Insurance and risk assessment
- [ ] Team training on production procedures

### Deployment Steps
1. [ ] Create production Firebase project
2. [ ] Deploy smart contracts to Hedera mainnet
3. [ ] Verify all contracts on explorer
4. [ ] Update app configuration for mainnet
5. [ ] Deploy Firebase Functions to production
6. [ ] Configure monitoring and alerting
7. [ ] Run final integration tests
8. [ ] Execute soft launch with limited users
9. [ ] Monitor for 48 hours before full launch
10. [ ] Full public launch announcement

### Post-Deployment
- [ ] 24/7 monitoring for first 7 days
- [ ] Daily performance reports
- [ ] Weekly security reviews
- [ ] Monthly compliance audits
- [ ] Quarterly external security assessment

## Emergency Procedures

### Circuit Breaker Conditions
- Error rate > 5%
- Security violations > 100/hour
- Smart contract failures > 10%
- DID verification failures > 20%

### Emergency Contacts
- Technical Lead: [CONTACT_INFO]
- Security Team: [CONTACT_INFO]
- DevOps Team: [CONTACT_INFO]
- Legal Team: [CONTACT_INFO]
- Executive Team: [CONTACT_INFO]

### Rollback Procedures
1. Disable new user registrations
2. Stop reward processing
3. Activate maintenance mode
4. Rollback to previous stable version
5. Investigate and fix issues
6. Gradual re-enable services

## Success Metrics

### Technical KPIs
- 99.9% uptime
- < 2s average response time
- < 0.1% error rate
- 100% security audit compliance

### Business KPIs
- Daily active users
- Reward claim success rate
- User retention rate
- Revenue per user
- Customer satisfaction score

---

**Configuration Version:** 1.0  
**Environment:** Production/Mainnet  
**Last Updated:** September 30, 2025  
**Next Review:** Post-launch + 7 days
