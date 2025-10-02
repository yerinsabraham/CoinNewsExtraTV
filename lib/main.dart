import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/earning_page.dart';
import 'screens/youtube_page.dart';
import 'screens/spin_game_page.dart';
import 'screens/daily_checkin_page.dart';
import 'screens/quiz_page.dart';
import 'screens/wallet_page.dart';
import 'screens/watch_videos_page.dart';
import 'screens/live_tv_page.dart';
import 'screens/video_detail_page.dart';
import 'screens/chat_page.dart';
import 'screens/extra_ai_page.dart';
import 'screens/live_stream_page.dart';
import 'screens/news_page.dart';
import 'screens/market_cap_page.dart';
import 'screens/more_page.dart';
import 'screens/summit_page.dart';
import 'screens/explore_page.dart';
import 'screens/program_page.dart';
import 'provider/admin_provider.dart'; 
import 'services/user_balance_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase Analytics
  FirebaseAnalytics.instance;
  
  runApp(const Watch2EarnApp());
}

class Watch2EarnApp extends StatelessWidget {
  const Watch2EarnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AdminProvider()),
        ChangeNotifierProvider(create: (context) => UserBalanceService()),
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
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return const HomeScreen();
            }
            return const LoginScreen();
          },
        ),
        routes: {
          '/auth': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/signup': (context) => const SignupScreen(),
          '/earning': (context) => const EarningPage(),
          '/youtube': (context) => const YoutubePage(),
          '/spin-game': (context) => const SpinGamePage(),
          '/daily-checkin': (context) => const DailyCheckinPage(),
          '/quiz': (context) => const QuizPage(),
          '/wallet': (context) => const WalletPage(),
          '/watch-videos': (context) => const WatchVideosPage(),
          '/live-tv': (context) => const LiveTvPage(),
          '/chat': (context) => const ChatPage(),
          '/extra-ai': (context) => const ExtraAIPage(),
          '/live-stream': (context) => const LiveStreamPage(
            streamId: 'live_stream_001',
            title: 'CoinNewsExtra Live',
            description: 'Watch our live crypto news and analysis stream to earn rewards!',
          ),
          '/news': (context) => const NewsPage(),
          '/market-cap': (context) => const MarketCapPage(),
          '/more': (context) => const MorePage(),
          '/summit': (context) => const SummitPage(),
          '/explore': (context) => const ExplorePage(),
          '/program': (context) => const ProgramPage(),
        },
      ),
    );
  }
}
