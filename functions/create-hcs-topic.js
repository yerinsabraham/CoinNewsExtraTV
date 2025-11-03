/**
 * Create HCS Topic for Mainnet Migration Audit Trail
 */

const { 
    Client, 
    AccountId, 
    PrivateKey, 
    TopicCreateTransaction,
    Hbar 
} = require("@hashgraph/sdk");

async function createAuditTopic() {
    console.log('🚀 CREATING HCS AUDIT TOPIC');
    console.log('===========================');

    try {
        // Initialize client
        const accountId = AccountId.fromString(process.env.HEDERA_ACCOUNT_ID || "0.0.9764298");
        const privateKey = PrivateKey.fromString(process.env.HEDERA_PRIVATE_KEY);
        const client = Client.forMainnet().setOperator(accountId, privateKey);

        // Create topic
        const transaction = new TopicCreateTransaction()
            .setTopicMemo("CNE Mainnet Migration Audit Trail - Token ID: 0.0.10007647")
            .setSubmitKey(privateKey.publicKey)
            .setMaxTransactionFee(new Hbar(2));

        const response = await transaction.execute(client);
        const receipt = await response.getReceipt(client);

        console.log('✅ HCS Topic Created Successfully');
        console.log('Topic ID:', receipt.topicId.toString());
        console.log('Transaction ID:', response.transactionId.toString());
        console.log('Explorer:', `https://hashscan.io/mainnet/topic/${receipt.topicId.toString()}`);

        return {
            topicId: receipt.topicId.toString(),
            transactionId: response.transactionId.toString()
        };

    } catch (error) {
        console.error('❌ Topic creation failed:', error.message);
        throw error;
    }
}

// Execute if called directly
if (require.main === module) {
    createAuditTopic()
        .then(result => {
            console.log('🎉 Topic creation completed successfully!');
            console.log('Use this Topic ID:', result.topicId);
            process.exit(0);
        })
        .catch(error => {
            console.error('💥 Creation failed:', error);
            process.exit(1);
        });
}

module.exports = createAuditTopic;