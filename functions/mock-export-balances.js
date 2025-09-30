/**
 * Mock Balance Export for Mainnet Migration Testing
 * 
 * This creates a simulated export based on the app's data structure
 * for testing the migration process without Firebase credentials.
 */

const fs = require('fs');
const crypto = require('crypto');

class MockBalanceExporter {
    constructor() {
        this.exportData = {
            metadata: {
                exportDate: new Date().toISOString(),
                exportVersion: '1.0.0',
                network: 'testnet',
                targetNetwork: 'mainnet',
                targetTokenId: '0.0.10007647',
                note: 'Mock export for migration testing'
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
     * Generate mock user data based on realistic app usage patterns
     */
    generateMockUsers() {
        console.log('📊 GENERATING MOCK TESTNET BALANCES');
        console.log('===================================');

        // Mock user data patterns
        const mockUsers = [
            {
                userId: 'user_001_active_player',
                email: 'player1@example.com',
                hederaAccountId: '0.0.1234567',
                cneTokens: 15000,
                playExtraTokens: 2500,
                totalRewardsClaimed: 12000,
                registrationDate: '2024-06-01T00:00:00.000Z',
                isVerified: true,
                watchTimeMinutes: 4800
            },
            {
                userId: 'user_002_moderate_user',
                email: 'player2@example.com',
                hederaAccountId: '0.0.2345678',
                cneTokens: 8500,
                playExtraTokens: 1200,
                totalRewardsClaimed: 7200,
                registrationDate: '2024-07-15T00:00:00.000Z',
                isVerified: true,
                watchTimeMinutes: 2400
            },
            {
                userId: 'user_003_new_player',
                email: 'newbie@example.com',
                hederaAccountId: '0.0.3456789',
                cneTokens: 2000,
                playExtraTokens: 500,
                totalRewardsClaimed: 1500,
                registrationDate: '2024-09-01T00:00:00.000Z',
                isVerified: true,
                watchTimeMinutes: 600
            },
            {
                userId: 'user_004_unverified',
                email: 'unverified@example.com',
                hederaAccountId: null, // No Hedera account
                cneTokens: 500,
                playExtraTokens: 100,
                totalRewardsClaimed: 300,
                registrationDate: '2024-09-20T00:00:00.000Z',
                isVerified: false,
                watchTimeMinutes: 120
            },
            {
                userId: 'user_005_power_user',
                email: 'poweruser@example.com',
                hederaAccountId: '0.0.4567890',
                cneTokens: 45000,
                playExtraTokens: 8500,
                totalRewardsClaimed: 38000,
                registrationDate: '2024-05-01T00:00:00.000Z',
                isVerified: true,
                watchTimeMinutes: 12000
            }
        ];

        for (const mockUser of mockUsers) {
            const userBalance = {
                userId: mockUser.userId,
                email: mockUser.email,
                hederaAccountId: mockUser.hederaAccountId,
                registrationDate: mockUser.registrationDate,
                lastActive: new Date().toISOString(),
                
                // Token balances
                cneTokens: mockUser.cneTokens,
                playExtraTokens: mockUser.playExtraTokens,
                
                // Reward history
                totalRewardsClaimed: mockUser.totalRewardsClaimed,
                rewardHistory: this.generateMockRewardHistory(mockUser.totalRewardsClaimed),
                
                // Game data
                dailySpinData: this.generateMockSpinData(),
                watchTimeMinutes: mockUser.watchTimeMinutes,
                
                // Verification
                isVerified: mockUser.isVerified,
                migrationEligible: this.checkMigrationEligibility(mockUser)
            };

            this.exportData.users.push(userBalance);
            
            // Update totals
            this.exportData.totals.userCount++;
            this.exportData.totals.totalCNETokens += userBalance.cneTokens;
            this.exportData.totals.totalPlayExtraTokens += userBalance.playExtraTokens;
            this.exportData.totals.totalRewardsClaimed += userBalance.totalRewardsClaimed;

            console.log(`Generated user: ${mockUser.userId} (CNE: ${mockUser.cneTokens})`);
        }
    }

    /**
     * Generate mock reward history
     */
    generateMockRewardHistory(totalRewards) {
        const history = [];
        const rewardTypes = ['daily_spin', 'watch_time', 'referral', 'bonus'];
        let remaining = totalRewards;
        let historyCount = Math.min(20, Math.floor(totalRewards / 100)); // Reasonable history size

        for (let i = 0; i < historyCount && remaining > 0; i++) {
            const amount = Math.min(remaining, Math.floor(Math.random() * 1000) + 50);
            remaining -= amount;

            history.push({
                id: `reward_${Date.now()}_${i}`,
                amount: amount,
                type: rewardTypes[Math.floor(Math.random() * rewardTypes.length)],
                timestamp: new Date(Date.now() - i * 24 * 60 * 60 * 1000).toISOString(),
                source: 'testnet_app'
            });
        }

        return history;
    }

    /**
     * Generate mock daily spin data
     */
    generateMockSpinData() {
        const today = new Date().toISOString().split('T')[0];
        return {
            [today]: {
                spinsUsed: Math.floor(Math.random() * 5),
                maxSpins: 5,
                lastSpinTime: new Date().toISOString()
            }
        };
    }

    /**
     * Check migration eligibility
     */
    checkMigrationEligibility(user) {
        return user.hederaAccountId !== null && 
               user.isVerified && 
               user.cneTokens >= 0;
    }

    /**
     * Generate export hash
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
     * Save mock export data
     */
    async saveExportData() {
        console.log('');
        console.log('💾 SAVING MOCK EXPORT DATA');
        console.log('==========================');

        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        
        // Add export hash
        this.exportData.metadata.exportHash = this.generateExportHash();

        // Save full export
        const fullExportPath = `mock-testnet-balances-${timestamp}.json`;
        fs.writeFileSync(fullExportPath, JSON.stringify(this.exportData, null, 2));
        console.log('✅ Mock export saved:', fullExportPath);

        // Save summary
        const summaryPath = `mock-balance-summary-${timestamp}.json`;
        const summary = {
            metadata: this.exportData.metadata,
            totals: this.exportData.totals,
            eligibleUsers: this.exportData.users.filter(u => u.migrationEligible).length,
            totalUsers: this.exportData.users.length
        };
        fs.writeFileSync(summaryPath, JSON.stringify(summary, null, 2));
        console.log('✅ Summary saved:', summaryPath);

        // Save migration-ready data
        const migrationPath = `mock-migration-ready-${timestamp}.json`;
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
     * Execute mock export
     */
    async execute() {
        console.log('🚀 STARTING MOCK TESTNET BALANCE EXPORT');
        console.log('=======================================');

        this.generateMockUsers();
        const savedFiles = await this.saveExportData();

        console.log('');
        console.log('📈 MOCK EXPORT SUMMARY');
        console.log('======================');
        console.log('Total Users:', this.exportData.totals.userCount);
        console.log('Total CNE Tokens:', this.exportData.totals.totalCNETokens.toLocaleString());
        console.log('Total Play Extra Tokens:', this.exportData.totals.totalPlayExtraTokens.toLocaleString());
        console.log('Total Rewards Claimed:', this.exportData.totals.totalRewardsClaimed.toLocaleString());
        console.log('Eligible for Migration:', this.exportData.users.filter(u => u.migrationEligible).length);

        console.log('');
        console.log('🎉 MOCK EXPORT COMPLETED SUCCESSFULLY');
        console.log('=====================================');
        console.log('Files generated:');
        console.log('  Full Export:', savedFiles.fullExportPath);
        console.log('  Summary:', savedFiles.summaryPath);
        console.log('  Migration Ready:', savedFiles.migrationPath);
        console.log('');
        console.log('Export Hash:', savedFiles.exportHash);
        console.log('Ready for Merkle tree generation');

        return savedFiles;
    }
}

// Execute if called directly
if (require.main === module) {
    const exporter = new MockBalanceExporter();
    exporter.execute()
        .then(result => {
            console.log('Mock export completed successfully');
            process.exit(0);
        })
        .catch(error => {
            console.error('Mock export failed:', error);
            process.exit(1);
        });
}

module.exports = MockBalanceExporter;