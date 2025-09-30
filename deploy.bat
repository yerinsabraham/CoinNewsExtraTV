@echo off
REM Deployment script for CoinNewsExtra TV (Windows)

echo 🚀 Starting CoinNewsExtra TV Deployment...

REM 1. Initialize video database
echo 📹 Initializing video database...
cd functions
node init-videos.js

REM 2. Deploy Firebase Functions
echo ⚡ Deploying Firebase Functions...
cd ..
firebase deploy --only functions --force

REM 3. Deploy Firestore rules
echo 🔒 Deploying Firestore security rules... 
firebase deploy --only firestore:rules

REM 4. Initialize reward configuration
echo 🎁 Initializing reward configuration...
cd functions
node init-reward-config.js

echo ✅ Deployment completed!
echo 🎉 Your app should now have full backend functionality!
