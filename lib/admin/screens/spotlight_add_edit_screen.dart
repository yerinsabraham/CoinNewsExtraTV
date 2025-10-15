import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import '../../models/spotlight_model.dart';
import '../../services/spotlight_service.dart';

class SpotlightAddEditScreen extends StatefulWidget {
  final SpotlightItem? item;

  const SpotlightAddEditScreen({
    super.key,
    this.item,
  });

  @override
  State<SpotlightAddEditScreen> createState() => _SpotlightAddEditScreenState();
}

class _SpotlightAddEditScreenState extends State<SpotlightAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _bannerUrlController = TextEditingController();
  final _ctaTextController = TextEditingController();
  final _ctaLinkController = TextEditingController();
  final _priorityController = TextEditingController();

  SpotlightCategory _selectedCategory = SpotlightCategory.crypto;
  bool _isActive = true;
  bool _isFeatured = false;
  List<String> _galleryImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _populateFields(widget.item!);
    } else {
      // Set default values for new items
      _ctaTextController.text = 'Learn More';
      _priorityController.text = '0';
    }
  }

  void _populateFields(SpotlightItem item) {
    _titleController.text = item.title;
    _shortDescriptionController.text = item.shortDescription;
    _descriptionController.text = item.description;
    _imageUrlController.text = item.imageUrl;
    _bannerUrlController.text = item.bannerUrl ?? '';
    _ctaTextController.text = item.ctaText;
    _ctaLinkController.text = item.ctaLink;
    _priorityController.text = item.priority.toString();
    _selectedCategory = item.category;
    _isActive = item.isActive;
    _isFeatured = item.isFeatured;
    _galleryImages = List<String>.from(item.galleryImages);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _bannerUrlController.dispose();
    _ctaTextController.dispose();
    _ctaLinkController.dispose();
    _priorityController.dispose();
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
    final isEditing = widget.item != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Spotlight Item' : 'Add Spotlight Item',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.amber,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveItem,
              child: Text(
                isEditing ? 'Update' : 'Create',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Section
              _buildSectionHeader('Basic Information'),
              _buildTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'Enter spotlight title',
                icon: FeatherIcons.type,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Category Selection
              _buildCategorySelector(),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _shortDescriptionController,
                label: 'Short Description',
                hint: 'Brief description (1-2 lines)',
                icon: FeatherIcons.alignLeft,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Short description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _descriptionController,
                label: 'Full Description',
                hint: 'Detailed description of the product/service',
                icon: FeatherIcons.fileText,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Media Section
              _buildSectionHeader('Media & Images'),
              _buildTextField(
                controller: _imageUrlController,
                label: 'Primary Image URL',
                hint: 'https://example.com/image.jpg',
                icon: FeatherIcons.image,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Image URL is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _bannerUrlController,
                label: 'Banner Image URL (Optional)',
                hint: 'https://example.com/banner.jpg',
                icon: FeatherIcons.image,
              ),
              const SizedBox(height: 16),

              // Gallery Images
              _buildGallerySection(),
              const SizedBox(height: 32),

              // Call-to-Action Section
              _buildSectionHeader('Call-to-Action'),
              _buildTextField(
                controller: _ctaTextController,
                label: 'CTA Button Text',
                hint: 'Download App, Visit Website, Join Airdrop',
                icon: FeatherIcons.mousePointer,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'CTA text is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _ctaLinkController,
                label: 'CTA Link',
                hint: 'https://example.com',
                icon: FeatherIcons.link,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'CTA link is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Settings Section
              _buildSectionHeader('Settings'),
              _buildTextField(
                controller: _priorityController,
                label: 'Priority',
                hint: '0 (higher numbers = higher priority)',
                icon: FeatherIcons.barChart2,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final priority = int.tryParse(value);
                    if (priority == null) {
                      return 'Priority must be a number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Status Switches
              _buildSwitchTile(
                title: 'Active',
                subtitle: 'Make this spotlight item visible to users',
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                icon: FeatherIcons.eye,
              ),
              
              _buildSwitchTile(
                title: 'Featured',
                subtitle: 'Highlight this item as featured',
                value: _isFeatured,
                onChanged: (value) => setState(() => _isFeatured = value),
                icon: FeatherIcons.star,
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing ? 'Update Spotlight Item' : 'Create Spotlight Item',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Lato',
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        labelStyle: TextStyle(color: Colors.grey[400]),
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.amber),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FeatherIcons.tag, color: Colors.grey[400], size: 16),
              const SizedBox(width: 8),
              Text(
                'Category',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontFamily: 'Lato',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SpotlightCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _getCategoryColor(category).withOpacity(0.2)
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? _getCategoryColor(category)
                          : Colors.grey[600]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: isSelected
                            ? _getCategoryColor(category)
                            : Colors.grey[400],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category.displayName,
                        style: TextStyle(
                          color: isSelected
                              ? _getCategoryColor(category)
                              : Colors.grey[400],
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontFamily: 'Lato',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FeatherIcons.image, color: Colors.grey[400], size: 16),
              const SizedBox(width: 8),
              Text(
                'Gallery Images (Optional)',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontFamily: 'Lato',
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _addGalleryImage,
                icon: const Icon(FeatherIcons.plus, color: Colors.amber, size: 16),
              ),
            ],
          ),
          if (_galleryImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...List.generate(_galleryImages.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _galleryImages[index],
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 12,
                          fontFamily: 'Lato',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeGalleryImage(index),
                      icon: const Icon(FeatherIcons.x, color: Colors.red, size: 16),
                    ),
                  ],
                ),
              );
            }),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No gallery images added',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontFamily: 'Lato',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
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
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: 'Lato',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.amber,
            activeTrackColor: Colors.amber.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  void _addGalleryImage() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Add Gallery Image',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'https://example.com/image.jpg',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
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
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _galleryImages.add(controller.text.trim());
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Add',
                style: TextStyle(color: Colors.amber),
              ),
            ),
          ],
        );
      },
    );
  }

  void _removeGalleryImage(int index) {
    setState(() {
      _galleryImages.removeAt(index);
    });
  }

  void _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final spotlightItem = SpotlightItem(
        id: widget.item?.id ?? '',
        title: _titleController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        shortDescription: _shortDescriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        bannerUrl: _bannerUrlController.text.trim().isEmpty
            ? null
            : _bannerUrlController.text.trim(),
        galleryImages: _galleryImages,
        ctaText: _ctaTextController.text.trim(),
        ctaLink: _ctaLinkController.text.trim(),
        createdAt: widget.item?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: _isActive,
        isFeatured: _isFeatured,
        priority: int.tryParse(_priorityController.text) ?? 0,
        createdBy: widget.item?.createdBy,
      );

      final success = widget.item == null
          ? await SpotlightService.createSpotlightItem(spotlightItem) != null
          : await SpotlightService.updateSpotlightItem(widget.item!.id, spotlightItem);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.item == null
                    ? 'Spotlight item created successfully!'
                    : 'Spotlight item updated successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to save item');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}