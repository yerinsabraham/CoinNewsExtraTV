import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

// The Cloud Function URL can be provided at build/run time via
// --dart-define=OPENAI_FUNCTION_URL=https://us-central1-.../askOpenAI
// Default to the deployed function so the app works without extra flags.
const String _openaiFunctionUrl = String.fromEnvironment(
  'OPENAI_FUNCTION_URL',
  defaultValue: 'https://askopenai-ftg3tdhi7q-uc.a.run.app',
);

class OpenAIService {
  // In production, this should be stored securely (environment variables, Firebase config, etc.)
  // Allow overriding the API key at build/run time with --dart-define=OPENAI_API_KEY=sk-...
  // This avoids hardcoding secrets in source for devs who prefer that.
  // No client-side OpenAI API key required — calls are proxied via the
  // deployed Cloud Function which holds the secret server-side.

  Future<String> sendMessage(String message,
      {bool includeSources = true, bool preferConcise = true}) async {
    // The app proxies all OpenAI calls to the server-side Cloud Function.
    // No client-side OpenAI key is required.

    // System prompt: prioritize direct factual answers across technology
    // domains. If `preferConcise` is true, answer the question in the
    // first sentence and keep replies short (1-3 sentences). If
    // `preferConcise` is false, allow a more detailed response (up to
    // three short paragraphs).
    final systemPrompt = StringBuffer();
    systemPrompt.writeln(
        'You are CNETV AI — a factual assistant for technology, blockchain, fintech, AI research, health-tech, and general software topics.');

    // Use the server-side Cloud Function proxy if configured
    if (_openaiFunctionUrl.isEmpty) {
      return 'OpenAI function URL not configured. Provide --dart-define=OPENAI_FUNCTION_URL=<url>';
    }

    // Ensure we have a signed-in Firebase user. If none, attempt anonymous sign-in
    // so the app can obtain an ID token and call the server-side proxy automatically.
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        final cred = await FirebaseAuth.instance.signInAnonymously();
        user = cred.user;
      } catch (e) {
        debugPrint('Anonymous sign-in failed: $e');
        return 'Authentication required. Please enable anonymous sign-in in Firebase or sign in to use Extra AI.';
      }
    }
    final idToken = await user!.getIdToken();

    try {
      final resp = await http.post(
        Uri.parse(_openaiFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'prompt': message,
          'preferConcise': preferConcise,
          'includeSources': includeSources,
          'max_tokens': 500,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return (data['answer'] ?? '').toString().trim();
      } else {
        debugPrint('OpenAI Function Error: ${resp.statusCode} - ${resp.body}');
        return _getErrorResponse();
      }
    } catch (e, st) {
      debugPrint('Failed calling OpenAI function: $e\n$st');
      return _getErrorResponse();
    }
  }

  String _getErrorResponse() {
    // Return a marker message that the app can detect and fall back to local responses
    return "Sorry, I'm having trouble connecting to the AI service right now.";
  }
}
