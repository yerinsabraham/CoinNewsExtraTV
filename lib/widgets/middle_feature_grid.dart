import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';

class MiddleFeatureGrid extends StatelessWidget {
  const MiddleFeatureGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
              children: [
                _buildGridItem(
                  context,
                  icon: FeatherIcons.trendingUp,
                  label: 'Market',
                  onTap: () => Navigator.pushNamed(context, '/market-cap'),
                ),
                _buildGridItem(
                  context,
                  icon: FeatherIcons.compass,
                  label: 'Explore',
                  onTap: () => Navigator.pushNamed(context, '/explore'),
                ),
                _buildGridItem(
                  context,
                  icon: FeatherIcons.fileText,
                  label: 'News',
                  onTap: () => Navigator.pushNamed(context, '/news'),
                ),
                _buildGridItem(
                  context,
                  icon: FeatherIcons.target,
                  label: 'Spin2Earn',
                  onTap: () => Navigator.pushNamed(context, '/spin-game'),
                ),
                _buildGridItem(
                  context,
                  icon: FeatherIcons.calendar,
                  label: 'Summit',
                  onTap: () => Navigator.pushNamed(context, '/summit'),
                ),
                _buildGridItem(
                  context,
                  icon: FeatherIcons.play,
                  label: 'Program',
                  onTap: () => Navigator.pushNamed(context, '/program'),
                ),
                _buildGridItem(
                  context,
                  icon: FeatherIcons.helpCircle,
                  label: 'Quiz',
                  onTap: () => Navigator.pushNamed(context, '/quiz'),
                ),
                _buildGridItem(
                  context,
                  icon: FeatherIcons.moreHorizontal,
                  label: 'More',
                  onTap: () => Navigator.pushNamed(context, '/more'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFF006833),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontFamily: 'Lato',
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: const Color(0xFF006833),
      ),
    );
  }
}
