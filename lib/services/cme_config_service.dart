import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class CMEConfigService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  
  // Cache for configuration data
  static Map<String, dynamic>? _configCache;
  static DateTime? _lastConfigUpdate;
  static const Duration _configCacheTimeout = Duration(minutes: 15);

  // Default configuration (fallback) - Flattened for Remote Config compatibility
  static const Map<String, dynamic> _defaultConfig = {
    'video_watch_base': 5.0,
    'video_watch_enabled': true,
    'ad_view_base': 2.0,
    'ad_view_enabled': true,
    'daily_airdrop_base': 10.0,
    'daily_airdrop_enabled': true,
    'quiz_completion_base': 15.0,
    'quiz_completion_enabled': true,
    'social_follow_base': 3.0,
    'social_follow_enabled': true,
    'referral_bonus_base': 25.0,
    'referral_bonus_enabled': true,
    'live_stream_base': 8.0,
    'live_stream_enabled': true,
    'min_redemption': 10.0,
    'max_daily_redemption': 1000.0,
    'processing_fee_hbar': 0.001,
    'lock_duration_years': 2,
    'immediate_percentage': 0.5,
    'locked_percentage': 0.5,
    'max_videos_per_hour': 10,
    'max_ads_per_day': 50,
    'min_watch_percentage': 0.7,
    'device_account_limit': 3,
    'users_per_tier': 10000,
    'max_tier': 10,
    'min_reward_multiplier': 0.001,
  };

  // Initialize Remote Config
  static Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 5),
      ));

      // Set default values
      await _remoteConfig.setDefaults(_defaultConfig);

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();
      
      debugPrint('✅ CME Config initialized successfully');
    } catch (error) {
      debugPrint('⚠️ Failed to initialize Remote Config, using defaults: $error');
    }
  }

  // Get configuration with caching
  static Future<Map<String, dynamic>> getConfig() async {
    // Check cache validity
    if (_configCache != null && 
        _lastConfigUpdate != null &&
        DateTime.now().difference(_lastConfigUpdate!) < _configCacheTimeout) {
      return _configCache!;
    }

    try {
      // Try to fetch latest config
      await _remoteConfig.fetchAndActivate();
      
      // Build config from Remote Config and reconstruct nested structure
      final flatConfig = <String, dynamic>{};
      
      for (final key in _defaultConfig.keys) {
        try {
          final value = _remoteConfig.getString(key);
          if (value.isNotEmpty) {
            // Try to parse as JSON
            flatConfig[key] = _parseConfigValue(value);
          } else {
            flatConfig[key] = _defaultConfig[key];
          }
        } catch (e) {
          flatConfig[key] = _defaultConfig[key];
        }
      }

      // Reconstruct nested structure
      final config = _buildNestedConfig(flatConfig);

      // Update cache
      _configCache = config;
      _lastConfigUpdate = DateTime.now();
      
      return config;
    } catch (error) {
      debugPrint('⚠️ Failed to fetch remote config, using defaults: $error');
      return _defaultConfig;
    }
  }

  // Get reward configuration for specific event type
  static Future<Map<String, dynamic>?> getRewardConfig(String eventType) async {
    final config = await getConfig();
    final rewardRates = config['reward_rates'] as Map<String, dynamic>?;
    return rewardRates?[eventType] as Map<String, dynamic>?;
  }

  // Check if reward type is enabled
  static Future<bool> isRewardEnabled(String eventType) async {
    final rewardConfig = await getRewardConfig(eventType);
    return rewardConfig?['enabled'] ?? false;
  }

  // Get base reward amount for event type
  static Future<double> getBaseRewardAmount(String eventType) async {
    final rewardConfig = await getRewardConfig(eventType);
    return (rewardConfig?['base'] ?? 0.0).toDouble();
  }

  // Get redemption limits
  static Future<Map<String, dynamic>> getRedemptionLimits() async {
    final config = await getConfig();
    return config['redemption_limits'] as Map<String, dynamic>? ?? 
           _defaultConfig['redemption_limits'] as Map<String, dynamic>;
  }

  // Get fraud prevention settings
  static Future<Map<String, dynamic>> getFraudPreventionConfig() async {
    final config = await getConfig();
    return config['fraud_prevention'] as Map<String, dynamic>? ?? 
           _defaultConfig['fraud_prevention'] as Map<String, dynamic>;
  }

  // Get halving tier configuration
  static Future<Map<String, dynamic>> getHalvingConfig() async {
    final config = await getConfig();
    return config['halving_tiers'] as Map<String, dynamic>? ?? 
           _defaultConfig['halving_tiers'] as Map<String, dynamic>;
  }

  // Get vesting configuration
  static Future<Map<String, dynamic>> getVestingConfig() async {
    final config = await getConfig();
    return config['vesting_config'] as Map<String, dynamic>? ?? 
           _defaultConfig['vesting_config'] as Map<String, dynamic>;
  }

  // Calculate tier multiplier based on user count
  static Future<double> calculateTierMultiplier(int totalUsers) async {
    final halvingConfig = await getHalvingConfig();
    final usersPerTier = halvingConfig['users_per_tier'] as int;
    final maxTier = halvingConfig['max_tier'] as int;
    final minMultiplier = halvingConfig['min_reward_multiplier'] as double;

    final tier = (totalUsers / usersPerTier).floor().clamp(0, maxTier);
    final multiplier = 1.0 / (1 << tier); // 1, 0.5, 0.25, 0.125, etc.
    
    return multiplier.clamp(minMultiplier, 1.0);
  }

  // Get system status
  static Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final doc = await _firestore.collection('config').doc('system_status').get();
      if (doc.exists) {
        return doc.data() ?? {'enabled': true, 'maintenance': false};
      }
    } catch (error) {
      debugPrint('Failed to get system status: $error');
    }
    
    return {'enabled': true, 'maintenance': false};
  }

  // Clear configuration cache (force refresh)
  static void clearCache() {
    _configCache = null;
    _lastConfigUpdate = null;
  }

  // Helper to parse configuration values
  static dynamic _parseConfigValue(String value) {
    try {
      // Try parsing as JSON first
      if (value.startsWith('{') || value.startsWith('[')) {
        return _parseJson(value);
      }
      
      // Try parsing as number
      if (RegExp(r'^\d+\.?\d*$').hasMatch(value)) {
        return double.parse(value);
      }
      
      // Try parsing as boolean
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
      
      // Return as string
      return value;
    } catch (e) {
      return value;
    }
  }

  // Simple JSON parser for configuration
  static dynamic _parseJson(String jsonString) {
    try {
      // This is a simplified parser - in production use proper JSON parsing
      if (jsonString.startsWith('{')) {
        final Map<String, dynamic> result = {};
        final content = jsonString.substring(1, jsonString.length - 1);
        final pairs = content.split(',');
        
        for (final pair in pairs) {
          final keyValue = pair.split(':');
          if (keyValue.length == 2) {
            final key = keyValue[0].trim().replaceAll('"', '');
            final value = keyValue[1].trim();
            result[key] = _parseConfigValue(value.replaceAll('"', ''));
          }
        }
        return result;
      }
      return jsonString;
    } catch (e) {
      return jsonString;
    }
  }

  // Development helper - get all current config
  static Future<Map<String, dynamic>> debugGetAllConfig() async {
    final config = await getConfig();
    debugPrint('🔧 Current CME Configuration:');
    config.forEach((key, value) {
      debugPrint('  $key: $value');
    });
    return config;
  }

  // Rebuild nested structure from flat config
  static Map<String, dynamic> _buildNestedConfig(Map<String, dynamic> flatConfig) {
    return {
      'reward_rates': {
        'video_watch': {
          'base': flatConfig['video_watch_base'] ?? 5.0,
          'enabled': flatConfig['video_watch_enabled'] ?? true,
        },
        'ad_view': {
          'base': flatConfig['ad_view_base'] ?? 2.0,
          'enabled': flatConfig['ad_view_enabled'] ?? true,
        },
        'daily_airdrop': {
          'base': flatConfig['daily_airdrop_base'] ?? 10.0,
          'enabled': flatConfig['daily_airdrop_enabled'] ?? true,
        },
        'quiz_completion': {
          'base': flatConfig['quiz_completion_base'] ?? 15.0,
          'enabled': flatConfig['quiz_completion_enabled'] ?? true,
        },
        'social_follow': {
          'base': flatConfig['social_follow_base'] ?? 3.0,
          'enabled': flatConfig['social_follow_enabled'] ?? true,
        },
        'referral_bonus': {
          'base': flatConfig['referral_bonus_base'] ?? 25.0,
          'enabled': flatConfig['referral_bonus_enabled'] ?? true,
        },
        'live_stream': {
          'base': flatConfig['live_stream_base'] ?? 8.0,
          'enabled': flatConfig['live_stream_enabled'] ?? true,
        },
      },
      'redemption_limits': {
        'min_redemption': flatConfig['min_redemption'] ?? 10.0,
        'max_daily_redemption': flatConfig['max_daily_redemption'] ?? 1000.0,
        'processing_fee_hbar': flatConfig['processing_fee_hbar'] ?? 0.001,
      },
      'vesting_config': {
        'lock_duration_years': flatConfig['lock_duration_years'] ?? 2,
        'immediate_percentage': flatConfig['immediate_percentage'] ?? 0.5,
        'locked_percentage': flatConfig['locked_percentage'] ?? 0.5,
      },
      'fraud_prevention': {
        'max_videos_per_hour': flatConfig['max_videos_per_hour'] ?? 10,
        'max_ads_per_day': flatConfig['max_ads_per_day'] ?? 50,
        'min_watch_percentage': flatConfig['min_watch_percentage'] ?? 0.7,
        'device_account_limit': flatConfig['device_account_limit'] ?? 3,
      },
      'halving_tiers': {
        'users_per_tier': flatConfig['users_per_tier'] ?? 10000,
        'max_tier': flatConfig['max_tier'] ?? 10,
        'min_reward_multiplier': flatConfig['min_reward_multiplier'] ?? 0.001,
      }
    };
  }
}

// Configuration models for type safety
class RewardConfig {
  final double base;
  final bool enabled;

  const RewardConfig({required this.base, required this.enabled});

  factory RewardConfig.fromMap(Map<String, dynamic> map) {
    return RewardConfig(
      base: (map['base'] ?? 0.0).toDouble(),
      enabled: map['enabled'] ?? false,
    );
  }
}

class RedemptionLimits {
  final double minRedemption;
  final double maxDailyRedemption;
  final double processingFeeHbar;

  const RedemptionLimits({
    required this.minRedemption,
    required this.maxDailyRedemption,
    required this.processingFeeHbar,
  });

  factory RedemptionLimits.fromMap(Map<String, dynamic> map) {
    return RedemptionLimits(
      minRedemption: (map['min_redemption'] ?? 10.0).toDouble(),
      maxDailyRedemption: (map['max_daily_redemption'] ?? 1000.0).toDouble(),
      processingFeeHbar: (map['processing_fee_hbar'] ?? 0.001).toDouble(),
    );
  }
}

class FraudPreventionConfig {
  final int maxVideosPerHour;
  final int maxAdsPerDay;
  final double minWatchPercentage;
  final int deviceAccountLimit;

  const FraudPreventionConfig({
    required this.maxVideosPerHour,
    required this.maxAdsPerDay,
    required this.minWatchPercentage,
    required this.deviceAccountLimit,
  });

  factory FraudPreventionConfig.fromMap(Map<String, dynamic> map) {
    return FraudPreventionConfig(
      maxVideosPerHour: map['max_videos_per_hour'] ?? 10,
      maxAdsPerDay: map['max_ads_per_day'] ?? 50,
      minWatchPercentage: (map['min_watch_percentage'] ?? 0.7).toDouble(),
      deviceAccountLimit: map['device_account_limit'] ?? 3,
    );
  }
}
