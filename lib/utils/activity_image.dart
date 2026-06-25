import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Aktivite kartları için güvenilir ağ görseli URL'leri ve yükleme.
abstract final class ActivityImage {
  static const httpHeaders = {
    'User-Agent': 'Mozilla/5.0 (compatible; VizegooTravel/1.0)',
    'Accept': 'image/*',
  };

  static const _brokenPhotoIds = {
    'photo-1534351590666-13e498e96709',
    'photo-1508050919630-b135583b29ab',
    'photo-1583422409513-28903a01ef45',
  };

  static String resolve({
    String? imageUrl,
    required String activityId,
    String category = 'tours',
  }) {
    final trimmed = imageUrl?.trim();
    if (trimmed != null &&
        trimmed.isNotEmpty &&
        !_isBroken(trimmed) &&
        trimmed.startsWith('http')) {
      return _withAutoFormat(trimmed);
    }
    final seed = activityId.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '-');
    return 'https://picsum.photos/seed/vizegoo-$seed/800/600';
  }

  static bool _isBroken(String url) =>
      _brokenPhotoIds.any((id) => url.contains(id));

  static String _withAutoFormat(String url) {
    if (url.contains('auto=format')) return url;
    final sep = url.contains('?') ? '&' : '?';
    return '$url${sep}auto=format&fit=crop&w=800&q=80';
  }
}

/// Aktivite listesi ve detay için ortak görsel widget'ı.
class ActivityNetworkImage extends StatelessWidget {
  const ActivityNetworkImage({
    super.key,
    this.imageUrl,
    required this.activityId,
    this.category = 'tours',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String? imageUrl;
  final String activityId;
  final String category;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = ActivityImage.resolve(
      imageUrl: imageUrl,
      activityId: activityId,
      category: category,
    );

    Widget image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: ActivityImage.httpHeaders,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _fallback(),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.fuchsiaSoft,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppTheme.textMuted, size: 28),
      ),
    );
  }

  Widget _fallback() {
    final fallbackUrl =
        'https://picsum.photos/seed/vizegoo-fb-$activityId/800/600';
    return CachedNetworkImage(
      imageUrl: fallbackUrl,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: ActivityImage.httpHeaders,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }
}
