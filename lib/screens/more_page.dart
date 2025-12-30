import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {

  // List of upcoming features
  final List<UpcomingFeature> upcomingFeatures = [
    const UpcomingFeature(
      name: 'Blockchain',
      description: 'Explore blockchain technology and innovations',
      icon: FeatherIcons.link,
      color: Color(0xFF1E40AF), // Blue
    ),
    const UpcomingFeature(
      name: 'Crypto',
      description: 'Cryptocurrency news, analysis, and insights',
      icon: FeatherIcons.dollarSign,
      color: Color(0xFFF59E0B), // Amber
    ),
    const UpcomingFeature(
      name: 'Esports',
      description: 'Gaming tournaments and esports coverage',
      icon: FeatherIcons.monitor,
      color: Color(0xFF7C3AED), // Purple
    ),
    const UpcomingFeature(
      name: 'AI',
      description: 'Artificial intelligence and machine learning',
      icon: FeatherIcons.zap,
      color: Color(0xFF059669), // Emerald
    ),
    const UpcomingFeature(
      name: 'Robotics',
      description: 'Robotics technology and automation',
      icon: FeatherIcons.cpu,
      color: Color(0xFFDC2626), // Red
    ),
    const UpcomingFeature(
      name: 'Trading',
      description: 'Trading tools, signals, and market analysis',
      icon: FeatherIcons.trendingUp,
      color: Color(0xFF059669), // Green
    ),
    const UpcomingFeature(
      name: 'Documentary',
      description: 'Tech documentaries and educational content',
      icon: FeatherIcons.film,
      color: Color(0xFF7C2D12), // Orange
    ),
    const UpcomingFeature(
      name: 'Summits',
      description: 'Tech conferences and summit coverage',
      icon: FeatherIcons.users,
      color: Color(0xFF1E40AF), // Blue
    ),
    const UpcomingFeature(
      name: 'Innovation',
      description: 'Latest tech innovations and breakthroughs',
      icon: FeatherIcons.star,
      color: Color(0xFFF59E0B), // Amber
    ),
    const UpcomingFeature(
      name: 'Airdrop',
      description: 'Cryptocurrency airdrops and token distributions',
      icon: FeatherIcons.gift,
      color: Color(0xFF7C3AED), // Purple
    ),
    const UpcomingFeature(
      name: 'Health Tech',
      description: 'Healthcare technology and digital health',
      icon: FeatherIcons.heart,
      color: Color(0xFFDC2626), // Red
    ),
    const UpcomingFeature(
      name: 'Agric Tech',
      description: 'Agricultural technology and smart farming',
      icon: FeatherIcons.sun,
      color: Color(0xFF059669), // Green
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'More Features',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF006833).withOpacity(0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF006833).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Exciting new features are on the way! Stay tuned for these amazing additions to CoinNewsExtra.',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                    height: 1.4,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006833).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF006833),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        FeatherIcons.clock,
                        color: Color(0xFF006833),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${upcomingFeatures.length} Features in Development',
                        style: const TextStyle(
                          color: Color(0xFF006833),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Features list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: upcomingFeatures.length,
              itemBuilder: (context, index) {
                final feature = upcomingFeatures[index];
                return _buildFeatureItem(context, feature, index);
              },
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Want to suggest a feature?',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    _showFeedbackDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006833),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Send Feedback',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, UpcomingFeature feature, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showFeaturePreview(context, feature);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Feature icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: feature.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: feature.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    feature.icon,
                    color: feature.color,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Feature details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            feature.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Lato',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Coming Soon',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature.description,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontFamily: 'Lato',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Arrow indicator
                Icon(
                  FeatherIcons.chevronRight,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFeaturePreview(BuildContext context, UpcomingFeature feature) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Feature header
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: feature.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: feature.color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            feature.icon,
                            color: feature.color,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                feature.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Lato',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'In Development',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Lato',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Description
                    Text(
                      feature.description,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 16,
                        height: 1.5,
                        fontFamily: 'Lato',
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Coming soon message
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006833).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF006833).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stay Tuned!',
                            style: TextStyle(
                              color: Color(0xFF006833),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lato',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This feature is currently in development. We\'ll notify you when it\'s ready!',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Send Feedback',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Have a feature request or suggestion? We\'d love to hear from you!',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(
                  FeatherIcons.mail,
                  color: Color(0xFF006833),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'feedback@coinnewsextra.com',
                  style: TextStyle(
                    color: Color(0xFF006833),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF006833),
                fontFamily: 'Lato',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UpcomingFeature {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const UpcomingFeature({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}