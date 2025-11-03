/**
 * Testnet Balance Export for Mainnet Migration
 * 
 * This script exports comprehensive user balance data from Firebase
 * for secure migration to mainnet CNE tokens.
 */

const admin = require('firebase-admin');
const fs = require('fs');
const crypto = require('crypto');

class TestnetBalanceExporter {
    constructor() {
        // Initialize Firebase Admin if not already done
        if (!admin.apps.length) {
            admin.initializeApp();
        }

        this.db = admin.firestore();
        this.exportData = {
            metadata: {
                exportDate: new Date().toISOString(),
                exportVersion: '1.0.0',
                network: 'testnet',
                targetNetwork: 'mainnet',
                targetTokenId: '0.0.10007647'
            },
            users: [],
            totals: {
                userCount: 0,
                totalCNETokens: 0,
                totalPlayExtraTokens: 0,
                totalRewardsClaimed: 0
            }
        };
    }

    /**
     * Export all user balances from Firebase
     */
    async exportUserBalances() {
        console.log('📊 EXPORTING TESTNET BALANCES');
        console.log('=============================');

        try {
            // Get all users
            const usersSnapshot = await this.db.collection('users').get();
            console.log(`Found ${usersSnapshot.size} users to export`);

            for (const userDoc of usersSnapshot.docs) {
                const userId = userDoc.id;
                const userData = userDoc.data();

                console.log(`Processing user: ${userId}`);
                
                const userBalance = await this.getUserBalance(userId, userData);
                this.exportData.users.push(userBalance);
                
                // Update totals
                this.exportData.totals.userCount++;
                this.exportData.totals.totalCNETokens += userBalance.cneTokens;
                this.exportData.totals.totalPlayExtraTokens += userBalance.playExtraTokens;
                this.exportData.totals.totalRewardsClaimed += userBalance.totalRewardsClaimed;
            }

            // Generate export hash for integrity
            const exportHash = this.generateExportHash();
            this.exportData.metadata.exportHash = exportHash;

            console.log('');
            console.log('📈 EXPORT SUMMARY');
            console.log('================');
            console.log('Total Users:', this.exportData.totals.userCount);
            console.log('Total CNE Tokens:', this.exportData.totals.totalCNETokens.toLocaleString());
            console.log('Total Play Extra Tokens:', this.exportData.totals.totalPlayExtraTokens.toLocaleString());
            console.log('Total Rewards Claimed:', this.exportData.totals.totalRewardsClaimed.toLocaleString());

            return this.exportData;

        } catch (error) {
            console.error('❌ Balance export failed:', error);
            throw error;
        }
    }

    /**
     * Get comprehensive balance data for a single user
     */
    async getUserBalance(userId, userData) {
        const userBalance = {
            userId: userId,
            email: userData.email || null,
            hederaAccountId: userData.hederaAccountId || null,
            registrationDate: userData.createdAt || null,
            lastActive: userData.lastLoginAt || null,
            
            // Token balances
            cneTokens: 0,
            playExtraTokens: 0,
            
            // Reward history
            totalRewardsClaimed: 0,
            rewardHistory: [],
            
            // Game data
            dailySpinData: {},
            watchTimeMinutes: 0,
            
            // Verification
            isVerified: userData.isVerified || false,
            migrationEligible: true
        };

        try {
            // Get CNE token balance
            const cneBalance = await this.getCNEBalance(userId);
            userBalance.cneTokens = cneBalance;

            // Get Play Extra tokens
            const playExtraBalance = await this.getPlayExtraBalance(userId);
            userBalance.playExtraTokens = playExtraBalance;

            // Get reward history
            const rewardData = await this.getRewardHistory(userId);
            userBalance.totalRewardsClaimed = rewardData.total;
            userBalance.rewardHistory = rewardData.history;

            // Get daily spin data
            const spinData = await this.getDailySpinData(userId);
            userBalance.dailySpinData = spinData;

            // Get watch time data
            const watchData = await this.getWatchTimeData(userId);
            userBalance.watchTimeMinutes = watchData;

            // Check migration eligibility
            userBalance.migrationEligible = this.checkMigrationEligibility(userBalance);

        } catch (error) {
            console.warn(`⚠️  Error getting balance for user ${userId}:`, error.message);
            userBalance.migrationEligible = false;
            userBalance.errorNote = error.message;
        }

        return userBalance;
    }

    /**
     * Get CNE token balance from userTokens collection
     */
    async getCNEBalance(userId) {
        try {
            const tokenDoc = await this.db.collection('userTokens').doc(userId).get();
            if (!tokenDoc.exists) return 0;
            
            const tokenData = tokenDoc.data();
            return tokenData.cneTokens || 0;
        } catch (error) {
            console.warn(`CNE balance error for ${userId}:`, error.message);
            return 0;
        }
    }

    /**
     * Get Play Extra token balance
     */
    async getPlayExtraBalance(userId) {
        try {
            const tokenDoc = await this.db.collection('userTokens').doc(userId).get();
            if (!tokenDoc.exists) return 0;
            
            const tokenData = tokenDoc.data();
            return tokenData.playExtraTokens || 0;
        } catch (error) {
            console.warn(`Play Extra balance error for ${userId}:`, error.message);
            return 0;
        }
    }

    /**
     * Get comprehensive reward history
     */
    async getRewardHistory(userId) {
        try {
            const rewardsSnapshot = await this.db
                .collection('userRewards')
                .where('userId', '==', userId)
                .orderBy('timestamp', 'desc')
                .get();

            let total = 0;
            const history = [];

            rewardsSnapshot.forEach(doc => {
                const reward = doc.data();
                total += reward.amount || 0;
                
                history.push({
                    id: doc.id,
                    amount: reward.amount || 0,
                    type: reward.type || 'unknown',
                    timestamp: reward.timestamp,
                    source: reward.source || 'legacy'
                });
            });

            return { total, history: history.slice(0, 100) }; // Limit history size

        } catch (error) {
            console.warn(`Reward history error for ${userId}:`, error.message);
            return { total: 0, history: [] };
        }
    }

    /**
     * Get daily spin data
     */
    async getDailySpinData(userId) {
        try {
            const spinDoc = await this.db.collection('dailySpins').doc(userId).get();
            if (!spinDoc.exists) return {};
            
            return spinDoc.data();
        } catch (error) {
            console.warn(`Spin data error for ${userId}:`, error.message);
            return {};
        }
    }

    /**
     * Get watch time data
     */
    async getWatchTimeData(userId) {
        try {
            const watchDoc = await this.db.collection('watchTime').doc(userId).get();
            if (!watchDoc.exists) return 0;
            
            const watchData = watchDoc.data();
            return watchData.totalMinutes || 0;
        } catch (error) {
            console.warn(`Watch time error for ${userId}:`, error.message);
            return 0;
        }
    }

    /**
     * Check if user is eligible for migration
     */
    checkMigrationEligibility(userBalance) {
        // Basic eligibility criteria
        if (!userBalance.hederaAccountId) return false;
        if (userBalance.cneTokens < 0) return false;
        if (!userBalance.email) return false;
        
        return true;
    }

    /**
     * Generate hash for data integrity verification
     */
    generateExportHash() {
        const hashData = JSON.stringify({
            userCount: this.exportData.totals.userCount,
            totalCNE: this.exportData.totals.totalCNETokens,
            totalPlayExtra: this.exportData.totals.totalPlayExtraTokens,
            exportDate: this.exportData.metadata.exportDate
        });

        return crypto.createHash('sha256').update(hashData).digest('hex');
    }

    /**
     * Save export data to files
     */
    async saveExportData() {
        console.log('');
        console.log('💾 SAVING EXPORT DATA');
        console.log('=====================');

        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        
        // Save full export
        const fullExportPath = `testnet-balances-${timestamp}.json`;
        fs.writeFileSync(fullExportPath, JSON.stringify(this.exportData, null, 2));
        console.log('✅ Full export saved:', fullExportPath);

        // Save summary only
        const summaryPath = `balance-summary-${timestamp}.json`;
        const summary = {
            metadata: this.exportData.metadata,
            totals: this.exportData.totals,
            eligibleUsers: this.exportData.users.filter(u => u.migrationEligible).length,
            totalUsers: this.exportData.users.length
        };
        fs.writeFileSync(summaryPath, JSON.stringify(summary, null, 2));
        console.log('✅ Summary saved:', summaryPath);

        // Save migration-ready data (eligible users only)
        const migrationPath = `migration-ready-${timestamp}.json`;
        const migrationData = {
            ...this.exportData,
            users: this.exportData.users.filter(u => u.migrationEligible)
        };
        fs.writeFileSync(migrationPath, JSON.stringify(migrationData, null, 2));
        console.log('✅ Migration data saved:', migrationPath);

        return {
            fullExportPath,
            summaryPath,
            migrationPath,
            exportHash: this.exportData.metadata.exportHash
        };
    }

    /**
     * Execute full export process
     */
    async execute() {
        try {
            console.log('🚀 STARTING TESTNET BALANCE EXPORT');
            console.log('==================================');

            await this.exportUserBalances();
            const savedFiles = await this.saveExportData();

            console.log('');
            console.log('🎉 EXPORT COMPLETED SUCCESSFULLY');
            console.log('================================');
            console.log('Files generated:');
            console.log('  Full Export:', savedFiles.fullExportPath);
            console.log('  Summary:', savedFiles.summaryPath);
            console.log('  Migration Ready:', savedFiles.migrationPath);
            console.log('');
            console.log('Export Hash:', savedFiles.exportHash);
            console.log('Ready for Merkle tree generation');

            return savedFiles;

        } catch (error) {
            console.error('💥 Export failed:', error);
            throw error;
        }
    }
}

// Execute if called directly
if (require.main === module) {
    const exporter = new TestnetBalanceExporter();
    exporter.execute()
        .then(result => {
            console.log('Export completed successfully');
            process.exit(0);
        })
        .catch(error => {
            console.error('Export failed:', error);
            process.exit(1);
        });
}

module.exports = TestnetBalanceExporter;