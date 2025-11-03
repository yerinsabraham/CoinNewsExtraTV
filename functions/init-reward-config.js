/**
 * Initialize Reward Configuration in Firestore
 * Sets up halving tiers and reward amounts according to tokenomics
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'coinnewsextra-tv'
  });
}

const db = admin.firestore();

// Exact reward configuration from tokenomics - Updated CNE System
const REWARD_CONFIG = {
  thresholds: [10000, 100000, 500000, 1000000, 5000000, 10000000],
  mapping: {
    "10000": {
      daily_checkin: 28,
      signup_bonus: 700,
      referral_bonus: 700,
      ad_view: 2.8,
      live_tv_watching: 7,
      other_videos_viewing: 7,
      social_follow: 100,
      chat_reward: 0.1,
      extra_ai_reward: 0.50,
      spotlight_reward: 2.8,
      quiz_per_question: 2
    },
    "100000": {
      daily_checkin: 14,
      signup_bonus: 350,
      referral_bonus: 350,
      ad_view: 1.4,
      live_tv_watching: 3.5,
      other_videos_viewing: 3.5,
      social_follow: 50,
      chat_reward: 0.05,
      extra_ai_reward: 0.25,
      spotlight_reward: 1.4,
      quiz_per_question: 1
    },
    "500000": {
      daily_checkin: 7,
      signup_bonus: 175,
      referral_bonus: 175,
      ad_view: 0.7,
      live_tv_watching: 1.75,
      other_videos_viewing: 1.75,
      social_follow: 25,
      chat_reward: 0.025,
      extra_ai_reward: 0.125,
      spotlight_reward: 0.7,
      quiz_per_question: 0.5
    },
    "1000000": {
      daily_checkin: 3.5,
      signup_bonus: 87.5,
      referral_bonus: 87.5,
      ad_view: 0.35,
      live_tv_watching: 0.875,
      other_videos_viewing: 0.875,
      social_follow: 12.5,
      chat_reward: 0.0125,
      extra_ai_reward: 0.0625,
      spotlight_reward: 0.35,
      quiz_per_question: 0.25
    },
    "5000000": {
      daily_checkin: 1.75,
      signup_bonus: 43.75,
      referral_bonus: 43.75,
      ad_view: 0.175,
      live_tv_watching: 0.4375,
      other_videos_viewing: 0.4375,
      social_follow: 6.25,
      chat_reward: 0.00625,
      extra_ai_reward: 0.03125,
      spotlight_reward: 0.175,
      quiz_per_question: 0.125
    },
    "10000000": {
      daily_checkin: 0.875,
      signup_bonus: 21.875,
      referral_bonus: 21.875,
      ad_view: 0.0875,
      live_tv_watching: 0.21875,
      other_videos_viewing: 0.21875,
      social_follow: 3.125,
      chat_reward: 0.003125,
      extra_ai_reward: 0.015625,
      spotlight_reward: 0.0875,
      quiz_per_question: 0.0625
    }
  },
  lock_duration_years: 2,
  lock_percentage: 0.5, // 50% locked
  precision_decimals: 8, // CNE token precision
  created_at: admin.firestore.FieldValue.serverTimestamp(),
  updated_at: admin.firestore.FieldValue.serverTimestamp()
};

// System configuration
const SYSTEM_CONFIG = {
  rewards_paused: false,
  network: 'testnet',
  migration_in_progress: false,
  daily_caps: {
    ad_view: 50,                    // Max 50 ads per day
    live_tv_watching: 144,          // Max 24 hours of live watching (144 * 10min)
    other_videos_viewing: 20,       // Max 20 videos per day
    daily_checkin: 1,               // Once per day
    social_follow: 10,              // Max 10 follows per day
    chat_reward: 1000,              // Max 1000 chat messages per day
    extra_ai_reward: 100,           // Max 100 AI interactions per day
    spotlight_reward: 50,           // Max 50 spotlight views per day
    quiz_per_question: 100          // Max 100 quiz questions per day (10 quizzes)
  },
  anti_abuse: {
    max_accounts_per_device: 5,
    max_skip_rate: 0.3,           // 30% max skip rate
    min_continuous_rate: 0.8,     // 80% min continuous watch
    referral_activity_days: 7     // 7 days minimum activity for referral
  },
  created_at: admin.firestore.FieldValue.serverTimestamp(),
  updated_at: admin.firestore.FieldValue.serverTimestamp()
};

// Initial metrics
const INITIAL_METRICS = {
  user_count: 1000, // Starting user count (will be updated dynamically)
  total_distributed: 0,
  total_locked: 0,
  total_unlocked: 0,
  daily_distribution: 0,
  event_stats: {
    signup_bonus: { count: 0, total: 0 },
    daily_checkin: { count: 0, total: 0 },
    ad_view: { count: 0, total: 0 },
    live_tv_watching: { count: 0, total: 0 },
    other_videos_viewing: { count: 0, total: 0 },
    referral_bonus: { count: 0, total: 0 },
    social_follow: { count: 0, total: 0 },
    chat_reward: { count: 0, total: 0 },
    extra_ai_reward: { count: 0, total: 0 },
    spotlight_reward: { count: 0, total: 0 },
    quiz_per_question: { count: 0, total: 0 }
  },
  last_updated: admin.firestore.FieldValue.serverTimestamp(),
  created_at: admin.firestore.FieldValue.serverTimestamp()
};

async function initializeRewardConfiguration() {
  try {
    console.log('🚀 Initializing reward configuration...');

    // Create config/halving document
    await db.doc('config/halving').set(REWARD_CONFIG);
    console.log('✅ Created config/halving document');

    // Create config/system document
    await db.doc('config/system').set(SYSTEM_CONFIG);
    console.log('✅ Created config/system document');

    // Create metrics/totals document
    await db.doc('metrics/totals').set(INITIAL_METRICS);
    console.log('✅ Created metrics/totals document');

    // Create empty reward_overrides document (for admin use)
    await db.doc('config/reward_overrides').set({
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('✅ Created config/reward_overrides document');

    // Verify configuration
    console.log('\n🔍 Verifying configuration...');
    
    const halvingDoc = await db.doc('config/halving').get();
    const systemDoc = await db.doc('config/system').get();
    const metricsDoc = await db.doc('metrics/totals').get();

    if (halvingDoc.exists && systemDoc.exists && metricsDoc.exists) {
      console.log('✅ All configuration documents created successfully');
      
      // Test halving tier calculation
      const halvingData = halvingDoc.data();
      const testUserCount = 45000;
      
      console.log('\n🧪 Testing halving tier calculation:');
      console.log(`User count: ${testUserCount}`);
      
      // Find appropriate tier
      let tier = 10000;
      for (const threshold of halvingData.thresholds.sort((a, b) => b - a)) {
        if (testUserCount >= threshold) {
          tier = threshold;
          break;
        }
      }
      
      console.log(`Tier: ${tier}`);
      console.log(`Signup bonus: ${halvingData.mapping[tier.toString()].signup_bonus} CNE_TEST`);
      console.log(`Ad view: ${halvingData.mapping[tier.toString()].ad_view} CNE_TEST`);
      
      console.log('\n🎉 Reward configuration initialization complete!');
      
    } else {
      throw new Error('Configuration verification failed');
    }

  } catch (error) {
    console.error('❌ Error initializing reward configuration:', error);
    process.exit(1);
  }
}

// Run initialization if called directly
if (require.main === module) {
  initializeRewardConfiguration()
    .then(() => {
      console.log('✅ Initialization complete');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Initialization failed:', error);
      process.exit(1);
    });
}

module.exports = { initializeRewardConfiguration, REWARD_CONFIG, SYSTEM_CONFIG, INITIAL_METRICS };
