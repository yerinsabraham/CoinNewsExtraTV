import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/enhanced_auth_service.dart';
import '../services/reward_service.dart';
import '../services/user_balance_service.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _loading = false;
  bool _showReferralField = false;

  Future<void> _signup() async {
    setState(() => _loading = true);
    try {
      // Use enhanced authentication service for complete onboarding
      final result = await EnhancedAuthService.instance.onboardNewUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(),
      );
      
      if (!result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Signup failed: ${result.error}")),
          );
        }
        return;
      }
      
      // Initialize user rewards and claim signup bonus
      await _initializeNewUserRewards();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signup successful! Hedera wallet created and welcome bonus awarded! 🎉"),
            backgroundColor: Color(0xFF006833),
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Initialize new user rewards
  Future<void> _initializeNewUserRewards() async {
    try {
      // Initialize user rewards system
      await RewardService.initializeUserRewards();
      
      // Claim signup bonus
      await RewardService.claimSignupBonus();
      
      // Use referral code if provided
      final referralCode = _referralCodeController.text.trim();
      if (referralCode.isNotEmpty) {
        await RewardService.useReferralCode(referralCode: referralCode);
      }
      
      // Initialize the balance service
      final balanceService = Provider.of<UserBalanceService>(context, listen: false);
      await balanceService.initialize();
    } catch (e) {
      debugPrint('Error initializing user rewards: $e');
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    try {
      final userCredential = await AuthService.signInWithGoogle();
      if (userCredential != null) {
        // Check if this is a new user
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        if (isNewUser) {
          // Initialize rewards for new Google sign-in users
          await _initializeNewUserRewards();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Welcome! Signup bonus awarded! ✅"),
                backgroundColor: Color(0xFF006833),
              ),
            );
          }
        }
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 100,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'CoinNewsExtra TV',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Referral code section
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showReferralField = !_showReferralField;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006833).withOpacity(0.1),
                        border: Border.all(color: const Color(0xFF006833).withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.card_giftcard,
                            color: Color(0xFF006833),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _showReferralField 
                                  ? 'Enter referral code for bonus tokens' 
                                  : 'Have a referral code? Tap for bonus!',
                              style: const TextStyle(
                                color: Color(0xFF006833),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            _showReferralField ? Icons.expand_less : Icons.expand_more,
                            color: const Color(0xFF006833),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (_showReferralField) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _referralCodeController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: "Referral Code (Optional)",
                        hintText: "Enter your friend's referral code",
                        prefixIcon: const Icon(Icons.people),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: "Get extra CNE tokens when you use a referral code!",
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006833),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "SIGN UP",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text("OR", style: TextStyle(color: Colors.grey)),
                            ),
                            Expanded(child: Divider(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: _googleSignIn,
                          icon: Image.asset(
                            'assets/icons/google.png',
                            height: 24,
                            width: 24,
                          ),
                          label: const Text(
                            "Sign in with Google",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[700]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Already have an account? Log in",
                      style: TextStyle(
                        color: Color(0xFF006833),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}