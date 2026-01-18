#!/usr/bin/env node

/**
 * Terminal Script for Unlimited Account Creation
 * Usage: node terminal-create-accounts.js <count>
 * Example: node terminal-create-accounts.js 500
 * 
 * This script can create unlimited accounts directly from terminal
 * No timeout limits, no Cloud Function restrictions
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin using default credentials (Firebase CLI login)
// You must be logged in: firebase login
try {
  admin.initializeApp({
    projectId: 'coinnewsextratv-9c75a'
  });
  console.log('✅ Firebase Admin initialized successfully');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin:', error.message);
  console.error('\nMake sure you are logged in: firebase login');
  process.exit(1);
}

// Real human names for email generation
const firstNames = [
  'john', 'fred', 'rachel', 'janet', 'nneka', 'tunde', 'ali', 'sarah', 'michael', 'david',
  'maria', 'james', 'linda', 'robert', 'patricia', 'amina', 'chidi', 'ada', 'emeka', 'fatima',
  'yusuf', 'aisha', 'ibrahim', 'zainab', 'abdullahi', 'hafsa', 'umar', 'khadija', 'musa', 'mariam',
  'elizabeth', 'william', 'jennifer', 'joseph', 'susan', 'thomas', 'jessica', 'charles', 'karen', 'daniel',
  'nancy', 'matthew', 'betty', 'anthony', 'margaret', 'mark', 'sandra', 'donald', 'ashley', 'steven'
];

function generateRandomEmail() {
  const name = firstNames[Math.floor(Math.random() * firstNames.length)];
  const number = Math.floor(Math.random() * 9999) + 1;
  return `${name}${number}@gmail.com`;
}

function generateRandomPassword() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
  let password = '';
  
  for (let i = 0; i < 12; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  
  return password.split('').sort(() => Math.random() - 0.5).join('');
}

function generateDID() {
  return `did:example:${Math.random().toString(36).substring(2, 15)}${Math.random().toString(36).substring(2, 15)}`;
}

async function createAccounts(count) {
  console.log(`\n🚀 Starting creation of ${count} accounts...\n`);
  
  const results = {
    successful: [],
    failed: [],
    total: count
  };

  const startTime = Date.now();

  for (let i = 0; i < count; i++) {
    const email = generateRandomEmail();
    const password = generateRandomPassword();

    try {
      // Progress indicator
      if ((i + 1) % 10 === 0 || i === 0) {
        const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
        const avgTime = elapsed / (i + 1);
        const remaining = ((count - i - 1) * avgTime).toFixed(0);
        console.log(`\n📊 Progress: ${i + 1}/${count} (${((i + 1) / count * 100).toFixed(1)}%) | Elapsed: ${elapsed}s | ETA: ${remaining}s`);
      }

      // 1. Create Firebase Auth user
      const userRecord = await admin.auth().createUser({
        email: email,
        password: password,
        emailVerified: false
      });

      const did = generateDID();

      // 2. Create user document
      await admin.firestore().collection('users').doc(userRecord.uid).set({
        email: email,
        displayName: email.split('@')[0],
        photoURL: '',
        cneBalance: 0,
        totalWatchTime: 0,
        totalEarnings: 0,
        videoCount: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastLogin: admin.firestore.FieldValue.serverTimestamp(),
        accountType: 'admin_created',
        hederaAccountId: 'Pending',
        status: 'pending_hedera',
        did: did
      });

      // 3. Store credentials
      await admin.firestore().collection('admin_created_accounts').add({
        email: email,
        password: password,
        firebaseUid: userRecord.uid,
        hederaAccountId: 'Pending',
        status: 'pending_hedera',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        did: did
      });

      results.successful.push({
        email: email,
        password: password,
        firebaseUid: userRecord.uid,
        hederaAccountId: 'Pending'
      });

      console.log(`✅ [${i + 1}/${count}] Created: ${email}`);

      // Small delay
      if (i < count - 1) {
        await new Promise(resolve => setTimeout(resolve, 200)); // 200ms delay
      }

    } catch (error) {
      console.error(`❌ [${i + 1}/${count}] Failed: ${email} - ${error.message}`);
      
      results.failed.push({
        email: email,
        error: error.message
      });
    }
  }

  const totalTime = ((Date.now() - startTime) / 1000).toFixed(1);

  // Update system stats
  try {
    const statsDoc = await admin.firestore().collection('system_stats').doc('admin_accounts').get();
    const currentTotal = statsDoc.exists ? (statsDoc.data().totalCreated || 0) : 0;
    
    await admin.firestore().collection('system_stats').doc('admin_accounts').set({
      totalCreated: currentTotal + results.successful.length,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      lastBulkCreate: {
        count: count,
        successful: results.successful.length,
        failed: results.failed.length,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      }
    }, { merge: true });
  } catch (error) {
    console.error('Failed to update stats:', error.message);
  }

  // Save results to file
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = `accounts-${count}-${timestamp}.json`;
  const filepath = path.join(__dirname, filename);
  
  fs.writeFileSync(filepath, JSON.stringify(results, null, 2));

  // Also save as CSV
  const csvFilename = `accounts-${count}-${timestamp}.csv`;
  const csvFilepath = path.join(__dirname, csvFilename);
  
  let csvContent = 'Email,Password,Firebase UID,Hedera Account ID,Status\n';
  results.successful.forEach(acc => {
    csvContent += `${acc.email},${acc.password},${acc.firebaseUid},${acc.hederaAccountId},pending_hedera\n`;
  });
  
  fs.writeFileSync(csvFilepath, csvContent);

  // Print summary
  console.log('\n' + '='.repeat(60));
  console.log('🎉 BATCH CREATION COMPLETE');
  console.log('='.repeat(60));
  console.log(`✅ Successful: ${results.successful.length}`);
  console.log(`❌ Failed: ${results.failed.length}`);
  console.log(`⏱️  Total Time: ${totalTime} seconds`);
  console.log(`⚡ Average: ${(totalTime / count).toFixed(2)}s per account`);
  console.log(`\n📁 Results saved to:`);
  console.log(`   JSON: ${filename}`);
  console.log(`   CSV:  ${csvFilename}`);
  console.log('='.repeat(60) + '\n');

  // Show first 5 accounts as sample
  if (results.successful.length > 0) {
    console.log('📋 Sample Accounts (first 5):');
    results.successful.slice(0, 5).forEach((acc, idx) => {
      console.log(`${idx + 1}. ${acc.email} | ${acc.password}`);
    });
    console.log('');
  }

  process.exit(0);
}

// Main execution
const args = process.argv.slice(2);
if (args.length === 0 || isNaN(args[0])) {
  console.error(`
❌ Usage: node terminal-create-accounts.js <count>

Examples:
  node terminal-create-accounts.js 100    # Create 100 accounts
  node terminal-create-accounts.js 500    # Create 500 accounts
  node terminal-create-accounts.js 1000   # Create 1000 accounts

Note: No limit! Create as many as you need.
Results are saved to JSON and CSV files in the functions directory.
`);
  process.exit(1);
}

const count = parseInt(args[0], 10);

if (count < 1) {
  console.error('❌ Count must be at least 1');
  process.exit(1);
}

if (count > 10000) {
  console.error('⚠️  Warning: Creating more than 10,000 accounts at once may take a very long time.');
  console.error('Consider running multiple batches instead.');
  process.exit(1);
}

// Confirmation for large batches
if (count >= 200) {
  console.log(`\n⚠️  You are about to create ${count} accounts.`);
  console.log(`Estimated time: ~${Math.ceil(count * 0.2 / 60)} minutes`);
  console.log(`Press Ctrl+C to cancel, or wait 5 seconds to continue...\n`);
  
  setTimeout(() => {
    createAccounts(count);
  }, 5000);
} else {
  createAccounts(count);
}
