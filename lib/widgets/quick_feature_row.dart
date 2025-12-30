import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';

class QuickFeatureRow extends StatelessWidget {
  final GlobalKey? liveTvKey;
  final GlobalKey? chatKey;
  final GlobalKey? extraAiKey;
  final GlobalKey? spotlightKey;

  const QuickFeatureRow({
    super.key,
    this.liveTvKey,
    this.chatKey,
    this.extraAiKey,
    this.spotlightKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF0F0F0F),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLiveTvFeatureItem(context),
          _buildFeatureItem(
            context,
            key: chatKey,
            icon: FeatherIcons.messageCircle,
            label: 'Chat',
            onTap: () {
              Navigator.pushNamed(context, '/chat');
            },
          ),
          _buildFeatureItem(
            context,
            key: extraAiKey,
            icon: FeatherIcons.cpu, 
            label: 'Extra AI',
            onTap: () {
              Navigator.pushNamed(context, '/extra-ai');
            },
          ),
          _buildSpotlightFeatureItem(context),
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
            key: liveTvKey,
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

  Widget _buildSpotlightFeatureItem(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/spotlight');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: spotlightKey,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber.withOpacity(0.3),
                  Colors.orange.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              FeatherIcons.star,
              color: Colors.amber,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Spotlight',
            style: TextStyle(
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

  Widget _buildFeatureItem(
    BuildContext context, {
    Key? key,
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
            key: key,
            // Note: chat/extra ai keys are set in parent when appropriate
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
