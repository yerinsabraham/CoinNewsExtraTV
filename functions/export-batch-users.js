const admin = require('firebase-admin');
const fs = require('fs');

// Initialize batch-03
const batch03 = admin.initializeApp({
  projectId: 'coinnewsextratv-batch-03-c94f4'
}, 'batch03');

// Initialize batch-04
const batch04 = admin.initializeApp({
  projectId: 'coinnewsextratv-batch-04-e38fd'
}, 'batch04');

async function exportUsersFromProject(app, projectName) {
  console.log(`\n📥 Exporting users from ${projectName}...`);
  
  const allUsers = [];
  let nextPageToken;
  
  try {
    do {
      const listUsersResult = await app.auth().listUsers(1000, nextPageToken);
      
      listUsersResult.users.forEach((userRecord) => {
        allUsers.push({
          uid: userRecord.uid,
          email: userRecord.email || '',
          displayName: userRecord.displayName || '',
          phoneNumber: userRecord.phoneNumber || '',
          photoURL: userRecord.photoURL || '',
          emailVerified: userRecord.emailVerified,
          disabled: userRecord.disabled,
          creationTime: userRecord.metadata.creationTime,
          lastSignInTime: userRecord.metadata.lastSignInTime || '',
          providerData: userRecord.providerData.map(p => p.providerId).join('; '),
        });
      });
      
      nextPageToken = listUsersResult.pageToken;
      console.log(`  Fetched ${allUsers.length} users so far...`);
      
    } while (nextPageToken);
    
    console.log(`✅ Total users from ${projectName}: ${allUsers.length}`);
    
    // Convert to CSV
    const headers = [
      'UID',
      'Email',
      'Display Name',
      'Phone Number',
      'Photo URL',
      'Email Verified',
      'Disabled',
      'Creation Time',
      'Last Sign In',
      'Providers'
    ];
    
    const csvRows = [headers.join(',')];
    
    allUsers.forEach((user) => {
      const row = [
        user.uid,
        user.email,
        `"${user.displayName}"`,
        user.phoneNumber,
        user.photoURL,
        user.emailVerified,
        user.disabled,
        user.creationTime,
        user.lastSignInTime,
        `"${user.providerData}"`
      ];
      csvRows.push(row.join(','));
    });
    
    const csv = csvRows.join('\n');
    const filename = `${projectName}_users_${allUsers.length}_${new Date().toISOString().split('T')[0]}.csv`;
    
    fs.writeFileSync(filename, csv);
    console.log(`💾 Saved to: ${filename}\n`);
    
    return allUsers.length;
    
  } catch (error) {
    console.error(`❌ Error exporting ${projectName}:`, error.message);
    return 0;
  }
}

async function main() {
  console.log('🚀 Starting user export from both Firebase projects...\n');
  
  const batch03Count = await exportUsersFromProject(batch03, 'batch-03');
  const batch04Count = await exportUsersFromProject(batch04, 'batch-04');
  
  console.log('═══════════════════════════════════════');
  console.log(`✅ Export Complete!`);
  console.log(`   Batch-03: ${batch03Count} users`);
  console.log(`   Batch-04: ${batch04Count} users`);
  console.log(`   Total: ${batch03Count + batch04Count} users`);
  console.log('═══════════════════════════════════════\n');
  
  process.exit(0);
}

main();
