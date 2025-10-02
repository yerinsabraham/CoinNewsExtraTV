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
          Text(
            'Services',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF00B359).withOpacity(0.2),
        highlightColor: const Color(0xFF00B359).withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2A2A2A),
                const Color(0xFF1F1F1F),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B359).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF00B359),
                  size: 18,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
