import 'package:flutter/material.dart';

class ResultWidget extends StatelessWidget {
  final List<String> objects;
  final String caption;

  const ResultWidget({
    super.key,
    required this.objects,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Replacing deprecated withOpacity
          color: Colors.black.withAlpha(153),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Objects: ${objects.join(', ')}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Caption: $caption',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
