import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import '../theme/app_theme.dart';
import '../utils/external_link_helper.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _subjectCtl = TextEditingController();
  final _messageCtl = TextEditingController();

  // Content pulled from https://www.coinnewsextratv.africa/
  final String _email = 'support@coinnewsextratv.africa';
  final String _phone = '+234 905 625 3714';
  final String _address = '8 The Green, Suite ADover, DE 19901-3618, United States';
  final String _website = 'https://coinnewsextratv.africa';

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _subjectCtl.dispose();
    _messageCtl.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final subject = Uri.encodeComponent(_subjectCtl.text.trim());
    final body = Uri.encodeComponent('Name: ${_nameCtl.text.trim()}\nEmail: ${_emailCtl.text.trim()}\n\n${_messageCtl.text.trim()}');
    final mailto = 'mailto:$_email?subject=$subject&body=$body';
    await launchUrlWithDisclaimer(context, mailto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Contact'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: AppTheme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Get in Touch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(FeatherIcons.mail, color: Colors.white),
                        title: Text(_email, style: const TextStyle(color: Colors.white)),
                        onTap: () => launchUrlWithDisclaimer(context, 'mailto:$_email'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(FeatherIcons.phone, color: Colors.white),
                        title: Text(_phone, style: const TextStyle(color: Colors.white)),
                        onTap: () => launchUrlWithDisclaimer(context, 'tel:${_phone.replaceAll(' ', '')}'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(FeatherIcons.mapPin, color: Colors.white),
                        title: Text(_address, style: const TextStyle(color: Colors.white)),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(FeatherIcons.globe, color: Colors.white),
                        title: Text(_website, style: const TextStyle(color: Colors.white)),
                        onTap: () => launchUrlWithDisclaimer(context, _website),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text('Send us a message', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              Card(
                color: AppTheme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Full name'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailCtl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Email address'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter your email';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _subjectCtl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Subject'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a subject' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _messageCtl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Message'),
                          maxLines: 5,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a message' : null,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _sendEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Send Message'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Contact support@coinnewsextratv.africa • +234 905 625 3714',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
