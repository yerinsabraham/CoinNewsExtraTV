// Admin User Deletion Script
// Usage: node delete-user.js yerinsmgmt@gmail.com "Account cleanup request"

const admin = require('firebase-admin');
const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const { getFunctions, httpsCallable } = require('firebase/functions');

// Initialize Firebase Admin (for server-side operations)
const serviceAccount = require('./service-account-key.json'); // You'll need to add this file
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'coinnewsextratv-9c75a'
});

// Initialize Firebase Client SDK
const firebaseConfig = {
  projectId: 'coinnewsextratv-9c75a',
  // Add other config values as needed
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const functions = getFunctions(app);

async function deleteUserAccount(targetEmail, reason) {
  try {
    console.log('🔐 Admin User Deletion Tool');
    console.log('==============================');
    
    // Get command line arguments
    const email = targetEmail || process.argv[2];
    const deletionReason = reason || process.argv[3] || 'Admin requested deletion';
    
    if (!email) {
      console.error('❌ Usage: node delete-user.js <email> [reason]');
      process.exit(1);
    }
    
    console.log(`📧 Target email: ${email}`);
    console.log(`📝 Reason: ${deletionReason}`);
    console.log('');
    
    // Step 1: Authenticate as admin (you'll need to provide admin credentials)
    console.log('🔑 Authenticating as admin...');
    const adminEmail = 'your-admin-email@example.com'; // Replace with actual admin email
    const adminPassword = 'your-admin-password'; // Replace with actual admin password
    
    try {
      const userCredential = await signInWithEmailAndPassword(auth, adminEmail, adminPassword);
      console.log('✅ Admin authentication successful');
    } catch (authError) {
      console.error('❌ Admin authentication failed:', authError.message);
      console.error('Please update the admin credentials in this script');
      process.exit(1);
    }
    
    // Step 2: Call the deletion function
    console.log('🗑️ Calling user deletion function...');
    const deleteUserAccountFunction = httpsCallable(functions, 'deleteUserAccount');
    
    const result = await deleteUserAccountFunction({
      email: email,
      reason: deletionReason
    });
    
    if (result.data.success) {
      console.log('✅ User account deleted successfully!');
      console.log('');
      console.log('📊 Deletion Summary:');
      console.log(`   - User ID: ${result.data.deleted_user_id}`);
      console.log(`   - Firebase Auth: ${result.data.deletion_summary.firebase_auth ? '✅' : '❌'}`);
      console.log(`   - User Document: ${result.data.deletion_summary.user_document ? '✅' : '❌'}`);
      console.log(`   - Rewards Entries: ${result.data.deletion_summary.rewards_entries} deleted`);
      console.log(`   - Social Verifications: ${result.data.deletion_summary.social_verifications} deleted`);
      console.log(`   - Redemptions: ${result.data.deletion_summary.redemptions} deleted`);
      console.log(`   - Battle Participations: ${result.data.deletion_summary.battle_participations} updated`);
      console.log(`   - Pending Transfers: ${result.data.deletion_summary.pending_transfers} deleted`);
      console.log('');
      console.log('🎯 Account deletion completed successfully!');
    } else {
      console.error('❌ User deletion failed:', result.data.message);
    }
    
  } catch (error) {
    console.error('❌ Error during user deletion:', error.message);
    if (error.code) {
      console.error(`   Error Code: ${error.code}`);
    }
  }
}

async function confirmDeletion(email) {
  const readline = require('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  
  return new Promise((resolve) => {
    rl.question(`⚠️  Are you sure you want to DELETE the account "${email}"? This action cannot be undone! (yes/no): `, (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'yes');
    });
  });
}

// Main execution
async function main() {
  const targetEmail = process.argv[2];
  const reason = process.argv[3] || 'Admin requested deletion';
  
  if (!targetEmail) {
    console.log('🔐 Firebase User Deletion Tool');
    console.log('Usage: node delete-user.js <email> [reason]');
    console.log('');
    console.log('Example:');
    console.log('  node delete-user.js user@example.com "Account cleanup"');
    return;
  }
  
  console.log('⚠️  WARNING: This will permanently delete the user account and all associated data!');
  console.log('');
  
  const confirmed = await confirmDeletion(targetEmail);
  if (!confirmed) {
    console.log('❌ Deletion cancelled by user');
    return;
  }
  
  await deleteUserAccount(targetEmail, reason);
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { deleteUserAccount };
