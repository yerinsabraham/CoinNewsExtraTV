/// Admin Wallet Test Screen
/// Provides functionality to test and verify wallet creation for users
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/wallet_creation_service.dart';
import '../services/wallet_verification_service.dart';
import '../services/enhanced_auth_service.dart';

class AdminWalletTestScreen extends StatefulWidget {
  const AdminWalletTestScreen({super.key});

  @override
  State<AdminWalletTestScreen> createState() => _AdminWalletTestScreenState();
}

class _AdminWalletTestScreenState extends State<AdminWalletTestScreen> {
  final _testEmailController = TextEditingController();
  bool _loading = false;
  String? _testResult;
  WalletVerificationStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await WalletVerificationService.instance.getVerificationStats();
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _testCurrentUserWallet() async {
    setState(() {
      _loading = true;
      _testResult = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _testResult = '❌ No user logged in';
        });
        return;
      }

      // Verify current user's wallet
      final verificationResult = await WalletVerificationService.instance
          .verifyUserWallet(currentUser.uid);

      if (verificationResult.success) {
        final wallet = verificationResult.data!.wallet;
        setState(() {
          _testResult = '''✅ Wallet Verification Successful!

Account ID: ${wallet.accountId}
DID: ${wallet.didIdentifier}
Status: ${wallet.status.name}
Created: ${wallet.createdAt.toLocal()}
Email: ${wallet.userEmail}
Display Name: ${wallet.displayName ?? 'N/A'}

Wallet is active and properly configured.''';
        });
      } else {
        setState(() {
          _testResult = '❌ Wallet Verification Failed:\n${verificationResult.error}';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ Test Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _testWalletCreation() async {
    final testEmail = _testEmailController.text.trim();
    if (testEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a test email')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _testResult = null;
    });

    try {
      // Create a mock test user for wallet creation
      final testUserId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      
      final walletResult = await WalletCreationService.instance.createCustodialWallet(
        userId: testUserId,
        userEmail: testEmail,
        displayName: 'Test User',
      );

      if (walletResult.success) {
        final wallet = walletResult.wallet!;
        setState(() {
          _testResult = '''✅ Test Wallet Created Successfully!

Test User ID: $testUserId
Account ID: ${wallet.accountId}
DID: ${wallet.didIdentifier}
Public Key: ${wallet.publicKey.substring(0, 20)}...
Created: ${wallet.createdAt.toLocal()}

⚠️ This is a test wallet and should be cleaned up.''';
        });
      } else {
        setState(() {
          _testResult = '❌ Test Wallet Creation Failed:\n${walletResult.error}';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ Test Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _testCompleteOnboarding() async {
    final testEmail = _testEmailController.text.trim();
    if (testEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a test email')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _testResult = null;
    });

    try {
      // Test complete onboarding process
      final result = await EnhancedAuthService.instance.onboardNewUser(
        email: testEmail,
        password: 'TestPassword123!',
        displayName: 'Test User Complete',
      );

      if (result.success) {
        final data = result.data!;
        setState(() {
          _testResult = '''✅ Complete Onboarding Test Successful!

Firebase UID: ${data.firebaseUser.uid}
Email: ${data.firebaseUser.email}
Wallet Account: ${data.wallet.accountId}
DID: ${data.wallet.didIdentifier}
User Data: ${data.didData.firebaseUid}

⚠️ Test account created - consider cleanup.''';
        });
      } else {
        setState(() {
          _testResult = '❌ Complete Onboarding Test Failed:\n${result.error}';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ Test Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Wallet Testing'),
        backgroundColor: const Color(0xFF006833),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey[900]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Statistics Card
                if (_stats != null) ...[
                  Card(
                    color: Colors.grey[800],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Wallet Statistics',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Total Wallets: ${_stats!.totalWallets}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Active Wallets: ${_stats!.activeWallets}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Users with Wallets: ${_stats!.usersWithWallets}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Recent Creations (24h): ${_stats!.recentCreations}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Last Updated: ${_stats!.lastUpdated.toLocal().toString().split('.')[0]}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Test Email Input
                TextField(
                  controller: _testEmailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Test Email',
                    hintText: 'Enter email for wallet tests',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF006833)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Test Buttons
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF006833),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: _testCurrentUserWallet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006833),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Test Current User Wallet'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _testWalletCreation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Test Wallet Creation Only'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _testCompleteOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Test Complete Onboarding'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadStats,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Refresh Statistics'),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // Test Results
                if (_testResult != null) ...[
                  Card(
                    color: Colors.grey[850],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Test Results',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _testResult!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Warning
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Admin Testing Panel',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This panel is for testing wallet creation functionality. '
                        'Test accounts created here should be cleaned up in production. '
                        'Only use this in development/testing environments.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _testEmailController.dispose();
    super.dispose();
  }
}
