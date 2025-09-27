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
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
              children: [
              _buildGridItem(
                context,
                icon: FeatherIcons.trendingUp,
                label: 'Market Cap',
                onTap: () {
                  Navigator.pushNamed(context, '/market-cap');
                },
              ),
              _buildGridItem(
                context,
                icon: FeatherIcons.compass,
                label: 'Explore',
                onTap: () {
                  Navigator.pushNamed(context, '/explore');
                },
              ),
              _buildGridItem(
                context,
                icon: FeatherIcons.fileText,
                label: 'News',
                onTap: () {
                  Navigator.pushNamed(context, '/news');
                },
              ),
              _buildGridItem(
                context,
                icon: FeatherIcons.target,
                label: 'Spin2Earn',
                onTap: () {
                  Navigator.pushNamed(context, '/spin2earn');
                },
              ),
              _buildGridItem(
                context,
                icon: FeatherIcons.calendar,
                label: 'Summit',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Crypto summit events coming soon!')),
                  );
                },
              ),
              _buildGridItem(
                context,
                icon: FeatherIcons.play,
                label: 'Play Extra',
                onTap: () {
                  Navigator.pushNamed(context, '/play-extra');
                },
              ),
              _buildGridItem(
                context,
                icon: FeatherIcons.helpCircle,
                label: 'Quiz',
                onTap: () {
                  Navigator.pushNamed(context, '/quiz');
                },
              ),
              _buildGridItem(
                context,
                icon: FeatherIcons.moreHorizontal,
                label: 'More',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('More features coming soon!')),
                  );
                },
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF006833).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF006833),
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              fontFamily: 'Lato',
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


}
