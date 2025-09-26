import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  // Sample program schedule data
  final Map<String, List<Map<String, String>>> _scheduleData = {
    'Today, September 24th': [
      {
        'time': '08:00',
        'title': 'Morning Market Update',
        'description': 'Daily crypto market analysis and news',
        'duration': '30 mins'
      },
      {
        'time': '12:00',
        'title': 'Midday Trading Signals',
        'description': 'Live trading analysis with expert insights',
        'duration': '45 mins'
      },
      {
        'time': '16:00',
        'title': 'Blockchain Education',
        'description': 'Learning session on blockchain technology',
        'duration': '60 mins'
      },
      {
        'time': '20:00',
        'title': 'Evening Wrap-up',
        'description': 'Daily market summary and tomorrow preview',
        'duration': '25 mins'
      },
    ],
    'Tomorrow, September 25th': [
      {
        'time': '08:00',
        'title': 'Global Market Overview',
        'description': 'International market trends and analysis',
        'duration': '30 mins'
      },
      {
        'time': '10:00',
        'title': 'DeFi Deep Dive',
        'description': 'Advanced DeFi protocols and strategies',
        'duration': '50 mins'
      },
      {
        'time': '14:00',
        'title': 'NFT Marketplace Tour',
        'description': 'Exploring trending NFT collections',
        'duration': '40 mins'
      },
      {
        'time': '18:00',
        'title': 'Live AMA Session',
        'description': 'Q&A with crypto industry experts',
        'duration': '90 mins'
      },
    ],
    'Thursday, September 26th': [
      {
        'time': '09:00',
        'title': 'Altcoin Spotlight',
        'description': 'Featured altcoins and their potential',
        'duration': '35 mins'
      },
      {
        'time': '15:00',
        'title': 'Technical Analysis Masterclass',
        'description': 'Chart patterns and trading indicators',
        'duration': '75 mins'
      },
      {
        'time': '19:00',
        'title': 'Crypto News Roundup',
        'description': 'Weekly digest of important crypto news',
        'duration': '45 mins'
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Program Schedule',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.calendar, color: Color(0xFF006833)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calendar integration coming soon!')),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _scheduleData.keys.length,
        itemBuilder: (context, dayIndex) {
          final dateKey = _scheduleData.keys.elementAt(dayIndex);
          final programs = _scheduleData[dateKey]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF006833).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF006833).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      FeatherIcons.calendar,
                      color: const Color(0xFF006833),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateKey,
                      style: const TextStyle(
                        color: Color(0xFF006833),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Program Items for this date
              ...programs.map((program) => _buildProgramItem(program)).toList(),
              
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgramItem(Map<String, String> program) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Time and Clock Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF006833).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FeatherIcons.clock,
                    color: const Color(0xFF006833),
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    program['time']!,
                    style: const TextStyle(
                      color: Color(0xFF006833),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Program Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program['title']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    program['description']!,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      program['duration']!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Button
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Set reminder for "${program['title']}"'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(
                FeatherIcons.bell,
                color: Colors.grey[500],
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
