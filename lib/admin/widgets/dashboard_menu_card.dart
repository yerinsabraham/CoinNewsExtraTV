import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';

class DashboardMenuCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int? badgeCount;
  final bool isEnabled;

  const DashboardMenuCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: isEnabled ? Colors.grey[900] : Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled 
                ? color.withOpacity(0.3)
                : Colors.grey[700]!,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Main content in positioned container
                    Positioned.fill(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Top section with icon and badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isEnabled 
                                      ? color.withOpacity(0.2)
                                      : Colors.grey[700],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  icon,
                                  color: isEnabled ? color : Colors.grey[500],
                                  size: 16,
                                ),
                              ),
                              if (badgeCount != null && badgeCount! > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    badgeCount! > 99 ? '99+' : badgeCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Lato',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 6),
                          
                          // Center section with title and description
                          Flexible(
                            fit: FlexFit.loose,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: isEnabled ? Colors.white : Colors.grey[500],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Lato',
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  description,
                                  style: TextStyle(
                                    color: isEnabled ? Colors.grey[400] : Colors.grey[600],
                                    fontSize: 9,
                                    fontFamily: 'Lato',
                                    height: 1.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Bottom section with arrow
                          Align(
                            alignment: Alignment.centerRight,
                            child: Icon(
                              FeatherIcons.arrowRight,
                              color: isEnabled ? color : Colors.grey[600],
                              size: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}