/// Environment Configuration for CNE Token App
/// Separates testnet and mainnet configurations
library environment_config;

enum AppEnvironment { testnet, mainnet }

class EnvironmentConfig {
  static AppEnvironment _currentEnvironment = AppEnvironment.testnet;
  
  static AppEnvironment get currentEnvironment => _currentEnvironment;
  
  static void setEnvironment(AppEnvironment env) {
    _currentEnvironment = env;
  }
  
  /// Hedera Network Configuration
  static Map<String, dynamic> get hederaConfig {
    switch (_currentEnvironment) {
      case AppEnvironment.testnet:
        return {
          'networkName': 'testnet',
          'operatorId': const String.fromEnvironment('HEDERA_TESTNET_OPERATOR_ID', defaultValue: '0.0.6917102'),
          'operatorKey': const String.fromEnvironment('HEDERA_TESTNET_OPERATOR_KEY', defaultValue: ''),
          'cneTokenId': const String.fromEnvironment('CNE_TESTNET_TOKEN_ID', defaultValue: '0.0.6917127'),
          'hcsTopicId': const String.fromEnvironment('HCS_TESTNET_TOPIC_ID', defaultValue: '0.0.6917128'),
          'mirrorNodeUrl': 'https://testnet.mirrornode.hedera.com',
          'nodeEndpoints': [
            'https://testnet.hedera.com:50211',
            'https://testnet.hedera.com:50212',
          ],
        };
      case AppEnvironment.mainnet:
        return {
          'networkName': 'mainnet',
          'operatorId': const String.fromEnvironment('HEDERA_MAINNET_OPERATOR_ID', defaultValue: ''),
          'operatorKey': const String.fromEnvironment('HEDERA_MAINNET_OPERATOR_KEY', defaultValue: ''),
          'cneTokenId': const String.fromEnvironment('CNE_MAINNET_TOKEN_ID', defaultValue: ''),
          'hcsTopicId': const String.fromEnvironment('HCS_MAINNET_TOPIC_ID', defaultValue: ''),
          'mirrorNodeUrl': 'https://mainnet-public.mirrornode.hedera.com',
          'nodeEndpoints': [
            'https://mainnet.hedera.com:50211',
            'https://mainnet.hedera.com:50212',
          ],
        };
    }
  }
  
  /// Smart Contract Configuration
  static Map<String, dynamic> get smartContractConfig {
    switch (_currentEnvironment) {
      case AppEnvironment.testnet:
        return {
          'rewardContractId': const String.fromEnvironment('REWARD_CONTRACT_TESTNET_ID', defaultValue: ''),
          'stakingContractId': const String.fromEnvironment('STAKING_CONTRACT_TESTNET_ID', defaultValue: ''),
          'gasLimit': 3000000,
          'gasPrice': 20, // gwei
        };
      case AppEnvironment.mainnet:
        return {
          'rewardContractId': const String.fromEnvironment('REWARD_CONTRACT_MAINNET_ID', defaultValue: ''),
          'stakingContractId': const String.fromEnvironment('STAKING_CONTRACT_MAINNET_ID', defaultValue: ''),
          'gasLimit': 3000000,
          'gasPrice': 30, // gwei
        };
    }
  }
  
  /// DID Configuration
  static Map<String, dynamic> get didConfig {
    switch (_currentEnvironment) {
      case AppEnvironment.testnet:
        return {
          'didMethod': 'did:hedera:testnet',
          'registryUrl': 'https://testnet-did-registry.hedera.com',
          'ipfsGateway': 'https://ipfs.io/ipfs/',
          'storageNetwork': 'ipfs',
          'verificationMethod': 'EcdsaSecp256k1VerificationKey2019',
        };
      case AppEnvironment.mainnet:
        return {
          'didMethod': 'did:hedera:mainnet',
          'registryUrl': 'https://mainnet-did-registry.hedera.com',
          'ipfsGateway': 'https://ipfs.io/ipfs/',
          'storageNetwork': 'ipfs',
          'verificationMethod': 'EcdsaSecp256k1VerificationKey2019',
        };
    }
  }
  
  /// Firebase Configuration
  static Map<String, dynamic> get firebaseConfig {
    return {
      'projectId': const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'coinnewsextra-tv'),
      'region': const String.fromEnvironment('FIREBASE_REGION', defaultValue: 'us-central1'),
      'functionsUrl': _currentEnvironment == AppEnvironment.testnet 
          ? 'https://us-central1-coinnewsextra-tv.cloudfunctions.net'
          : 'https://us-central1-coinnewsextra-tv-prod.cloudfunctions.net',
    };
  }
  
  /// API Configuration
  static Map<String, dynamic> get apiConfig {
    return {
      'baseUrl': _currentEnvironment == AppEnvironment.testnet 
          ? 'https://api-testnet.coinnewsextra.tv'
          : 'https://api.coinnewsextra.tv',
      'version': 'v1',
      'timeout': 30000, // 30 seconds
      'retryAttempts': 3,
    };
  }
  
  /// Security Configuration
  static Map<String, dynamic> get securityConfig {
    return {
      'enablePinning': _currentEnvironment == AppEnvironment.mainnet,
      'allowDebugLogs': _currentEnvironment == AppEnvironment.testnet,
      'enableBiometric': true,
      'sessionTimeout': 30 * 60 * 1000, // 30 minutes in milliseconds
    };
  }
  
  /// Validation
  static bool validateConfig() {
    final hedera = hederaConfig;
    final contracts = smartContractConfig;
    
    // Check required fields
    if (hedera['operatorId'].isEmpty || hedera['operatorKey'].isEmpty) {
      print('❌ Missing Hedera operator credentials');
      return false;
    }
    
    if (hedera['cneTokenId'].isEmpty) {
      print('❌ Missing CNE token ID');
      return false;
    }
    
    if (_currentEnvironment == AppEnvironment.mainnet) {
      if (contracts['rewardContractId'].isEmpty) {
        print('❌ Missing reward contract ID for mainnet');
        return false;
      }
    }
    
    print('✅ Environment configuration validated for ${_currentEnvironment.name}');
    return true;
  }
  
  /// Initialize environment from build configuration
  static void initializeFromBuild() {
    const envString = String.fromEnvironment('APP_ENV', defaultValue: 'testnet');
    switch (envString.toLowerCase()) {
      case 'mainnet':
      case 'production':
        _currentEnvironment = AppEnvironment.mainnet;
        break;
      case 'testnet':
      case 'development':
      default:
        _currentEnvironment = AppEnvironment.testnet;
        break;
    }
    
    print('🌍 Environment initialized: ${_currentEnvironment.name}');
    validateConfig();
  }
}
