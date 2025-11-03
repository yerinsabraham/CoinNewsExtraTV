/**
 * Admin Account Setup Script
 * Creates the three admin accounts for CoinNewsExtraTV
 * 
 * Run: node functions/setup-admin-accounts.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'coinnewsextratv-9c75a'
  });
}

const auth = admin.auth();
const db = admin.firestore();

// Admin account configurations
const ADMIN_ACCOUNTS = [
  {
    email: 'cnesup@outlook.com',
    password: 'cneadmin1234',
    role: 'super_admin',
    displayName: 'Super Admin',
    description: 'Full system access and admin management'
  },
  {
    email: 'cnefinance@outlook.com',
    password: 'cneadmin1234',
    role: 'finance_admin',
    displayName: 'Finance Admin',
    description: 'CNE token and finance management only'
  },
  {
    email: 'cneupdates@gmail.com',
    password: 'cneadmin1234',
    role: 'updates_admin',
    displayName: 'Updates Admin',
    description: 'Content updates and maintenance'
  }
];

// Permission mappings
const PERMISSIONS = {
  super_admin: [
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
  ],
  finance_admin: [
    'manage_finance',
    'send_tokens',
    'view_transaction_logs'
  ],
  updates_admin: [
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
};

async function createAdminAccount(accountInfo) {
  try {
    console.log(`\n🔐 Creating admin account: ${accountInfo.email}`);

    // Check if user already exists
    let userRecord;
    try {
      userRecord = await auth.getUserByEmail(accountInfo.email);
      console.log(`✓ Account already exists: ${accountInfo.email}`);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        // Create new user
        userRecord = await auth.createUser({
          email: accountInfo.email,
          password: accountInfo.password,
          displayName: accountInfo.displayName,
          emailVerified: true // Auto-verify admin emails
        });
        console.log(`✓ Created Firebase Auth user: ${accountInfo.email}`);
      } else {
        throw error;
      }
    }

    // Create/update admin document in Firestore
    const adminRef = db.collection('admins').doc(userRecord.uid);
    await adminRef.set({
      email: accountInfo.email,
      role: accountInfo.role,
      displayName: accountInfo.displayName,
      description: accountInfo.description,
      isActive: true,
      permissions: PERMISSIONS[accountInfo.role],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: null,
      createdBy: 'system_setup'
    }, { merge: true });

    console.log(`✓ Created/updated Firestore admin document`);
    console.log(`  - UID: ${userRecord.uid}`);
    console.log(`  - Role: ${accountInfo.role}`);
    console.log(`  - Permissions: ${PERMISSIONS[accountInfo.role].length} permissions`);

    return {
      success: true,
      uid: userRecord.uid,
      email: accountInfo.email,
      role: accountInfo.role
    };

  } catch (error) {
    console.error(`❌ Error creating admin account ${accountInfo.email}:`, error.message);
    return {
      success: false,
      email: accountInfo.email,
      error: error.message
    };
  }
}

async function setupAdminAccounts() {
  console.log('='.repeat(60));
  console.log('📋 Admin Account Setup for CoinNewsExtraTV');
  console.log('='.repeat(60));

  const results = [];

  for (const account of ADMIN_ACCOUNTS) {
    const result = await createAdminAccount(account);
    results.push(result);
  }

  console.log('\n' + '='.repeat(60));
  console.log('📊 Setup Summary');
  console.log('='.repeat(60));

  const successful = results.filter(r => r.success);
  const failed = results.filter(r => !r.success);

  console.log(`\n✅ Successfully created: ${successful.length}/${ADMIN_ACCOUNTS.length}`);
  successful.forEach(r => {
    console.log(`   - ${r.email} (${r.role})`);
  });

  if (failed.length > 0) {
    console.log(`\n❌ Failed: ${failed.length}`);
    failed.forEach(r => {
      console.log(`   - ${r.email}: ${r.error}`);
    });
  }

  console.log('\n' + '='.repeat(60));
  console.log('📝 Admin Account Details');
  console.log('='.repeat(60));

  ADMIN_ACCOUNTS.forEach(account => {
    console.log(`\n${account.displayName}:`);
    console.log(`  Email: ${account.email}`);
    console.log(`  Password: ${account.password}`);
    console.log(`  Role: ${account.role}`);
    console.log(`  Permissions: ${PERMISSIONS[account.role].join(', ')}`);
  });

  console.log('\n' + '='.repeat(60));
  console.log('✅ Admin account setup complete!');
  console.log('='.repeat(60));
  console.log('\n⚠️  IMPORTANT SECURITY NOTES:');
  console.log('1. Change default passwords immediately after first login');
  console.log('2. Keep admin credentials secure and private');
  console.log('3. Only authorized personnel should have admin access');
  console.log('4. Monitor admin_actions collection for audit trail');
  console.log('\n');
}

// Run setup
setupAdminAccounts()
  .then(() => {
    console.log('✅ Setup completed successfully');
    process.exit(0);
  })
  .catch(error => {
    console.error('❌ Setup failed:', error);
    process.exit(1);
  });
