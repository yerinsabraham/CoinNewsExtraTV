    }
});

// ================================
// SIMPLE REWARD SYSTEM - Import from separate file  
// ================================
const { simpleEarnReward, simpleGetBalance } = require('./simple_rewards');
exports.simpleEarnReward = simpleEarnReward;
exports.simpleGetBalance = simpleGetBalance;