import 'package:firebase_core/firebase_core.dart';
import 'lib/services/username_validation_service.dart';
import 'firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('🧪 Testing username validation...');
  
  // Test username availability
  final testUsernames = ['testuser123', 'admin', 'validuser2024'];
  
  for (final username in testUsernames) {
    print('\n--- Testing: $username ---');
    
    // Test format validation
    final formatError = UsernameValidationService.validateUsernameFormat(username);
    if (formatError != null) {
      print('❌ Format error: $formatError');
      continue;
    }
    
    // Test availability
    try {
      final isAvailable = await UsernameValidationService.isUsernameAvailable(username);
      print('✅ Username "$username" available: $isAvailable');
    } catch (e) {
      print('❌ Error checking "$username": $e');
    }
  }
  
  print('\n🧪 Username validation tests completed');
}
