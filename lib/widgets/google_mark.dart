import 'package:flutter/material.dart';

/// A small "G" mark for the "Continue with Google" button — not a pixel
/// exact reproduction of Google's logo, but a clean, recognizable stand-in
/// consistent with the app's restrained icon style.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Text(
        'G',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF4285F4), height: 1),
      ),
    );
  }
}
