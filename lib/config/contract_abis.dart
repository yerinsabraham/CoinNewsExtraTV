/// Smart Contract ABI Definitions for CNE Token Rewards
library contract_abis;

/// CNE Token Contract ABI (HTS Token on Hedera)
class CNETokenABI {
  static const String contractABI = '''
  [
    {
      "inputs": [
        {"name": "account", "type": "address"},
        {"name": "amount", "type": "uint256"}
      ],
      "name": "transfer",
      "outputs": [{"name": "", "type": "bool"}],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "account", "type": "address"}],
      "name": "balanceOf",
      "outputs": [{"name": "", "type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "totalSupply",
      "outputs": [{"name": "", "type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "decimals",
      "outputs": [{"name": "", "type": "uint8"}],
      "stateMutability": "view",
      "type": "function"
    }
  ]
  ''';
}

/// Reward Distribution Contract ABI
class RewardContractABI {  
  static const String contractABI = '''
  [
    {
      "inputs": [
        {"name": "user", "type": "address"},
        {"name": "amount", "type": "uint256"},
        {"name": "eventType", "type": "string"},
        {"name": "metadata", "type": "string"}
      ],
      "name": "claimReward",
      "outputs": [{"name": "success", "type": "bool"}],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {"name": "user", "type": "address"},
        {"name": "eventType", "type": "string"}
      ],
      "name": "canClaimReward",
      "outputs": [{"name": "", "type": "bool"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"name": "user", "type": "address"}],
      "name": "getUserRewards",
      "outputs": [
        {"name": "totalEarned", "type": "uint256"},
        {"name": "totalClaimed", "type": "uint256"},
        {"name": "lockedBalance", "type": "uint256"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {"name": "user", "type": "address"},
        {"name": "amount", "type": "uint256"}
      ],
      "name": "lockTokens",
      "outputs": [{"name": "lockId", "type": "uint256"}],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "lockId", "type": "uint256"}],
      "name": "unlockTokens",
      "outputs": [{"name": "success", "type": "bool"}],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {"name": "eventType", "type": "string"},
        {"name": "newAmount", "type": "uint256"}
      ],
      "name": "updateRewardAmount",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "newOwner", "type": "address"}],
      "name": "transferOwnership",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "pause",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "unpause",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "anonymous": false,
      "inputs": [
        {"indexed": true, "name": "user", "type": "address"},
        {"indexed": false, "name": "amount", "type": "uint256"},
        {"indexed": true, "name": "eventType", "type": "string"},
        {"indexed": false, "name": "timestamp", "type": "uint256"}
      ],
      "name": "RewardClaimed",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {"indexed": true, "name": "user", "type": "address"},
        {"indexed": false, "name": "amount", "type": "uint256"},
        {"indexed": false, "name": "lockDuration", "type": "uint256"}
      ],
      "name": "TokensLocked",
      "type": "event"
    }
  ]
  ''';
}

/// Staking Contract ABI
class StakingContractABI {
  static const String contractABI = '''
  [
    {
      "inputs": [{"name": "amount", "type": "uint256"}],
      "name": "stake",
      "outputs": [{"name": "stakeId", "type": "uint256"}],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "stakeId", "type": "uint256"}],
      "name": "unstake",
      "outputs": [{"name": "amount", "type": "uint256"}],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "user", "type": "address"}],
      "name": "getStakeInfo",
      "outputs": [
        {"name": "totalStaked", "type": "uint256"},
        {"name": "rewards", "type": "uint256"},
        {"name": "lastUpdate", "type": "uint256"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "claimStakingRewards",
      "outputs": [{"name": "amount", "type": "uint256"}],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ]
  ''';
}

/// DID Registry Contract ABI (for Hedera DID method)
class DIDRegistryABI {
  static const String contractABI = '''
  [
    {
      "inputs": [
        {"name": "identifier", "type": "string"},
        {"name": "document", "type": "string"}
      ],
      "name": "createDID",
      "outputs": [{"name": "success", "type": "bool"}],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {"name": "identifier", "type": "string"},
        {"name": "document", "type": "string"}
      ],
      "name": "updateDID",
      "outputs": [{"name": "success", "type": "bool"}],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"name": "identifier", "type": "string"}],
      "name": "resolveDID",
      "outputs": [
        {"name": "document", "type": "string"},
        {"name": "lastUpdated", "type": "uint256"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"name": "identifier", "type": "string"}],
      "name": "deactivateDID",
      "outputs": [{"name": "success", "type": "bool"}],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "anonymous": false,
      "inputs": [
        {"indexed": true, "name": "identifier", "type": "string"},
        {"indexed": false, "name": "controller", "type": "address"},
        {"indexed": false, "name": "timestamp", "type": "uint256"}
      ],
      "name": "DIDCreated",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {"indexed": true, "name": "identifier", "type": "string"},
        {"indexed": false, "name": "timestamp", "type": "uint256"}
      ],
      "name": "DIDUpdated",
      "type": "event"
    }
  ]
  ''';
}
