import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a short disclaimer dialog before launching an external URL.
/// Returns true if the URL was launched.
Future<bool> launchUrlWithDisclaimer(BuildContext context, String urlString) async {
  if (urlString.isEmpty) return false;

  final Uri uri = Uri.parse(urlString);

  final bool proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            title: const Text('You are leaving the app'),
            content: const Text(
              'This link opens an external website. CoinNewsExtra is not responsible for external content. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      ) ??
      false;

  if (!proceed) return false;

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return true;
  }

  // Show a simple snackbar if launch fails
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not launch URL')),
    );
  }

  return false;
}
