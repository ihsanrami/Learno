/// =============================================================================
/// Image Service - Handles AI-Generated Images
/// =============================================================================
/// 🆕 NEW FILE
///
/// Manages image display, caching, and loading states for AI-generated images.
/// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final Map<String, ImageProvider> _imageCache = {};

  final Map<String, bool> _loadingStates = {};

  final Map<String, bool> _errorStates = {};

  Future<void> preloadImage(String url, BuildContext context) async {
    if (_imageCache.containsKey(url)) return;
    
    _loadingStates[url] = true;
    
    try {
      final imageProvider = NetworkImage(url);
      await precacheImage(imageProvider, context);
      _imageCache[url] = imageProvider;
      _loadingStates[url] = false;
      _errorStates[url] = false;
    } catch (e) {
      _loadingStates[url] = false;
      _errorStates[url] = true;
      print('❌ Image preload error: $e');
    }
  }

  bool isLoading(String url) => _loadingStates[url] ?? false;

  bool hasError(String url) => _errorStates[url] ?? false;

  bool isCached(String url) => _imageCache.containsKey(url);

  ImageProvider? getCachedImage(String url) => _imageCache[url];

  void clearCache() {
    _imageCache.clear();
    _loadingStates.clear();
    _errorStates.clear();
  }

  Widget buildImage({
    required String? url,
    double width = 200,
    double height = 200,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    if (url == null || url.isEmpty) {
      return _buildPlaceholder(width, height);
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingIndicator(width, height, loadingProgress);
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget(width, height);
        },
      ),
    );
  }

  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.image_outlined,
        size: 50,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildLoadingIndicator(
    double width, 
    double height, 
    ImageChunkEvent loadingProgress,
  ) {
    final progress = loadingProgress.expectedTotalBytes != null
        ? loadingProgress.cumulativeBytesLoaded / 
          loadingProgress.expectedTotalBytes!
        : null;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              color: const Color(0xFFFF8D00),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
