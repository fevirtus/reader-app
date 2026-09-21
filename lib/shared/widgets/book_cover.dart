import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Consistent book proportions, including loading and unavailable artwork.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.url,
    this.width = 88,
    this.height = 128,
  });
  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fallback = Container(
      color: cs.surfaceContainerHigh,
      child: Center(
        child: Icon(Icons.auto_stories_outlined, color: cs.primary, size: 30),
      ),
    );
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: url == null || url!.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
