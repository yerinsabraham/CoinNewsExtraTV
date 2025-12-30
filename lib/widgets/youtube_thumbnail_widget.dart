import 'package:flutter/material.dart';
import '../utils/youtube_thumbnail_helper.dart';

/// YouTube Thumbnail Widget
/// Displays YouTube video thumbnails with error handling and loading states
class YouTubeThumbnailWidget extends StatelessWidget {
  final String youtubeUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String quality;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showPlayButton;
  final VoidCallback? onTap;

  const YouTubeThumbnailWidget({
    super.key,
    required this.youtubeUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.quality = 'hqdefault',
    this.placeholder,
    this.errorWidget,
    this.showPlayButton = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String? thumbnailUrl = YouTubeThumbnailHelper.getThumbnailFromUrl(
      youtubeUrl, 
      quality: quality
    );

    if (thumbnailUrl == null) {
      return _buildErrorWidget();
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              thumbnailUrl,
              fit: fit,
              width: width,
              height: height,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildLoadingWidget(loadingProgress);
              },
              errorBuilder: (context, error, stackTrace) {
                print('Failed to load YouTube thumbnail: $thumbnailUrl - $error');
                return _buildErrorWidget();
              },
            ),
            if (showPlayButton)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(ImageChunkEvent loadingProgress) {
    return placeholder ?? Container(
      color: Colors.grey[300],
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / 
                loadingProgress.expectedTotalBytes!
              : null,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return errorWidget ?? Container(
      width: width,
      height: height,
      color: Colors.grey[800],
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                color: Colors.grey[400],
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'CoinNews Extra',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (showPlayButton)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Carousel Item Widget with YouTube Thumbnail
class YouTubeCarouselItem extends StatelessWidget {
  final String youtubeUrl;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const YouTubeCarouselItem({
    super.key,
    required this.youtubeUrl,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            YouTubeThumbnailWidget(
              youtubeUrl: youtubeUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              onTap: onTap,
            ),
            // Gradient overlay for text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

/// Grid Item Widget with YouTube Thumbnail for Explore Page
class YouTubeGridItem extends StatelessWidget {
  final String youtubeUrl;
  final String title;
  final String? channelName;
  final String? views;
  final String? timeAgo;
  final VoidCallback? onTap;

  const YouTubeGridItem({
    super.key,
    required this.youtubeUrl,
    required this.title,
    this.channelName,
    this.views,
    this.timeAgo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: YouTubeThumbnailWidget(
                  youtubeUrl: youtubeUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Video info
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _buildMetadata(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildMetadata() {
    List<String> parts = [];
    if (channelName != null) parts.add(channelName!);
    if (views != null) parts.add(views!);
    if (timeAgo != null) parts.add(timeAgo!);
    return parts.join(' • ');
  }
}
