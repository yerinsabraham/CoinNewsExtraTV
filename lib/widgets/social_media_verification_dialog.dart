import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/social_media_verification_service.dart';

class SocialMediaVerificationDialog extends StatefulWidget {
  final Map<String, dynamic> platform;
  final VoidCallback? onVerificationComplete;

  const SocialMediaVerificationDialog({
    super.key,
    required this.platform,
    this.onVerificationComplete,
  });

  @override
  State<SocialMediaVerificationDialog> createState() => _SocialMediaVerificationDialogState();
}

class _SocialMediaVerificationDialogState extends State<SocialMediaVerificationDialog> {
  final TextEditingController _proofController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasVisitedPlatform = false;
  VerificationStatus? _currentStatus;

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  @override
  void dispose() {
    _proofController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentStatus() async {
    final status = await SocialMediaVerificationService.getVerificationStatus(
      widget.platform['id'],
    );
    setState(() {
      _currentStatus = status;
    });
  }

  Future<void> _visitPlatform() async {
    final url = widget.platform['url'] as String;
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        setState(() {
          _hasVisitedPlatform = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening ${widget.platform['displayName']}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyUrl() async {
    final url = widget.platform['url'] as String;
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL copied to clipboard!'),
          backgroundColor: Color(0xFF006833),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _submitVerification() async {
    if (_proofController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide verification proof'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await SocialMediaVerificationService.submitVerificationProof(
        platformId: widget.platform['id'],
        proofText: _proofController.text.trim(),
      );

      if (result.success) {
        if (mounted) {
          // Refresh status
          await _loadCurrentStatus();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: const Color(0xFF006833),
              duration: const Duration(seconds: 3),
            ),
          );

          // If auto-approved (like Telegram), close the dialog and refresh parent
          if (result.status == 'approved') {
            widget.onVerificationComplete?.call();
            Navigator.of(context).pop();
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getPlatformIcon(widget.platform['id']),
                  color: const Color(0xFF006833),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Verify ${widget.platform['displayName']} Follow',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Current Status
            if (_currentStatus != null) ...[
              _buildStatusWidget(_currentStatus!),
              const SizedBox(height: 16),
            ],
            
            // Instructions
            if (_currentStatus?.status != 'completed') ...[
              Text(
                'Follow these steps:',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lato',
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Step 1: Visit Platform
              _buildStepWidget(
                stepNumber: 1,
                title: 'Visit ${widget.platform['displayName']}',
                description: 'Click below to open ${widget.platform['displayName']} and follow our account',
                actionWidget: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _visitPlatform,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text('Open ${widget.platform['displayName']}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006833),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _copyUrl,
                      icon: const Icon(Icons.copy, color: Colors.white70),
                      tooltip: 'Copy URL',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Step 2: Follow and Interact
              _buildStepWidget(
                stepNumber: 2,
                title: 'Follow and Interact',
                description: widget.platform['proofInstructions'] ?? 
                    'Follow our account and interact with our latest content',
              ),
              
              const SizedBox(height: 16),
              
              // Step 3: Provide Proof
              if (_hasVisitedPlatform || _currentStatus?.isPending == true) ...[
                _buildStepWidget(
                  stepNumber: 3,
                  title: 'Provide Verification Proof',
                  description: _getProofDescription(widget.platform['id']),
                  actionWidget: Column(
                    children: [
                      TextField(
                        controller: _proofController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: _getProofHint(widget.platform['id']),
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF006833)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting || _currentStatus?.isPending == true 
                              ? null 
                              : _submitVerification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006833),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _currentStatus?.isPending == true 
                                      ? 'Verification Pending'
                                      : 'Submit Verification',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            
            // Reward Information
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF006833).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF006833).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Color(0xFF006833),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Reward: +${widget.platform['reward']} CNE',
                    style: const TextStyle(
                      color: Color(0xFF006833),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
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

  Widget _buildStatusWidget(VerificationStatus status) {
    Color statusColor;
    IconData statusIcon;
    
    switch (status.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'approved':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'completed':
        statusColor = const Color(0xFF006833);
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status.message,
              style: TextStyle(
                color: statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Lato',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepWidget({
    required int stepNumber,
    required String title,
    required String description,
    Widget? actionWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF006833),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lato',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontFamily: 'Lato',
                ),
              ),
              if (actionWidget != null) ...[
                const SizedBox(height: 8),
                actionWidget,
              ],
            ],
          ),
        ),
      ],
    );
  }

  IconData _getPlatformIcon(String platformId) {
    switch (platformId.toLowerCase()) {
      case 'twitter':
        return Icons.alternate_email;
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      case 'youtube':
        return Icons.play_circle_outline;
      case 'linkedin':
        return Icons.business;
      case 'telegram':
        return Icons.send;
      default:
        return Icons.link;
    }
  }

  String _getProofDescription(String platformId) {
    switch (platformId.toLowerCase()) {
      case 'twitter':
        return 'Enter your Twitter username (without @) to verify your follow';
      case 'instagram':
        return 'Enter your Instagram username (without @) to verify your follow';
      case 'facebook':
        return 'Enter your Facebook profile name or URL to verify your follow';
      case 'youtube':
        return 'Enter your YouTube channel name to verify your subscription';
      case 'linkedin':
        return 'Enter your LinkedIn profile URL to verify your follow';
      case 'telegram':
        return 'Simply join our channel - verification is automatic';
      default:
        return 'Enter your username or profile information for verification';
    }
  }

  String _getProofHint(String platformId) {
    switch (platformId.toLowerCase()) {
      case 'twitter':
        return 'e.g., john_doe';
      case 'instagram':
        return 'e.g., john.doe';
      case 'facebook':
        return 'e.g., John Doe or facebook.com/john.doe';
      case 'youtube':
        return 'e.g., John\'s Channel';
      case 'linkedin':
        return 'e.g., linkedin.com/in/johndoe';
      case 'telegram':
        return 'Just join the channel';
      default:
        return 'Enter your profile information';
    }
  }
}
