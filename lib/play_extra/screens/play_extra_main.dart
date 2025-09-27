import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'stats_screen.dart';
import 'room_screen.dart';
import 'battle_screen.dart';

class PlayExtraMain extends StatefulWidget {
  const PlayExtraMain({Key? key}) : super(key: key);

  @override
  State<PlayExtraMain> createState() => _PlayExtraMainState();
}

class _PlayExtraMainState extends State<PlayExtraMain> {
  int _selectedIndex = 0;
  
  void switchToBattleTab() {
    setState(() {
      _selectedIndex = 2; // Battle tab index
    });
  }
  
  List<Widget> get _screens => [
    const StatsScreen(),
    RoomScreen(onNavigateToBattle: switchToBattleTab),
    const BattleScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _screens[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border(
              top: BorderSide(color: const Color(0xFF006833), width: 2),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.grey[900],
            selectedItemColor: const Color(0xFF006833),
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: const TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Lato',
              fontSize: 12,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Stats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.meeting_room),
                label: 'Room',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.casino),
                label: 'Battle',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF006833), width: 2),
          ),
          title: Row(
            children: [
              Icon(
                Icons.sports_martial_arts,
                color: const Color(0xFF006833),
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quit Game?',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Do you want to quit this game?\n\nYour CNE coins and progress will be saved.',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Lato',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Stay in Game',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Lato',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006833),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Quit Game',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }
}
