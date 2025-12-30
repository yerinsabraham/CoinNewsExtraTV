import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import '../models/spotlight_model.dart';
import '../services/spotlight_service.dart';
import 'spotlight_details_screen.dart';

class SpotlightScreen extends StatefulWidget {
  const SpotlightScreen({super.key});

  @override
  State<SpotlightScreen> createState() => _SpotlightScreenState();
}

class _SpotlightScreenState extends State<SpotlightScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<SpotlightCategory> _categories = SpotlightCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'Spotlight',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.search, color: Colors.white),
            onPressed: () => _showSearchDialog(),
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
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                fontFamily: 'Lato',
              ),
              tabs: _categories.map((category) {
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
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          return SpotlightCategoryView(category: category);
        }).toList(),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => const SpotlightSearchDialog(),
    );
  }
}

class SpotlightCategoryView extends StatelessWidget {
  final SpotlightCategory category;

  const SpotlightCategoryView({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SpotlightItem>>(
      stream: SpotlightService.getSpotlightItemsByCategory(category),
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
                  'Error loading ${category.displayName}',
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
                  'No ${category.displayName} available yet',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for exciting new opportunities!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: Colors.amber,
          onRefresh: () async {
            // Trigger rebuild to refresh data
            (context as Element).markNeedsBuild();
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.58, // Further reduced to fix overflow completely
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return SpotlightItemCard(item: items[index]);
            },
          ),
        );
      },
    );
  }
}

class SpotlightItemCard extends StatelessWidget {
  final SpotlightItem item;

  const SpotlightItemCard({
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpotlightDetailsScreen(item: item),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section - Fixed height instead of flex
            SizedBox(
              height: 100, // Fixed height for consistency
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: Colors.grey[800],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      item.imageUrl.startsWith('assets/')
                          ? Image.asset(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: Icon(
                                    FeatherIcons.image,
                                    color: Colors.grey[500],
                                    size: 32,
                                  ),
                                );
                              },
                            )
                          : Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: Icon(
                                    FeatherIcons.image,
                                    color: Colors.grey[500],
                                    size: 32,
                                  ),
                                );
                              },
                            ),
                      if (item.isFeatured)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'FEATURED',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ),
                        ),
                      // Category badge
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(item.category).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category.displayName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Content section - Expanded to fill remaining space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title - Fixed height
                    SizedBox(
                      height: 32, // Fixed height for title (2 lines max)
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Short description - Flexible but limited
                    Flexible(
                      child: Text(
                        item.shortDescription,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                          fontFamily: 'Lato',
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // CTA button - Fixed at bottom
                    SizedBox(
                      width: double.infinity,
                      height: 26,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SpotlightDetailsScreen(item: item),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getCategoryColor(item.category),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: EdgeInsets.zero,
                          elevation: 0,
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
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
}

class SpotlightSearchDialog extends StatefulWidget {
  const SpotlightSearchDialog({super.key});

  @override
  State<SpotlightSearchDialog> createState() => _SpotlightSearchDialogState();
}

class _SpotlightSearchDialogState extends State<SpotlightSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  Stream<List<SpotlightItem>>? _searchResults;

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = null);
      return;
    }

    setState(() {
      _searchResults = SpotlightService.searchSpotlightItems(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search header
            Row(
              children: [
                const Text(
                  'Search Spotlight',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Search field
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search brands, apps, airdrops...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(FeatherIcons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _performSearch,
            ),
            
            const SizedBox(height: 16),
            
            // Search results
            Expanded(
              child: _searchResults == null
                  ? Center(
                      child: Text(
                        'Enter a search term to find spotlight items',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontFamily: 'Lato',
                        ),
                      ),
                    )
                  : StreamBuilder<List<SpotlightItem>>(
                      stream: _searchResults,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.amber),
                          );
                        }

                        final items = snapshot.data ?? [];
                        
                        if (items.isEmpty) {
                          return Center(
                            child: Text(
                              'No results found',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontFamily: 'Lato',
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(item.imageUrl),
                                backgroundColor: Colors.grey[800],
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Lato',
                                ),
                              ),
                              subtitle: Text(
                                item.category.displayName,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontFamily: 'Lato',
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SpotlightDetailsScreen(item: item),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}