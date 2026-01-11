# Hedera Account Generator - Web Interface

## Quick Access

**Local File**: [hedera-account-generator.html](hedera-account-generator.html)

**After Deployment**: `https://YOUR-PROJECT.web.app/hedera-account-generator.html`

---

## Features

🔐 **Generate Hedera Blockchain Accounts**
- Create 1-100 accounts per batch
- No email required
- Testnet (free) or Mainnet (real HBAR)

📊 **Real-time Tracking**
- Progress bar shows generation status
- Live logs display each account creation
- Statistics dashboard updates automatically

💾 **Export Options**
- Download as CSV for spreadsheets
- Download as JSON for programming
- Includes all account details

🌐 **Blockchain Integration**
- Direct links to HashScan explorer
- View accounts on public blockchain
- Track all transactions and balances

---

## How to Use

1. **Open the HTML file** in your browser
2. **Enter number** of accounts (1-100)
3. **Select network** (testnet/mainnet)
4. **Click "Generate Hedera Accounts"**
5. **Download results** as CSV or JSON

---

## Requirements

- Modern web browser (Chrome, Firefox, Edge)
- Internet connection (connects to Firebase)
- Hedera operator account configured in Firebase Functions

---

## Security Notice

⚠️ **Private Keys**: The generated private keys give full control of accounts. Download and store them securely!

**Best Practices:**
- Download immediately after generation
- Store in encrypted storage
- Never commit to version control
- Keep offline backups

---

## What Gets Created

Each account includes:

```json
{
  "accountId": "0.0.4506257",
  "publicKey": "302a300506032b6570032100...",
  "privateKey": "302e020100300506032b6570...",
  "did": "did:hedera:testnet:0.0.4506257_0.0.0",
  "network": "testnet",
  "explorerUrl": "https://hashscan.io/testnet/account/0.0.4506257"
}
```

---

## Blockchain Explorers

View your accounts on:
- **HashScan**: https://hashscan.io/
- **Ledger Works**: https://ledgerworks.io/
- **DragonGlass**: https://app.dragonglass.me/

---

## Support

For detailed documentation, see:
- [HEDERA_ACCOUNT_GENERATOR_GUIDE.md](../../HEDERA_ACCOUNT_GENERATOR_GUIDE.md)
- [HEDERA_QUICK_START.md](../../HEDERA_QUICK_START.md)

---

**Happy generating! 🚀**
