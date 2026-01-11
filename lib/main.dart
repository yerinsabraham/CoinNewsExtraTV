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
import 'screens/spotlight_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/tour_screen.dart';
import 'screens/referral_page.dart';
// TEMPORARILY DISABLED: play_extra has compilation errors
// import 'play_extra/screens/play_extra_main.dart';
import 'provider/admin_provider.dart';
import 'services/user_balance_service.dart';
import 'services/first_launch_service.dart';
import 'services/notification_service.dart';
import 'provider/theme_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Analytics
  FirebaseAnalytics.instance;

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService().initialize();

  // Check first-launch intro flag
  final firstLaunchService = FirstLaunchService();
  final seenIntro = await firstLaunchService.hasSeenIntro();

  runApp(Watch2EarnApp(showIntro: !seenIntro));
}

class Watch2EarnApp extends StatelessWidget {
  final bool showIntro;

  const Watch2EarnApp({super.key, this.showIntro = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AdminProvider()),
        ChangeNotifierProvider(create: (context) => UserBalanceService()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CoinNewsExtra TV',
          themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData.light().copyWith(
            useMaterial3: true,
            primaryColor: const Color(0xFF006833),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00B359),
              primaryContainer: Color(0xFF006833),
              secondary: Color(0xFF4CAF50),
              secondaryContainer: Color(0xFF1B5E20),
              surface: Colors.white,
              surfaceVariant: Color(0xFFF6F6F6),
              onPrimary: Colors.white,
              onSurface: Colors.black,
              onSurfaceVariant: Color(0xFF333333),
              outline: Color(0xFFCCCCCC),
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF0A0A0A),
            primaryColor: const Color(0xFF006833),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00B359),
              primaryContainer: Color(0xFF006833),
              secondary: Color(0xFF4CAF50),
              secondaryContainer: Color(0xFF1B5E20),
              surface: Color(0xFF1A1A1A),
              surfaceVariant: Color(0xFF2A2A2A),
              onPrimary: Colors.white,
              onSurface: Colors.white,
              onSurfaceVariant: Color(0xFFE0E0E0),
              outline: Color(0xFF404040),
            ),
          ),
          home: Builder(builder: (context) {
            // If user is not logged in and this is first-launch, show welcome
            if (showIntro) return const WelcomeScreen();
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return const HomeScreen();
                }
                return const LoginScreen();
              },
            );
          }),
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
                  description:
                      'Watch our live crypto news and analysis stream to earn rewards!',
                ),
            '/news': (context) => const NewsPage(),
            '/market-cap': (context) => const MarketCapPage(),
            '/more': (context) => const MorePage(),
            '/summit': (context) => const SummitPage(),
            '/explore': (context) => const ExplorePage(),
            '/program': (context) => const ProgramPage(),
            '/spotlight': (context) => const SpotlightScreen(),
            '/welcome': (context) => const WelcomeScreen(),
            '/tour': (context) => const TourScreen(),
            // TEMPORARILY DISABLED: play_extra has compilation errors
            // '/play-extra': (context) => const PlayExtraMain(),
            '/referral': (context) => const ReferralPage(),
          },
        );
      }),
    );
  }
}
