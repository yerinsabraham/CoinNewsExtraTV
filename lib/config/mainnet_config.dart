// GENERATED MAINNET CONFIGURATION
// Generated on: 2025-09-30T17:24:29.281Z
// DO NOT MODIFY MANUALLY - Use configuration scripts

class MainnetConfig {
  // Hedera Network Configuration
  static const String network = 'mainnet';
  static const String operatorAccountId = '0.0.9764298';
  
  // CNE Token Configuration
  static const String cneTokenId = '0.0.10007647';
  static const String treasuryAccountId = '0.0.10007646';
  
  // HCS Audit Configuration
  static const String auditTopicId = '0.0.10007691';
  
  // Migration Metadata
  static const String migrationDate = '2025-09-30T17:24:29.281Z';
  static const String previousNetwork = 'testnet';
  static const bool isMainnet = true;
  static const bool migrationComplete = true;
  
  // Explorer URLs
  static String get tokenExplorerUrl => 'https://hashscan.io/mainnet/token/$cneTokenId';
  static String get treasuryExplorerUrl => 'https://hashscan.io/mainnet/account/$treasuryAccountId';
  static String get auditExplorerUrl => 'https://hashscan.io/mainnet/topic/$auditTopicId';
  
  // Validation
  static bool validateConfiguration() {
    return cneTokenId.startsWith('0.0.') && 
           treasuryAccountId.startsWith('0.0.') &&
           network == 'mainnet';
  }
  
  // Network endpoints
  static const String hederaNetworkEndpoint = 'mainnet-public.mirrornode.hedera.com';
  static const bool useTestnet = false;
}

// Legacy support - will be deprecated
class TokenConfig {
  @Deprecated('Use MainnetConfig.cneTokenId instead')
  static const String tokenId = MainnetConfig.cneTokenId;
  
  @Deprecated('Use MainnetConfig.treasuryAccountId instead')  
  static const String treasuryId = MainnetConfig.treasuryAccountId;
}
