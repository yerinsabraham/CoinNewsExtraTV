/**
 * Script to add admin documents to Firestore
 * Run this from the functions directory: node setup-admin-firestore.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin with application default credentials
admin.initializeApp({
  credential: admin.credential.applicationDefault()
});

const db = admin.firestore();

// Admin accounts to create
const ADMIN_ACCOUNTS = [
  {
    uid: 'ue1WsY6XR8WrDU7F8uSjxPHTdRe2',
    email: 'cnesup@outlook.com',
    role: 'super_admin',
    displayName: 'Super Administrator',
    description: 'Full system access - can manage all aspects of the platform',
    permissions: [
      'manage_admins',
      'manage_finance',
      'send_tokens',
      'view_transaction_logs',
      'manage_content',
      'upload_videos',
      'manage_programs',
      'manage_schedules',
      'manage_spotlight',
      'manage_quiz',
      'moderate_comments',
      'manage_news',
      'update_homepage',
      'system_settings',
      'user_management',
      'support_management'
    ]
  },
  {
    uid: 'fq5OnwErlQebR9Woh0nxGZWjKIf2',
    email: 'cnefinance@outlook.com',
    role: 'finance_admin',
    displayName: 'Finance Administrator',
    description: 'Token management and financial operations only',
    permissions: [
      'manage_finance',
      'send_tokens',
      'view_transaction_logs'
    ]
  },
  {
    uid: 'XECIRvnghqVItF4vIJ9fuZjEhZu1',
    email: 'cneupdates@gmail.com',
    role: 'updates_admin',
    displayName: 'Updates Administrator',
    description: 'Content management and platform updates only',
    permissions: [
      'manage_content',
      'upload_videos',
      'manage_programs',
      'manage_schedules',
      'manage_spotlight',
      'manage_quiz',
      'moderate_comments',
      'manage_news',
      'update_homepage'
    ]
  }
];

async function setupAdminDocuments() {
  console.log('============================================================');
  console.log('📋 Setting up Admin Documents in Firestore');
  console.log('============================================================\n');

  const results = {
    created: [],
    updated: [],
    errors: []
  };

  for (const account of ADMIN_ACCOUNTS) {
    try {
      console.log(`🔐 Processing admin: ${account.email}`);
      
      const adminRef = db.collection('admins').doc(account.uid);
      const existingDoc = await adminRef.get();

      const adminData = {
        email: account.email,
        role: account.role,
        displayName: account.displayName,
        description: account.description,
        permissions: account.permissions,
        isActive: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      if (existingDoc.exists) {
        // Update existing document
        await adminRef.update(adminData);
        console.log(`✅ Updated existing admin document for ${account.email}`);
        results.updated.push(account.email);
      } else {
        // Create new document
        adminData.createdAt = admin.firestore.FieldValue.serverTimestamp();
        adminData.lastLogin = admin.firestore.FieldValue.serverTimestamp();
        await adminRef.set(adminData);
        console.log(`✅ Created new admin document for ${account.email}`);
        results.created.push(account.email);
      }

    } catch (error) {
      console.error(`❌ Error processing ${account.email}:`, error.message);
      results.errors.push({ email: account.email, error: error.message });
    }
  }

  console.log('\n============================================================');
  console.log('📊 Setup Summary');
  console.log('============================================================\n');

  if (results.created.length > 0) {
    console.log(`✅ Created: ${results.created.length}`);
    results.created.forEach(email => console.log(`   - ${email}`));
    console.log('');
  }

  if (results.updated.length > 0) {
    console.log(`🔄 Updated: ${results.updated.length}`);
    results.updated.forEach(email => console.log(`   - ${email}`));
    console.log('');
  }

  if (results.errors.length > 0) {
    console.log(`❌ Errors: ${results.errors.length}`);
    results.errors.forEach(err => console.log(`   - ${err.email}: ${err.error}`));
    console.log('');
  }

  console.log('============================================================');
  console.log('📝 Admin Roles Configuration');
  console.log('============================================================\n');

  console.log('Super Admin (cnesup@outlook.com):');
  console.log('  UID: ue1WsY6XR8WrDU7F8uSjxPHTdRe2');
  console.log('  Role: super_admin');
  console.log('  Permissions: 16 (full access)');
  console.log('  Badge Color: Red\n');

  console.log('Finance Admin (cnefinance@outlook.com):');
  console.log('  UID: fq5OnwErlQebR9Woh0nxGZWjKIf2');
  console.log('  Role: finance_admin');
  console.log('  Permissions: 3 (token management)');
  console.log('  Badge Color: Orange\n');

  console.log('Updates Admin (cneupdates@gmail.com):');
  console.log('  UID: XECIRvnghqVItF4vIJ9fuZjEhZu1');
  console.log('  Role: updates_admin');
  console.log('  Permissions: 9 (content management)');
  console.log('  Badge Color: Blue\n');

  console.log('============================================================');
  console.log('✅ Admin setup complete!');
  console.log('============================================================\n');

  console.log('⚠️  IMPORTANT NEXT STEPS:');
  console.log('1. Install the APK on your test device');
  console.log('2. Test each admin role with password: cneadmin1234');
  console.log('3. Change all passwords immediately after testing');
  console.log('4. Verify role-based access control is working\n');

  process.exit(0);
}

// Run the setup
setupAdminDocuments().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
