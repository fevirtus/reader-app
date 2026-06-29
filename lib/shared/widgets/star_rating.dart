import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/providers.dart';

class StarRating extends ConsumerStatefulWidget {
  const StarRating({
    super.key,
    required this.novelId,
    required this.rating,
    required this.ratingCount,
    this.interactive = false,
  });

  final String novelId;
  final double rating;
  final int ratingCount;
  final bool interactive;

  @override
  ConsumerState<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends ConsumerState<StarRating> {
  late double _currentRating;
  late int _currentCount;
  double _previewScore = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
    _currentCount = widget.ratingCount;
  }

  @override
  void didUpdateWidget(covariant StarRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    _currentRating = widget.rating;
    _currentCount = widget.ratingCount;
  }

  double get _displayRating => _previewScore > 0 ? _previewScore : _currentRating;

  Future<void> _submit(double score) async {
    if (!widget.interactive || _submitting) return;
    setState(() => _submitting = true);
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.dio.post(
        '/api/truyen/${widget.novelId}/rate',
        data: {'score': score},
      );
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _currentRating = (data['rating'] as num?)?.toDouble() ?? score;
        _currentCount = (data['ratingCount'] as num?)?.toInt() ?? _currentCount + 1;
        _previewScore = 0;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          final star = index + 1;
          final fill = () {
            final threshold = star * 2;
            if (_displayRating >= threshold) return 1.0;
            if (_displayRating >= threshold - 1) return 0.5;
            return 0.0;
          }();

          return SizedBox(
            width: 28,
            height: 28,
            child: widget.interactive && !_submitting
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final isLeftHalf = details.localPosition.dx < 14;
                      final score = isLeftHalf ? star * 2 - 1 : star * 2;
                      _submit(score.toDouble());
                    },
                    onPanUpdate: (details) {
                      final isLeftHalf = details.localPosition.dx < 14;
                      setState(() {
                        _previewScore = (isLeftHalf ? star * 2 - 1 : star * 2).toDouble();
                      });
                    },
                    onPanEnd: (_) => setState(() => _previewScore = 0),
                    child: _StarIcon(fill: fill),
                  )
                : _StarIcon(fill: fill),
          );
        }),
        const SizedBox(width: 8),
        Text(
          '${_currentRating.toStringAsFixed(1)}/10',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 4),
        Text(
          '($_currentCount đánh giá)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _StarIcon extends StatelessWidget {
  const _StarIcon({required this.fill});

  final double fill;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        const Icon(Icons.star_border, size: 22, color: Colors.grey),
        ClipRect(
          clipper: _StarClipper(fill),
          child: Icon(
            Icons.star,
            size: 22,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _StarClipper extends CustomClipper<Rect> {
  _StarClipper(this.fill);

  final double fill;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fill, size.height);

  @override
  bool shouldReclip(covariant _StarClipper oldClipper) => oldClipper.fill != fill;
}
