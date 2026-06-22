import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../city_images.dart';
import '../theme/app_theme.dart';

/// Önce canlı otel fotoğrafı, sonra yerel destinasyon görseli, yoksa ağ yedeği.
class DestinationHeroImage extends StatelessWidget {
  final String iataCode;
  final String? imageUrl;
  final double? height;
  final BoxFit fit;

  const DestinationHeroImage({
    super.key,
    required this.iataCode,
    this.imageUrl,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final override = imageUrl?.trim();
    if (override != null && override.isNotEmpty) {
      return _wrap(
        CachedNetworkImage(
          imageUrl: override,
          fit: fit,
          httpHeaders: const {
            'User-Agent': 'Mozilla/5.0 (compatible; VizegooTravel/1.0)',
          },
          placeholder: (ctx, url) => Shimmer.fromColors(
            baseColor: AppTheme.bgSecondary,
            highlightColor: AppTheme.bgTertiary,
            child: Container(color: AppTheme.bgSecondary),
          ),
          errorWidget: (ctx, url, err) => _cityFallback(),
        ),
      );
    }

    final asset = CityImages.assetPath(iataCode);
    final network = CityImages.networkUrl(iataCode);

    Widget networkImage() => CachedNetworkImage(
          imageUrl: network,
          fit: fit,
          httpHeaders: const {
            'User-Agent': 'Mozilla/5.0 (compatible; VizegooTravel/1.0)',
          },
          placeholder: (ctx, url) => Shimmer.fromColors(
            baseColor: AppTheme.bgSecondary,
            highlightColor: AppTheme.bgTertiary,
            child: Container(color: AppTheme.bgSecondary),
          ),
          errorWidget: (ctx, url, err) => _fallbackBox,
        );

    final image = Image.asset(
      asset,
      fit: fit,
      errorBuilder: (_, __, ___) => networkImage(),
    );

    return _wrap(image);
  }

  Widget _cityFallback() {
    final asset = CityImages.assetPath(iataCode);
    return Image.asset(
      asset,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallbackBox,
    );
  }

  Widget _wrap(Widget child) {
    if (height != null) {
      return SizedBox(height: height, width: double.infinity, child: child);
    }
    return child;
  }

  static Widget get _fallbackBox => Container(
        color: AppTheme.bgTertiary,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppTheme.textMuted,
          size: 32,
        ),
      );
}
