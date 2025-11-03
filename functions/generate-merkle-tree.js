/**
 * Merkle Tree Generator for Mainnet Migration
 * 
 * This script creates a cryptographic Merkle tree of all user balances,
 * publishes the root hash to Hedera Consensus Service for immutable audit trail,
 * and generates proof files for balance verification.
 */

const crypto = require('crypto');
const fs = require('fs');
const { 
    Client, 
    AccountId, 
    PrivateKey, 
    TopicMessageSubmitTransaction,
    TopicId,
    Hbar 
} = require("@hashgraph/sdk");

class MerkleTreeGenerator {
    constructor() {
        this.migrationData = null;
        this.merkleTree = null;
        this.proofs = new Map();
        
        // Hedera configuration
        this.client = null;
        this.auditTopicId = "0.0.10007691"; // HCS topic for mainnet migration audit logs
        
        this.config = {
            hashAlgorithm: 'sha256',
            leafPrefix: 'BALANCE:',
            rootPrefix: 'MERKLE_ROOT:',
            version: '1.0.0'
        };
    }

    /**
     * Initialize Hedera client for HCS publishing
     */
    initializeHederaClient() {
        const accountId = AccountId.fromString(process.env.HEDERA_ACCOUNT_ID || "0.0.9764298");
        const privateKey = PrivateKey.fromString(process.env.HEDERA_PRIVATE_KEY);
        
        this.client = Client.forMainnet().setOperator(accountId, privateKey);
        console.log('✅ Hedera client initialized for HCS publishing');
    }

    /**
     * Load migration data from the most recent export
     */
    loadMigrationData() {
        console.log('📂 LOADING MIGRATION DATA');
        console.log('=========================');

        try {
            // Find the most recent migration file
            const files = fs.readdirSync('.');
            const migrationFiles = files.filter(f => f.startsWith('mock-migration-ready-'));
            
            if (migrationFiles.length === 0) {
                throw new Error('No migration data files found');
            }

            // Get the most recent file
            const latestFile = migrationFiles.sort().pop();
            console.log('📄 Loading file:', latestFile);

            const rawData = fs.readFileSync(latestFile, 'utf8');
            this.migrationData = JSON.parse(rawData);

            console.log('✅ Migration data loaded');
            console.log('   Users eligible for migration:', this.migrationData.users.length);
            console.log('   Total CNE tokens:', this.migrationData.totals.totalCNETokens.toLocaleString());
            console.log('   Export hash:', this.migrationData.metadata.exportHash);

            return this.migrationData;

        } catch (error) {
            console.error('❌ Failed to load migration data:', error.message);
            throw error;
        }
    }

    /**
     * Create leaf nodes for the Merkle tree
     */
    createLeafNodes() {
        console.log('');
        console.log('🌱 CREATING MERKLE TREE LEAF NODES');
        console.log('==================================');

        const leafNodes = [];

        for (const user of this.migrationData.users) {
            // Create standardized balance record for hashing
            const balanceRecord = {
                userId: user.userId,
                hederaAccountId: user.hederaAccountId,
                cneTokens: user.cneTokens,
                playExtraTokens: user.playExtraTokens,
                totalRewardsClaimed: user.totalRewardsClaimed,
                migrationEligible: user.migrationEligible,
                timestamp: this.migrationData.metadata.exportDate
            };

            // Create deterministic hash
            const recordString = this.config.leafPrefix + JSON.stringify(balanceRecord, Object.keys(balanceRecord).sort());
            const leafHash = crypto.createHash(this.config.hashAlgorithm).update(recordString).digest('hex');

            leafNodes.push({
                hash: leafHash,
                data: balanceRecord,
                originalData: user
            });

            console.log(`✅ Leaf created for ${user.userId}: ${leafHash.substring(0, 16)}...`);
        }

        console.log('');
        console.log(`📊 Created ${leafNodes.length} leaf nodes`);
        return leafNodes;
    }

    /**
     * Build the complete Merkle tree
     */
    buildMerkleTree(leafNodes) {
        console.log('');
        console.log('🌳 BUILDING MERKLE TREE');
        console.log('=======================');

        let currentLevel = leafNodes.map(leaf => ({
            hash: leaf.hash,
            isLeaf: true,
            data: leaf.data,
            originalData: leaf.originalData
        }));

        const tree = {
            levels: [currentLevel],
            root: null,
            depth: 0
        };

        let level = 0;
        console.log(`Level ${level}: ${currentLevel.length} nodes`);

        // Build tree bottom-up
        while (currentLevel.length > 1) {
            const nextLevel = [];
            
            // Process pairs of nodes
            for (let i = 0; i < currentLevel.length; i += 2) {
                const left = currentLevel[i];
                const right = currentLevel[i + 1] || left; // Duplicate if odd number

                // Create parent node hash
                const combinedHash = left.hash + right.hash;
                const parentHash = crypto.createHash(this.config.hashAlgorithm).update(combinedHash).digest('hex');

                nextLevel.push({
                    hash: parentHash,
                    left: left,
                    right: right !== left ? right : null, // null if duplicated
                    isLeaf: false
                });
            }

            currentLevel = nextLevel;
            level++;
            tree.levels.push(currentLevel);
            console.log(`Level ${level}: ${currentLevel.length} nodes`);
        }

        tree.root = currentLevel[0];
        tree.depth = level;

        console.log('');
        console.log('✅ Merkle tree construction complete');
        console.log('   Tree depth:', tree.depth);
        console.log('   Root hash:', tree.root.hash);

        this.merkleTree = tree;
        return tree;
    }

    /**
     * Generate Merkle proofs for all users
     */
    generateMerkleProofs() {
        console.log('');
        console.log('🔐 GENERATING MERKLE PROOFS');
        console.log('===========================');

        const leafLevel = this.merkleTree.levels[0];
        
        for (let leafIndex = 0; leafIndex < leafLevel.length; leafIndex++) {
            const leaf = leafLevel[leafIndex];
            const proof = this.generateProofForLeaf(leafIndex);
            
            this.proofs.set(leaf.data.userId, {
                leafIndex: leafIndex,
                leafHash: leaf.hash,
                proof: proof,
                userData: leaf.originalData
            });

            console.log(`✅ Proof generated for ${leaf.data.userId}`);
        }

        console.log('');
        console.log(`📊 Generated ${this.proofs.size} Merkle proofs`);
        return this.proofs;
    }

    /**
     * Generate proof path for a specific leaf
     */
    generateProofForLeaf(leafIndex) {
        const proof = [];
        let currentIndex = leafIndex;

        // Traverse from leaf to root
        for (let level = 0; level < this.merkleTree.depth; level++) {
            const currentLevel = this.merkleTree.levels[level];
            const siblingIndex = currentIndex % 2 === 0 ? currentIndex + 1 : currentIndex - 1;
            
            // Add sibling to proof if it exists
            if (siblingIndex < currentLevel.length) {
                const sibling = currentLevel[siblingIndex];
                proof.push({
                    hash: sibling.hash,
                    position: currentIndex % 2 === 0 ? 'right' : 'left'
                });
            }

            // Move to parent level
            currentIndex = Math.floor(currentIndex / 2);
        }

        return proof;
    }

    /**
     * Verify a Merkle proof
     */
    verifyProof(userId) {
        const proofData = this.proofs.get(userId);
        if (!proofData) {
            throw new Error(`No proof found for user ${userId}`);
        }

        let currentHash = proofData.leafHash;

        // Reconstruct path to root
        for (const step of proofData.proof) {
            if (step.position === 'right') {
                currentHash = crypto.createHash(this.config.hashAlgorithm)
                    .update(currentHash + step.hash)
                    .digest('hex');
            } else {
                currentHash = crypto.createHash(this.config.hashAlgorithm)
                    .update(step.hash + currentHash)
                    .digest('hex');
            }
        }

        const isValid = currentHash === this.merkleTree.root.hash;
        return {
            userId: userId,
            isValid: isValid,
            computedRoot: currentHash,
            expectedRoot: this.merkleTree.root.hash
        };
    }

    /**
     * Publish Merkle root to HCS for immutable audit trail
     */
    async publishToHCS() {
        console.log('');
        console.log('📡 PUBLISHING TO HEDERA CONSENSUS SERVICE');
        console.log('=========================================');

        try {
            const auditMessage = {
                event: 'MAINNET_MIGRATION_MERKLE_ROOT',
                version: this.config.version,
                timestamp: new Date().toISOString(),
                merkleRoot: this.merkleTree.root.hash,
                userCount: this.migrationData.users.length,
                totalCNETokens: this.migrationData.totals.totalCNETokens,
                exportHash: this.migrationData.metadata.exportHash,
                treeDepth: this.merkleTree.depth,
                metadata: {
                    tokenId: '0.0.10007647',
                    treasuryAccount: '0.0.10007646',
                    network: 'mainnet',
                    migrationPhase: 'balance_snapshot'
                }
            };

            const messageString = JSON.stringify(auditMessage);
            console.log('📝 Audit message prepared:', messageString.length, 'characters');

            // Submit to HCS
            const transaction = new TopicMessageSubmitTransaction()
                .setTopicId(TopicId.fromString(this.auditTopicId))
                .setMessage(messageString);

            const response = await transaction.execute(this.client);
            const receipt = await response.getReceipt(this.client);

            console.log('✅ Successfully published to HCS');
            console.log('   Topic ID:', this.auditTopicId);
            console.log('   Transaction ID:', response.transactionId.toString());
            console.log('   Sequence Number:', receipt.topicSequenceNumber?.toString());
            console.log('   HCS Explorer:', `https://hashscan.io/mainnet/topic/${this.auditTopicId}`);

            return {
                success: true,
                transactionId: response.transactionId.toString(),
                sequenceNumber: receipt.topicSequenceNumber?.toString(),
                topicId: this.auditTopicId,
                merkleRoot: this.merkleTree.root.hash
            };

        } catch (error) {
            console.error('❌ HCS publishing failed:', error.message);
            throw error;
        }
    }

    /**
     * Save all generated data to files
     */
    saveGeneratedData(hcsResult) {
        console.log('');
        console.log('💾 SAVING MERKLE TREE DATA');
        console.log('==========================');

        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

        try {
            // Save complete Merkle tree structure
            const treeData = {
                metadata: {
                    generatedAt: new Date().toISOString(),
                    version: this.config.version,
                    algorithm: this.config.hashAlgorithm,
                    userCount: this.migrationData.users.length,
                    treeDepth: this.merkleTree.depth,
                    rootHash: this.merkleTree.root.hash,
                    exportHash: this.migrationData.metadata.exportHash
                },
                tree: {
                    root: this.merkleTree.root,
                    depth: this.merkleTree.depth,
                    leafCount: this.merkleTree.levels[0].length
                },
                hcsPublication: hcsResult
            };

            const treeFile = `merkle-tree-${timestamp}.json`;
            fs.writeFileSync(treeFile, JSON.stringify(treeData, null, 2));
            console.log('✅ Merkle tree saved:', treeFile);

            // Save user proofs for verification
            const proofsData = {
                metadata: treeData.metadata,
                proofs: Array.from(this.proofs.entries()).map(([userId, proofData]) => ({
                    userId: userId,
                    hederaAccountId: proofData.userData.hederaAccountId,
                    cneTokens: proofData.userData.cneTokens,
                    leafHash: proofData.leafHash,
                    proof: proofData.proof,
                    leafIndex: proofData.leafIndex
                }))
            };

            const proofsFile = `merkle-proofs-${timestamp}.json`;
            fs.writeFileSync(proofsFile, JSON.stringify(proofsData, null, 2));
            console.log('✅ Merkle proofs saved:', proofsFile);

            // Save verification summary
            const summary = {
                merkleRoot: this.merkleTree.root.hash,
                userCount: this.migrationData.users.length,
                totalCNETokens: this.migrationData.totals.totalCNETokens,
                hcsTransactionId: hcsResult.transactionId,
                hcsSequenceNumber: hcsResult.sequenceNumber,
                generatedAt: new Date().toISOString(),
                verificationUrl: `https://hashscan.io/mainnet/topic/${this.auditTopicId}`,
                files: {
                    merkleTree: treeFile,
                    proofs: proofsFile
                }
            };

            const summaryFile = `merkle-summary-${timestamp}.json`;
            fs.writeFileSync(summaryFile, JSON.stringify(summary, null, 2));
            console.log('✅ Summary saved:', summaryFile);

            return {
                treeFile,
                proofsFile,
                summaryFile,
                merkleRoot: this.merkleTree.root.hash
            };

        } catch (error) {
            console.error('❌ Error saving data:', error.message);
            throw error;
        }
    }

    /**
     * Verify all generated proofs
     */
    verifyAllProofs() {
        console.log('');
        console.log('🔍 VERIFYING ALL MERKLE PROOFS');
        console.log('==============================');

        let validCount = 0;
        let invalidCount = 0;

        for (const userId of this.proofs.keys()) {
            try {
                const verification = this.verifyProof(userId);
                if (verification.isValid) {
                    validCount++;
                    console.log(`✅ ${userId}: VALID`);
                } else {
                    invalidCount++;
                    console.log(`❌ ${userId}: INVALID`);
                }
            } catch (error) {
                invalidCount++;
                console.log(`❌ ${userId}: ERROR - ${error.message}`);
            }
        }

        console.log('');
        console.log('📊 VERIFICATION SUMMARY');
        console.log(`   Valid proofs: ${validCount}`);
        console.log(`   Invalid proofs: ${invalidCount}`);
        console.log(`   Total proofs: ${validCount + invalidCount}`);

        if (invalidCount > 0) {
            throw new Error(`${invalidCount} invalid proofs detected`);
        }

        return { validCount, invalidCount };
    }

    /**
     * Execute complete Merkle tree generation process
     */
    async execute() {
        try {
            console.log('🚀 STARTING MERKLE TREE GENERATION');
            console.log('==================================');
            console.log('Target Token ID: 0.0.10007647');
            console.log('Treasury Account: 0.0.10007646');
            console.log('');

            // Initialize Hedera client
            this.initializeHederaClient();

            // Load migration data
            this.loadMigrationData();

            // Create leaf nodes
            const leafNodes = this.createLeafNodes();

            // Build Merkle tree
            this.buildMerkleTree(leafNodes);

            // Generate proofs
            this.generateMerkleProofs();

            // Verify all proofs
            this.verifyAllProofs();

            // Publish to HCS
            const hcsResult = await this.publishToHCS();

            // Save all data
            const savedFiles = this.saveGeneratedData(hcsResult);

            console.log('');
            console.log('🎉 MERKLE TREE GENERATION COMPLETE');
            console.log('==================================');
            console.log('');
            console.log('📊 FINAL RESULTS');
            console.log('================');
            console.log('Merkle Root:', this.merkleTree.root.hash);
            console.log('Users Processed:', this.migrationData.users.length);
            console.log('Total CNE Tokens:', this.migrationData.totals.totalCNETokens.toLocaleString());
            console.log('Tree Depth:', this.merkleTree.depth);
            console.log('');
            console.log('🔗 BLOCKCHAIN VERIFICATION');
            console.log('==========================');
            console.log('HCS Topic:', this.auditTopicId);
            console.log('Transaction ID:', hcsResult.transactionId);
            console.log('Sequence Number:', hcsResult.sequenceNumber);
            console.log('Explorer Link:', `https://hashscan.io/mainnet/topic/${this.auditTopicId}`);
            console.log('');
            console.log('📁 GENERATED FILES');
            console.log('==================');
            console.log('Merkle Tree:', savedFiles.treeFile);
            console.log('User Proofs:', savedFiles.proofsFile);
            console.log('Summary:', savedFiles.summaryFile);
            console.log('');
            console.log('✅ Ready for balance migration (Step 5)');

            return {
                merkleRoot: this.merkleTree.root.hash,
                userCount: this.migrationData.users.length,
                hcsTransaction: hcsResult,
                files: savedFiles
            };

        } catch (error) {
            console.error('💥 Merkle tree generation failed:', error);
            throw error;
        }
    }
}

// Execute if called directly
if (require.main === module) {
    const generator = new MerkleTreeGenerator();
    generator.execute()
        .then(result => {
            console.log('🎉 Merkle tree generation completed successfully!');
            process.exit(0);
        })
        .catch(error => {
            console.error('💥 Generation failed:', error);
            process.exit(1);
        });
}

module.exports = MerkleTreeGenerator;