# Google Sign-In Fix Guide

## Problem
Google Sign-In is failing with "Sign-in was canceled" because the Android app (`com.coinnewsextratv.cnetv`) **does not have an Android OAuth 2.0 client configured** in Firebase Console.

Your `google-services.json` shows:
- Package `com.coinnewsextra.tv` ✅ Has Android OAuth client with SHA-1
- Package `com.coinnewsextratv.cnetv` ❌ **Only has Web OAuth client** (no Android client)

## Solution

### Step 1: Get Your SHA-1 Certificate Fingerprint

Run this command to get your debug SHA-1 key:

```bash
cd android
./gradlew signingReport
```

Look for output like this:
```
Variant: debug
Config: debug
Store: /Users/njokusomto/.android/debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:...
SHA1: AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12
SHA-256: XX:XX:XX:...
```

**Copy the SHA1 value** (the one that looks like `AB:CD:EF:...`)

### Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **coinnewsextratv-9c75a**
3. Click the gear icon (⚙️) → **Project settings**
4. Scroll down to **Your apps** section
5. Find the Android app: `com.coinnewsextratv.cnetv`
6. Click **Add fingerprint**
7. Paste your SHA-1 fingerprint
8. Click **Save**

### Step 3: Download Updated google-services.json

1. In Firebase Console, still in **Project settings**
2. Scroll to the Android app: `com.coinnewsextratv.cnetv`
3. Click **Download google-services.json**
4. Replace the file at: `android/app/google-services.json`

### Step 4: Verify Configuration

After downloading the new `google-services.json`, verify it contains an Android OAuth client (client_type: 1):

```bash
cat android/app/google-services.json | grep -A 5 "client_type.*1"
```

You should see something like:
```json
{
  "client_id": "889552494681-XXXXX.apps.googleusercontent.com",
  "client_type": 1,
  "android_info": {
    "package_name": "com.coinnewsextratv.cnetv",
    "certificate_hash": "YOUR_SHA1_HERE"
  }
}
```

### Step 5: Clean and Rebuild

```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

### Step 6: Test Google Sign-In

1. Tap "Sign in with Google" button
2. You should now see Google account picker
3. Select an account
4. Sign in should complete successfully ✅

## Alternative Quick Fix (if Firebase Console access is delayed)

If you can't access Firebase Console immediately, you can test with the **other package** that already has SHA-1 configured:

1. Open `android/app/build.gradle.kts`
2. Find: `applicationId = "com.coinnewsextratv.cnetv"`
3. Temporarily change to: `applicationId = "com.coinnewsextra.tv"`
4. Run: `flutter clean && flutter run`
5. Test Google Sign-In (should work)
6. **Remember to change it back** after verifying

## Troubleshooting

### If sign-in still fails after adding SHA-1:

1. **Wait 5 minutes** - Firebase can take a few minutes to propagate changes
2. **Check logs**: Run `flutter run` and watch for error messages
3. **Verify package name**: Make sure `applicationId` in `build.gradle.kts` matches Firebase
4. **Check Google Sign-In is enabled**: Firebase Console → Authentication → Sign-in method → Google (should be enabled)

### Common errors:

- **"10: Developer Error"** = SHA-1 fingerprint missing or incorrect
- **"Sign-in was canceled"** = OAuth client not configured
- **"DEVELOPER_ERROR"** in logs = package name or SHA-1 mismatch

## Technical Details

Current configuration in `lib/services/auth_service.dart`:
- Web Client ID: `889552494681-52shssr5ar3pvde98g6u485j3o0e2ula.apps.googleusercontent.com`
- This ID is from your `google-services.json` and is used as `serverClientId` for Android

The code has been updated with:
- ✅ Proper initialization with Web client ID
- ✅ Detailed logging (watch console for 🔑, ✅, ❌ emoji markers)
- ✅ Better error handling and messages

---

**Next steps**: Run `./gradlew signingReport` to get SHA-1, then add it to Firebase Console.
