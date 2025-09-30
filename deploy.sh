#!/bin/bash
# Deployment script for CoinNewsExtra TV

echo "🚀 Starting CoinNewsExtra TV Deployment..."

# 1. Initialize video database
echo "📹 Initializing video database..."
cd functions
node init-videos.js

# 2. Deploy Firebase Functions
echo "⚡ Deploying Firebase Functions..."
cd ..
firebase deploy --only functions --force

# 3. Deploy Firestore rules
echo "🔒 Deploying Firestore security rules..."
firebase deploy --only firestore:rules

# 4. Initialize reward configuration
echo "🎁 Initializing reward configuration..."
cd functions
node init-reward-config.js

echo "✅ Deployment completed!"
echo "🎉 Your app should now have full backend functionality!"
