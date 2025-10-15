import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import '../../models/spotlight_model.dart';
import '../../services/spotlight_service.dart';
import 'spotlight_add_edit_screen.dart';

class SpotlightManagementScreen extends StatefulWidget {
  const SpotlightManagementScreen({super.key});

  @override
  State<SpotlightManagementScreen> createState() => _SpotlightManagementScreenState();
}

class _SpotlightManagementScreenState extends State<SpotlightManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<SpotlightCategory> _categories = SpotlightCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(SpotlightCategory category) {
    switch (category) {
      case SpotlightCategory.airdrops:
        return Colors.purple;
      case SpotlightCategory.crypto:
        return Colors.orange;
      case SpotlightCategory.ai:
        return Colors.blue;
      case SpotlightCategory.fintech:
        return Colors.green;
    }
  }

  IconData _getCategoryIcon(SpotlightCategory category) {
    switch (category) {
      case SpotlightCategory.airdrops:
        return FeatherIcons.gift;
      case SpotlightCategory.crypto:
        return FeatherIcons.trendingUp;
      case SpotlightCategory.ai:
        return FeatherIcons.cpu;
      case SpotlightCategory.fintech:
        return FeatherIcons.creditCard;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Spotlight Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.plus, color: Colors.white),
            onPressed: () => _navigateToAddSpotlight(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.amber,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[400],
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
              tabs: [
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FeatherIcons.list, size: 16),
                      SizedBox(width: 6),
                      Text('All Items'),
                    ],
                  ),
                ),
                ..._categories.map((category) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          size: 16,
                          color: _getCategoryColor(category),
                        ),
                        const SizedBox(width: 6),
                        Text(category.displayName),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All items tab
          SpotlightManagementList(category: null),
          // Category-specific tabs
          ..._categories.map((category) {
            return SpotlightManagementList(category: category);
          }).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddSpotlight(),
        backgroundColor: Colors.amber,
        child: const Icon(FeatherIcons.plus, color: Colors.black),
      ),
    );
  }

  void _navigateToAddSpotlight() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SpotlightAddEditScreen(),
      ),
    );
  }
}

class SpotlightManagementList extends StatelessWidget {
  final SpotlightCategory? category;

  const SpotlightManagementList({
    super.key,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SpotlightItem>>(
      stream: category == null
          ? SpotlightService.getAllSpotlightItemsForAdmin()
          : SpotlightService.getSpotlightItemsByCategory(category!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FeatherIcons.alertCircle, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Error loading spotlight items',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => (context as Element).markNeedsBuild(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          final categoryText = category?.displayName ?? 'spotlight items';
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FeatherIcons.star,
                  size: 48,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'No $categoryText yet',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first spotlight item to get started!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SpotlightAddEditScreen(),
                      ),
                    );
                  },
                  icon: const Icon(FeatherIcons.plus),
                  label: const Text('Add Spotlight Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: Colors.amber,
          onRefresh: () async {
            (context as Element).markNeedsBuild();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return SpotlightManagementCard(item: items[index]);
            },
          ),
        );
      },
    );
  }
}

class SpotlightManagementCard extends StatelessWidget {
  final SpotlightItem item;

  const SpotlightManagementCard({
    super.key,
    required this.item,
  });

  Color _getCategoryColor(SpotlightCategory category) {
    switch (category) {
      case SpotlightCategory.airdrops:
        return Colors.purple;
      case SpotlightCategory.crypto:
        return Colors.orange;
      case SpotlightCategory.ai:
        return Colors.blue;
      case SpotlightCategory.fintech:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isActive ? Colors.grey[700]! : Colors.red[900]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[800],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      FeatherIcons.image,
                      color: Colors.grey[500],
                      size: 20,
                    );
                  },
                ),
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(item.category).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.category.displayName,
                        style: TextStyle(
                          color: _getCategoryColor(item.category),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.isActive ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          color: item.isActive ? Colors.green : Colors.red,
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
                  item.shortDescription,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(FeatherIcons.moreVertical, color: Colors.white),
              color: Colors.grey[800],
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(FeatherIcons.edit2, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text('Edit', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_status',
                  child: Row(
                    children: [
                      Icon(
                        item.isActive ? FeatherIcons.eyeOff : FeatherIcons.eye,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.isActive ? 'Deactivate' : 'Activate',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_featured',
                  child: Row(
                    children: [
                      Icon(
                        FeatherIcons.star,
                        color: item.isFeatured ? Colors.amber : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.isFeatured ? 'Unfeature' : 'Feature',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(FeatherIcons.trash2, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpotlightAddEditScreen(item: item),
          ),
        );
        break;
      case 'toggle_status':
        _toggleStatus(context);
        break;
      case 'toggle_featured':
        _toggleFeatured(context);
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  void _toggleStatus(BuildContext context) async {
    final success = await SpotlightService.toggleSpotlightItemStatus(
      item.id,
      !item.isActive,
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleFeatured(BuildContext context) async {
    final success = await SpotlightService.toggleFeaturedStatus(
      item.id,
      !item.isFeatured,
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update featured status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Spotlight Item',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${item.title}"? This action cannot be undone.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await SpotlightService.deleteSpotlightItem(item.id);
              
              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete item'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}