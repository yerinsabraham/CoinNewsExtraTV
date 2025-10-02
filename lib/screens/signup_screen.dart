import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
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
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(_nameController.text.trim());
        
        // Create user document
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'balance': 500, // 5 CNE signup bonus (500 units = 5.00 CNE)
          'totalEarned': 500,
          'createdAt': FieldValue.serverTimestamp(),
          'referralCode': _generateReferralCode(userCredential.user!.uid),
        });

        // Process referral code if provided
        final referralCode = _referralCodeController.text.trim();
        if (referralCode.isNotEmpty) {
          await _processReferralCode(referralCode, userCredential.user!.uid);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(referralCode.isNotEmpty 
                ? "Signup successful! Welcome bonus + referral bonus awarded! 🎉"
                : "Signup successful! Welcome bonus awarded! 🎉"),
              backgroundColor: const Color(0xFF006833),
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup failed: ")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _generateReferralCode(String uid) {
    return 'REF';
  }

  Future<void> _processReferralCode(String referralCode, String newUserId) async {
    try {
      // Find the referrer by referral code
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final referrerDoc = querySnapshot.docs.first;
        final referrerId = referrerDoc.id;

        if (referrerId != newUserId) {
          // Give bonus to new user (referee)
          await FirebaseFirestore.instance.collection('users').doc(newUserId).update({
            'balance': FieldValue.increment(300), // 3 CNE referral bonus
            'totalEarned': FieldValue.increment(300),
            'referredBy': referrerId,
          });

          // Give bonus to referrer
          await FirebaseFirestore.instance.collection('users').doc(referrerId).update({
            'balance': FieldValue.increment(500), // 5 CNE referral reward
            'totalEarned': FieldValue.increment(500),
          });

          // Record the referral
          await FirebaseFirestore.instance.collection('referrals').add({
            'referrerId': referrerId,
            'refereeId': newUserId,
            'referralCode': referralCode,
            'timestamp': FieldValue.serverTimestamp(),
            'referrerBonus': 5.0,
            'refereeBonus': 3.0,
          });

          print('Referral processed: Referrer  gets 5 CNE, Referee  gets 3 CNE');
        }
      }
    } catch (e) {
      print('Error processing referral: ');
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    try {
      final userCredential = await AuthService.signInWithGoogle();
      if (userCredential != null) {
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        if (isNewUser) {
          // Create user document for new Google users
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'name': userCredential.user!.displayName ?? 'User',
            'email': userCredential.user!.email ?? '',
            'balance': 500, // 5 CNE signup bonus
            'totalEarned': 500,
            'createdAt': FieldValue.serverTimestamp(),
            'referralCode': _generateReferralCode(userCredential.user!.uid),
          });

          // Process referral if provided
          final referralCode = _referralCodeController.text.trim();
          if (referralCode.isNotEmpty) {
            await _processReferralCode(referralCode, userCredential.user!.uid);
          }

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
          SnackBar(content: Text("Error: ")),
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
