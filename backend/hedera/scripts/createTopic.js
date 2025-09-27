// createTopic.js - Create HCS topic for commit-reveal transparency
const {
    TopicCreateTransaction,
    Hbar
} = require("@hashgraph/sdk");
const { client, OPERATOR_ID, operatorKey } = require('../src/hederaClient');

/**
 * Creates an HCS topic for Play Extra commit-reveal transparency
 * This topic will store commit hashes and reveal seeds for provable fairness
 */
async function createHCSTopic() {
    console.log('📡 Creating HCS topic for Play Extra transparency...');
    
    try {
        // Create the topic
        const topicCreateTx = new TopicCreateTransaction()
            .setTopicMemo("Play Extra Battle Commit-Reveal Log")
            .setSubmitKey(operatorKey) // Only operator can submit messages
            .setAdminKey(operatorKey) // Admin control over topic
            .setMaxTransactionFee(new Hbar(10));

        // Freeze and sign the transaction
        const topicCreateFreeze = await topicCreateTx.freezeWith(client);
        const topicCreateSign = await topicCreateFreeze.sign(operatorKey);
        
        // Execute the transaction
        console.log('📤 Submitting topic creation transaction...');
        const topicCreateSubmit = await topicCreateSign.execute(client);
        
        // Get the receipt
        const topicCreateReceipt = await topicCreateSubmit.getReceipt(client);
        const topicId = topicCreateReceipt.topicId;
        
        console.log('✅ HCS topic created successfully!');
        console.log(`🏷️  Topic ID: ${topicId.toString()}`);
        console.log(`📝 Memo: Play Extra Battle Commit-Reveal Log`);
        console.log(`🔑 Submit Key: ${OPERATOR_ID}`);
        console.log(`⚙️  Admin Key: ${OPERATOR_ID}`);
        
        // Test submitting a message to verify topic works
        console.log('\n🧪 Testing topic with initial message...');
        
        const { TopicMessageSubmitTransaction } = require("@hashgraph/sdk");
        
        const testMessage = JSON.stringify({
            type: 'TOPIC_CREATED',
            timestamp: new Date().toISOString(),
            message: 'Play Extra HCS topic initialized successfully',
            version: '1.0.0'
        });
        
        const messageSubmitTx = new TopicMessageSubmitTransaction()
            .setTopicId(topicId)
            .setMessage(testMessage)
            .setMaxTransactionFee(new Hbar(5));
            
        const messageSubmitFreeze = await messageSubmitTx.freezeWith(client);
        const messageSubmitSign = await messageSubmitFreeze.sign(operatorKey);
        const messageSubmitResponse = await messageSubmitSign.execute(client);
        const messageSubmitReceipt = await messageSubmitResponse.getReceipt(client);
        
        console.log('✅ Test message submitted successfully!');
        console.log(`📨 Message sequence: ${messageSubmitReceipt.topicSequenceNumber}`);
        console.log(`🕒 Running hash: ${messageSubmitReceipt.topicRunningHash.toString('hex')}`);
        
        // Update .env file with topic ID
        console.log('\n📝 To use this topic, update your .env file:');
        console.log(`HCS_TOPIC_ID=${topicId.toString()}`);
        
        return {
            topicId: topicId.toString(),
            memo: "Play Extra Battle Commit-Reveal Log",
            submitKey: OPERATOR_ID,
            adminKey: OPERATOR_ID,
            firstSequenceNumber: messageSubmitReceipt.topicSequenceNumber.toString(),
            runningHash: messageSubmitReceipt.topicRunningHash.toString('hex')
        };
        
    } catch (error) {
        console.error('❌ Failed to create HCS topic:', error.message);
        console.error('Full error:', error);
        
        if (error.message.includes('INSUFFICIENT_PAYER_BALANCE')) {
            console.error('\n💡 Tip: Fund your account with HBAR from the testnet faucet:');
            console.error('https://portal.hedera.com/');
        }
        
        throw error;
    }
}

/**
 * Subscribe to topic messages (for testing and monitoring)
 */
async function subscribeToTopic(topicId) {
    console.log(`👂 Subscribing to topic ${topicId} messages...`);
    
    const { TopicMessageQuery } = require("@hashgraph/sdk");
    
    try {
        new TopicMessageQuery()
            .setTopicId(topicId)
            .setStartTime(0) // Start from beginning
            .subscribe(client, null, (message) => {
                const messageString = Buffer.from(message.contents).toString();
                console.log(`📬 New message (seq ${message.sequenceNumber}):`);
                console.log(`   Timestamp: ${new Date(message.consensusTimestamp.toDate()).toISOString()}`);
                console.log(`   Content: ${messageString}`);
                console.log(`   Hash: ${message.runningHash.toString('hex')}`);
                console.log('---');
                
                try {
                    const messageJson = JSON.parse(messageString);
                    if (messageJson.type) {
                        console.log(`📋 Message type: ${messageJson.type}`);
                    }
                } catch (e) {
                    // Not JSON, that's okay
                }
            });
            
        console.log('✅ Subscription active. Press Ctrl+C to stop.');
        
    } catch (error) {
        console.error('❌ Failed to subscribe to topic:', error.message);
        throw error;
    }
}

// Run the function if this script is executed directly
if (require.main === module) {
    const args = process.argv.slice(2);
    
    if (args[0] === 'subscribe' && args[1]) {
        // Subscribe to existing topic
        subscribeToTopic(args[1])
            .catch((error) => {
                console.error('\n💥 Subscription failed:', error.message);
                process.exit(1);
            });
    } else {
        // Create new topic
        createHCSTopic()
            .then((result) => {
                console.log('\n🎉 Topic creation completed successfully!');
                console.log(JSON.stringify(result, null, 2));
                console.log('\n💡 To subscribe to messages, run:');
                console.log(`node scripts/createTopic.js subscribe ${result.topicId}`);
                process.exit(0);
            })
            .catch((error) => {
                console.error('\n💥 Topic creation failed:', error.message);
                process.exit(1);
            });
    }
}

module.exports = { createHCSTopic, subscribeToTopic };
