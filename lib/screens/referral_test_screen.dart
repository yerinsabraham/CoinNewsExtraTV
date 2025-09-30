/// Referral System Test Screen
/// UI for testing and verifying referral code functionality
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/referral_testing_service.dart';
import '../services/reward_service.dart';

class ReferralTestScreen extends StatefulWidget {
  const ReferralTestScreen({super.key});

  @override
  State<ReferralTestScreen> createState() => _ReferralTestScreenState();
}

class _ReferralTestScreenState extends State<ReferralTestScreen> {
  final _testCodeController = TextEditingController();
  bool _loading = false;
  ReferralTestResult? _testResult;
  ReferralStats? _stats;
  String? _userReferralCode;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final code = await RewardService.getUserReferralCode();
      final stats = await ReferralTestingService.instance.getReferralStats();
      
      if (mounted) {
        setState(() {
          _userReferralCode = code;
          _stats = stats;
        });
      }
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  Future<void> _runCompleteTest() async {
    setState(() {
      _loading = true;
      _testResult = null;
    });

    try {
      final result = await ReferralTestingService.instance.testReferralFlow();
      
      if (mounted) {
        setState(() {
          _testResult = result;
        });
        
        // Show result dialog
        _showTestResultDialog(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _testSpecificCode() async {
    final code = _testCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a referral code to test')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final result = await RewardService.useReferralCode(referralCode: code);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success 
                  ? 'Referral code used successfully! +${result.reward ?? 0} CNE'
                  : 'Referral code failed: ${result.message}',
            ),
            backgroundColor: result.success ? const Color(0xFF006833) : Colors.red,
          ),
        );
        
        // Refresh stats
        await _loadInitialData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showTestResultDialog(ReferralTestResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          result.success ? 'Test Results ✅' : 'Test Failed ❌',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result.success && result.data != null) ...[
                Text(
                  'Overall Success: ${result.data!.overallSuccess ? "✅" : "❌"}',
                  style: TextStyle(
                    color: result.data!.overallSuccess ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tests Passed: ${result.data!.testsPassedCount}/${result.data!.totalTestsCount}',
                  style: const TextStyle(color: Colors.white),
                ),
                if (result.data!.referralCode != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Your Referral Code: ${result.data!.referralCode}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Detailed Results:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    result.data!.summary,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Error: ${result.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _copyReferralCode() {
    if (_userReferralCode != null) {
      Clipboard.setData(ClipboardData(text: _userReferralCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral code copied to clipboard!'),
          backgroundColor: Color(0xFF006833),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral System Test'),
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
                // User's Referral Code Card
                if (_userReferralCode != null) ...[
                  Card(
                    color: Colors.grey[800],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Referral Code',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF006833).withOpacity(0.1),
                              border: Border.all(color: const Color(0xFF006833)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _userReferralCode!,
                                    style: const TextStyle(
                                      color: Color(0xFF006833),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _copyReferralCode,
                                  icon: const Icon(Icons.copy, color: Color(0xFF006833)),
                                  tooltip: 'Copy to clipboard',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Referral Statistics
                if (_stats != null) ...[
                  Card(
                    color: Colors.grey[800],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Referral Statistics',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  'Successful Referrals',
                                  _stats!.successfulReferrals.toString(),
                                  Icons.people,
                                ),
                              ),
                              Expanded(
                                child: _buildStatItem(
                                  'Total Earnings',
                                  '${_stats!.totalEarnings.toStringAsFixed(2)} CNE',
                                  Icons.monetization_on,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildStatItem(
                            'Used Referral Code',
                            _stats!.usedReferralCode ? 'Yes' : 'No',
                            _stats!.usedReferralCode ? Icons.check_circle : Icons.cancel,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Test Referral Code Input
                Card(
                  color: Colors.grey[800],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Referral Code',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _testCodeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter referral code to test',
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
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _testSpecificCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Test This Code'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Test Actions
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
                        onPressed: _runCompleteTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006833),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Run Complete Referral Test',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadInitialData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Refresh Data'),
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
                          Row(
                            children: [
                              Text(
                                'Last Test Results',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                _testResult!.success ? Icons.check_circle : Icons.error,
                                color: _testResult!.success ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_testResult!.success && _testResult!.data != null) ...[
                            Text(
                              'Tests Passed: ${_testResult!.data!.testsPassedCount}/${_testResult!.data!.totalTestsCount}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _testResult!.data!.testsPassedCount / _testResult!.data!.totalTestsCount,
                              backgroundColor: Colors.grey[700],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _testResult!.data!.overallSuccess ? Colors.green : Colors.orange,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Error: ${_testResult!.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Information Panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ℹ️ Referral System Testing',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This screen tests the complete referral system functionality including:\n'
                        '• Referral code generation\n'
                        '• Code format validation\n'
                        '• Usage tracking\n'
                        '• Reward distribution\n'
                        '• Anti-abuse measures\n\n'
                        'Share your referral code with friends to earn rewards when they sign up!',
                        style: TextStyle(color: Colors.blue),
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF006833), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _testCodeController.dispose();
    super.dispose();
  }
}
