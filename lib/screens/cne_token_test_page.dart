import 'package:flutter/material.dart';
import '../services/fresh_reward_service.dart';
import '../services/http_direct_service.dart';

class CneTokenTestPage extends StatefulWidget {
  const CneTokenTestPage({super.key});

  @override
  State<CneTokenTestPage> createState() => _CneTokenTestPageState();
}

class _CneTokenTestPageState extends State<CneTokenTestPage> {
  final FreshRewardService _freshRewardService = FreshRewardService();
  final HttpDirectService _httpDirectService = HttpDirectService();
  int _currentBalance = 0;
  bool _isLoading = false;
  String _lastAction = '';

  // NUCLEAR SOLUTION - Test with HTTP Direct (bypasses Flutter Firebase SDK)
  Future<void> _testHttpDirectBalance() async {
    setState(() {
      _isLoading = true;
      _lastAction = 'Getting balance via HTTP Direct...';
    });

    try {
      final balance = await _httpDirectService.getBalance();
      setState(() {
        _currentBalance = balance;
        _lastAction = '🚀 HTTP Direct SUCCESS: $balance CNE';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _lastAction = '❌ HTTP Direct FAILED: $e';
        _isLoading = false;
      });
    }
  }

  // NUCLEAR SOLUTION - Test claim with HTTP Direct
  Future<void> _testHttpDirectClaim() async {
    setState(() {
      _isLoading = true;
      _lastAction = 'Claiming reward via HTTP Direct...';
    });

    try {
      await _httpDirectService.claimReward('test', 10);
      setState(() {
        _lastAction = '🚀 HTTP Direct CLAIM SUCCESS: +10 CNE';
        _isLoading = false;
      });
      await _testHttpDirectBalance();
    } catch (e) {
      setState(() {
        _lastAction = '❌ HTTP Direct CLAIM FAILED: $e';
        _isLoading = false;
      });
    }
  }

  // OLD SDK METHODS (for comparison)
  Future<void> _testGetBalance() async {
    setState(() {
      _isLoading = true;
      _lastAction = 'Getting balance via Firebase SDK...';
    });

    try {
      final balance = await _freshRewardService.getBalance();
      setState(() {
        _currentBalance = balance;
        _lastAction = '✅ SDK SUCCESS: $balance CNE';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _lastAction = '❌ SDK FAILED: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testClaimReward() async {
    setState(() {
      _isLoading = true;
      _lastAction = 'Claiming reward via Firebase SDK...';
    });

    try {
      await _freshRewardService.claimReward('test', 10);
      setState(() {
        _lastAction = '✅ SDK CLAIM SUCCESS: +10 CNE';
        _isLoading = false;
      });
      await _testGetBalance();
    } catch (e) {
      setState(() {
        _lastAction = '❌ SDK CLAIM FAILED: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CNE Token Test - NUCLEAR SOLUTION'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nuclear Solution Header
            Card(
              color: Colors.blue[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt, color: Colors.red, size: 32),
                        SizedBox(width: 8),
                        Text(
                          '🚀 NUCLEAR SOLUTION',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'HTTP Direct Bypass (Avoids Flutter Firebase SDK Bug)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Current Balance: $_currentBalance CNE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Last Action: $_lastAction',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // NUCLEAR TEST BUTTONS
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testHttpDirectBalance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '🚀 NUCLEAR GET BALANCE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testHttpDirectClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '🚀 NUCLEAR CLAIM REWARD (+10 CNE)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testGetBalance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '📱 Test Firebase SDK (Original)',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testClaimReward,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '📱 Test SDK Claim (+10 CNE)',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Instructions Card
            Card(
              color: Colors.grey[800],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔬 Test Instructions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Test NUCLEAR buttons first (red/purple)\n'
                      '2. If NUCLEAR works → Authentication is FIXED!\n'
                      '3. Compare with SDK buttons (green/orange)\n'
                      '4. SDK buttons may still fail due to Flutter bug',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '🚀 NUCLEAR = HTTP Direct (bypasses Flutter SDK)\n'
                        '📱 SDK = Original Firebase SDK methods',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
