# 🚀 MAINNET MIGRATION CHECKLIST

## Phase 1: Pre-Migration Setup ✅

### 1.1 Token Creation (MANUAL - USER ACTION REQUIRED)
- [ ] **Create mainnet CNE token in HashPack**
  - Token Name: `CoinNewsExtra Token`
  - Symbol: `CNE`
  - Decimals: `8`
  - Supply Type: `INFINITE`
  - Initial Supply: `0`
  - Save Token ID: `0.0.________` ← **FILL THIS IN**

### 1.2 Account Setup
- [ ] **Treasury Account**: Ensure sufficient HBAR for transactions
- [ ] **Backup Keys**: Secure storage of all private keys
- [ ] **Multi-sig Setup** (recommended for production)

### 1.3 Data Backup
- [ ] **Run backup script**: `node scripts/backup-user-data.js`
- [ ] **Verify backup file** created successfully
- [ ] **Store backup securely** (multiple locations)

---

## Phase 2: Configuration Updates (AUTOMATED)

### 2.1 Environment Variables
- [ ] Update Firebase environment variables
- [ ] Update Hedera configuration
- [ ] Update token ID references

### 2.2 App Configuration  
- [ ] Update Flutter app constants
- [ ] Update Cloud Functions configuration
- [ ] Update Firestore security rules if needed

---

## Phase 3: Migration Execution

### 3.1 Pre-Migration Checks
- [ ] **Verify token creation** on HashScan
- [ ] **Test token transfers** with small amounts
- [ ] **Validate treasury account** access

### 3.2 User Balance Migration
- [ ] **Pause reward system** temporarily
- [ ] **Export current balances** from backup
- [ ] **Import balances** to mainnet system
- [ ] **Verify balance accuracy**

### 3.3 System Validation
- [ ] **Test reward functions** with pilot users
- [ ] **Verify token transfers** work correctly
- [ ] **Check audit logging** to HCS

---

## Phase 4: Go-Live

### 4.1 Deployment
- [ ] **Deploy updated Cloud Functions**
- [ ] **Deploy updated Flutter app**
- [ ] **Resume reward system**

### 4.2 Monitoring
- [ ] **Monitor system health** for 24 hours
- [ ] **Check user feedback** and support tickets
- [ ] **Verify transaction logs**

---

## Emergency Rollback Plan

If issues arise:
1. **Pause mainnet system** immediately
2. **Restore testnet configuration**
3. **Restore user balances** from backup
4. **Investigate and fix issues**
5. **Re-attempt migration** when ready

---

## Manual Actions Required From User

### 🔴 **IMMEDIATE ACTION NEEDED**
1. **Create mainnet CNE token** using HashPack with these specifications:
   ```
   Token Name: CoinNewsExtra Token
   Symbol: CNE
   Decimals: 8
   Supply Type: INFINITE
   Initial Supply: 0
   Treasury Account: [Your Hedera account]
   Admin Key: [Your private key]
   Supply Key: [Your private key]
   ```

2. **Provide the new Token ID** (format: 0.0.XXXXXXX)

3. **Run these commands** in order:
   ```bash
   # 1. Create backup
   node scripts/backup-user-data.js
   
   # 2. Update configuration (replace TOKEN_ID with your new token)
   node scripts/update-mainnet-config.js 0.0.TOKEN_ID
   
   # 3. Validate everything
   node scripts/validate-migration.js
   
   # 4. Deploy to mainnet
   node scripts/deploy-mainnet.js deploy
   ```

### 🟡 **VERIFICATION STEPS**
1. **Check token on HashScan**: `https://hashscan.io/mainnet/token/0.0.TOKEN_ID`
2. **Test small token transfer** to verify functionality
3. **Monitor first few user transactions**

### 🆘 **EMERGENCY ROLLBACK** (if needed)
```bash
node scripts/deploy-mainnet.js rollback
```

---

**Status**: ⏳ Waiting for mainnet token creation
**Next Step**: Create token in HashPack and provide Token ID

**Scripts Ready**: ✅ All migration scripts created and ready to execute
