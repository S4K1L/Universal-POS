import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../api/api_client.dart';
import 'kit.dart';

/// A product's picture, or — when it has none, or it cannot be loaded (offline, deleted) — its coloured monogram.
/// Pictures are optional everywhere: nothing depends on one being there.
class ProductThumb extends ConsumerWidget {
  const ProductThumb({super.key, required this.name, this.imageUrl = '', this.size = 40, this.seed, this.radius});
  final String name, imageUrl;
  final double size;
  final String? seed;
  final double? radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = Monogram(name, size: size, seed: seed);
    if (imageUrl.isEmpty) return fallback;
    final url = ServerConfig.assetUrl(ref.watch(serverUrlProvider), imageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? size * 0.28),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => fallback,
          frameBuilder: (context, child, frame, sync) => sync || frame != null ? child : fallback,
        ),
      ),
    );
  }
}
