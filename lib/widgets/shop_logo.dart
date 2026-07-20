import 'package:flutter/material.dart';

/// Circular shop logo — falls back to a storefront icon when [logoUrl] is
/// null/empty or fails to load (e.g. a broken/removed URL).
class ShopLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;

  const ShopLogo({super.key, required this.logoUrl, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.storefront_outlined, size: size * 0.5, color: theme.colorScheme.onSurfaceVariant),
    );
    if (logoUrl == null || logoUrl!.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
        loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
      ),
    );
  }
}
