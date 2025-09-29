import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'provider/user_provider.dart';
import 'provider/admin_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/live_tv_page.dart';
import 'screens/programs_page.dart';
import 'screens/market_cap_page.dart';
import 'screens/community_chat.dart';
import 'screens/extra_ai_chat.dart';
import 'screens/news_page.dart';
import 'screens/notification_screen.dart';
import 'screens/explore_page.dart';
import 'screens/spin2earn_game_page.dart';
import 'play_extra/screens/play_extra_main.dart';
import 'play_extra/services/play_extra_service.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Play Extra service
  await PlayExtraService().initialize();
  
  runApp(const Watch2EarnApp());
}

class Watch2EarnApp extends StatelessWidget {
  const Watch2EarnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CoinNewsExtra TV',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          primaryColor: const Color(0xFF006833),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF006833),
            secondary: Color(0xFF006833),
          ),
        ),
        home: const LoginScreen(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/home':
              return MaterialPageRoute(builder: (_) => const HomeScreen());
            case '/signup':
              return MaterialPageRoute(builder: (_) => const SignupScreen());
            case '/video':
              // Video navigation is handled directly in VideoFeedPage
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/live-tv':
              return MaterialPageRoute(builder: (_) => const LiveTvPage());
            case '/programs':
              return MaterialPageRoute(builder: (_) => const ProgramsPage());
            case '/market-cap':
              return MaterialPageRoute(builder: (_) => const MarketCapPage());
            case '/chat':
              return MaterialPageRoute(builder: (_) => const CommunityChat());
            case '/extra-ai':
              return MaterialPageRoute(builder: (_) => const ExtraAiChat());
            case '/news':
              return MaterialPageRoute(builder: (_) => const NewsPage());
            case '/notifications':
              return MaterialPageRoute(builder: (_) => const NotificationScreen());
            case '/explore':
              return MaterialPageRoute(builder: (_) => const ExplorePage());
            case '/spin2earn':
              return MaterialPageRoute(builder: (_) => const Spin2EarnGamePage());
            case '/play-extra':
              return MaterialPageRoute(builder: (_) => const PlayExtraMain());
            default:
              return MaterialPageRoute(builder: (_) => const LoginScreen());
          }
        },
      ),
    );
  }
}

