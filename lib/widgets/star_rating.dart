import 'package:flutter/material.dart';

const _starColor = Color(0xFFF59E0B);

/// Read-only star display (shop cards, review lists).
class StarRating extends StatelessWidget {
  final double rating;
  final double size;

  const StarRating({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 1;
        final half = !filled && rating > i && rating < i + 1;
        return Icon(
          half ? Icons.star_half_rounded : (filled ? Icons.star_rounded : Icons.star_border_rounded),
          size: size,
          color: _starColor,
        );
      }),
    );
  }
}

/// Interactive star picker for submitting a review.
class StarRatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  const StarRatingInput({super.key, required this.value, required this.onChanged, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = value >= i + 1;
        return IconButton(
          onPressed: () => onChanged(i + 1),
          icon: Icon(filled ? Icons.star_rounded : Icons.star_border_rounded, color: _starColor, size: size),
        );
      }),
    );
  }
}
