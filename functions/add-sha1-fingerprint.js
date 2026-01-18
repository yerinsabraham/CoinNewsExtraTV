#!/usr/bin/env node

/**
 * Add SHA-1 fingerprint to Firebase Android app
 * Run: node add-sha1-fingerprint.js
 */

const admin = require('firebase-admin');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

// Initialize Firebase Admin (requires service account key)
const serviceAccount = require('./service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'coinnewsextratv-9c75a'
});

const PROJECT_ID = 'coinnewsextratv-9c75a';
const PACKAGE_NAME = 'com.coinnewsextra.tv';
const SHA1_FINGERPRINT = '7D:43:D3:53:A9:FC:F1:04:39:6C:5F:22:9F:01:95:2E:B6:C8:08:A2';

async function addSHA1ToFirebase() {
  console.log('Adding SHA-1 fingerprint to Firebase...');
  console.log('SHA-1:', SHA1_FINGERPRINT);
  
  try {
    // Use Firebase CLI to add SHA-1
    const sha1Clean = SHA1_FINGERPRINT.replace(/:/g, '').toLowerCase();
    
    const command = `firebase apps:android:sha:create ${PACKAGE_NAME} ${sha1Clean} --project ${PROJECT_ID}`;
    console.log('Executing:', command);
    
    const { stdout, stderr } = await execPromise(command);
    console.log('Output:', stdout);
    if (stderr) console.error('Errors:', stderr);
    
    console.log('\n✅ SHA-1 fingerprint added successfully!');
    console.log('\nNow downloading updated google-services.json...');
    
    // Download updated google-services.json
    const downloadCmd = `firebase apps:sdkconfig ANDROID --out android/app/google-services.json --project ${PROJECT_ID}`;
    const { stdout: dlOut, stderr: dlErr } = await execPromise(downloadCmd);
    console.log('Download output:', dlOut);
    if (dlErr) console.error('Download errors:', dlErr);
    
    console.log('\n✅ google-services.json updated!');
    console.log('\n📱 Next steps:');
    console.log('1. Rebuild your app: flutter clean && flutter pub get');
    console.log('2. Run the app: flutter run');
    console.log('3. Test Google Sign-In');
    
  } catch (error) {
    console.error('❌ Error adding SHA-1:', error.message);
    console.log('\n📋 Manual steps:');
    console.log('1. Go to: https://console.firebase.google.com/project/coinnewsextratv-9c75a/settings/general');
    console.log('2. Scroll to "Your apps" section');
    console.log('3. Click on your Android app (com.coinnewsextra.tv)');
    console.log('4. Add this SHA-1 fingerprint:', SHA1_FINGERPRINT);
    console.log('5. Download the updated google-services.json');
    console.log('6. Replace android/app/google-services.json with the new file');
  }
}

addSHA1ToFirebase();
