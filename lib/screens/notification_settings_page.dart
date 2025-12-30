import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _enabled = true;
  List<Map<String, dynamic>> _scheduled = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadScheduled();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool('program_reminders_enabled') ?? true;
    });
  }

  Future<void> _setEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('program_reminders_enabled', v);
    setState(() => _enabled = v);
  }

  Future<void> _loadScheduled() async {
    final items = await NotificationService().getPersistedScheduledNotifications();
    setState(() => _scheduled = items);
  }

  Future<void> _cancelNotification(int id) async {
    await NotificationService().cancelScheduledNotification(id);
    await _loadScheduled();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Enable program reminders'),
              value: _enabled,
              onChanged: (v) => _setEnabled(v),
            ),
            const SizedBox(height: 12),
            const Text('Scheduled reminders', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _scheduled.isEmpty
                  ? const Center(child: Text('No scheduled reminders'))
                  : ListView.builder(
                      itemCount: _scheduled.length,
                      itemBuilder: (context, i) {
                        final s = _scheduled[i];
                        final time = DateTime.fromMillisecondsSinceEpoch(s['time']);
                        return ListTile(
                          title: Text(s['title'] ?? 'Reminder'),
                          subtitle: Text(time.toLocal().toString()),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _cancelNotification(s['id'] as int),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
