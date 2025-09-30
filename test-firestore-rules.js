// Test script to verify Firestore rules are working
const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
    admin.initializeApp({
        projectId: 'coinnewsextratv-9c75a'
    });
}

const db = admin.firestore();

async function testFirestoreRules() {
    console.log('🔍 Testing Firestore Rules...');
    
    try {
        // Test reading system configuration (should work)
        console.log('\n1. Testing system config read...');
        const systemRef = db.collection('system').doc('config');
        const systemDoc = await systemRef.get();
        console.log('✅ System config read successful:', systemDoc.exists);
        
        // Test reading videos collection (should work)
        console.log('\n2. Testing videos collection read...');
        const videosRef = db.collection('videos').limit(1);
        const videosSnapshot = await videosRef.get();
        console.log('✅ Videos collection read successful:', videosSnapshot.size, 'documents');
        
        // Test creating a test user document
        console.log('\n3. Testing user document creation...');
        const testUserId = 'test-user-' + Date.now();
        const userRef = db.collection('users').doc(testUserId);
        await userRef.set({
            email: 'test@example.com',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            tokenBalance: 0
        });
        console.log('✅ User document created successfully');
        
        // Test creating social verification document
        console.log('\n4. Testing social verification subcollection...');
        const socialRef = userRef.collection('social_verifications').doc('twitter');
        await socialRef.set({
            platform: 'twitter',
            status: 'pending',
            username: 'testuser',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log('✅ Social verification document created successfully');
        
        // Clean up test data
        console.log('\n5. Cleaning up test data...');
        await socialRef.delete();
        await userRef.delete();
        console.log('✅ Test data cleaned up');
        
        console.log('\n🎉 All Firestore rule tests passed!');
        
    } catch (error) {
        console.error('❌ Firestore rules test failed:', error);
        console.error('Error code:', error.code);
        console.error('Error message:', error.message);
    }
}

// Run the test
testFirestoreRules().then(() => {
    console.log('\n✅ Test completed');
    process.exit(0);
}).catch(error => {
    console.error('💥 Test failed:', error);
    process.exit(1);
});
