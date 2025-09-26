import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';

class QuickFeatureRow extends StatelessWidget {
  const QuickFeatureRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLiveTvFeatureItem(context),
          _buildFeatureItem(
            context,
            icon: FeatherIcons.messageCircle,
            label: 'Chat',
            onTap: () {
              // Navigate to Chat screen
              Navigator.pushNamed(context, '/chat');
            },
          ),
          _buildFeatureItem(
            context,
            icon: FeatherIcons.cpu, 
            label: 'Extra AI',
            onTap: () {
              // Navigate to AI Chat screen
              Navigator.pushNamed(context, '/extra-ai');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTvFeatureItem(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/live-tv');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              FeatherIcons.tv,
              color: Colors.red,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Live TV',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF006833).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF006833),
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Lato',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


}