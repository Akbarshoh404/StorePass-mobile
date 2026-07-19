import 'package:flutter/material.dart';

/// The StorePass mark: a plain monochrome square with the initial, used in
/// place of a colorful icon on splash/auth screens to keep the accent color
/// reserved for actions and key numbers rather than decoration.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: scheme.onSurface, borderRadius: BorderRadius.circular(size * 0.28)),
      child: Text(
        'S',
        style: TextStyle(
          color: scheme.surface,
          fontSize: size * 0.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
