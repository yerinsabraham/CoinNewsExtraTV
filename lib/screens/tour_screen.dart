import 'package:flutter/material.dart';
import '../services/first_launch_service.dart';

class TourScreen extends StatefulWidget {
  const TourScreen({super.key});

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  final PageController _controller = PageController();
  int _current = 0;

  final List<Map<String, String>> _steps = [
    {'title': 'Live TV', 'desc': 'Watch live blockchain news and earn rewards.'},
    {'title': 'ExtraAI', 'desc': 'AI-powered summaries and insights.'},
    {'title': 'Market Cap', 'desc': 'Track top cryptocurrencies and market data.'},
    {'title': 'News', 'desc': 'Curated crypto & fintech headlines.'},
    {'title': 'Spin to Earn', 'desc': 'Play games and win CNE tokens.'},
    {'title': 'Summit', 'desc': 'Attend virtual events and panels.'},
    {'title': 'Play Extra', 'desc': 'Extra mini-games and experiences.'},
    {'title': 'Quiz', 'desc': 'Test your knowledge and earn rewards.'},
  ];

  void _next() {
    if (_current < _steps.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      FirstLaunchService().setSeenIntro();
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _skip() {
    FirstLaunchService().setSeenIntro();
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tv,
                          size: 96,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(step['title']!, style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 12),
                        Text(step['desc']!, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
              child: Row(
                children: [
                  // Skip button on the left
                  TextButton(onPressed: _skip, child: const Text('Skip Tour')),

                  // Centered dots that can shrink if space is limited
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_steps.length, (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: CircleAvatar(radius: 4, backgroundColor: i == _current ? Theme.of(context).colorScheme.primary : Colors.grey),
                        )),
                      ),
                    ),
                  ),

                  // Next/Finish button on the right
                  ElevatedButton(
                    onPressed: () => _next(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                      child: Text(_current == _steps.length - 1 ? 'Finish' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
