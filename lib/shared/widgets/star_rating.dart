import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/providers.dart';

class StarRating extends ConsumerStatefulWidget {
  const StarRating({
    super.key,
    required this.novelId,
    required this.rating,
    required this.ratingCount,
    this.userRating,
    this.interactive = false,
  });

  final String novelId;
  final double rating;
  final int ratingCount;
  final double? userRating;
  final bool interactive;

  @override
  ConsumerState<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends ConsumerState<StarRating> {
  late double _averageRating;
  late int _ratingCount;
  double? _userRating;
  double _previewScore = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _averageRating = widget.rating;
    _ratingCount = widget.ratingCount;
    _userRating = widget.userRating;
    if (widget.interactive && widget.userRating == null) {
      Future.microtask(_loadUserRating);
    }
  }

  @override
  void didUpdateWidget(covariant StarRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    _averageRating = widget.rating;
    _ratingCount = widget.ratingCount;
    if (widget.userRating != null) {
      _userRating = widget.userRating;
    }
  }

  Future<void> _loadUserRating() async {
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.dio.get('/api/truyen/${widget.novelId}/rate');
      final data = res.data as Map<String, dynamic>;
      final score = (data['userRating'] as num?)?.toDouble();
      if (mounted && score != null) {
        setState(() => _userRating = score);
      }
    } catch (_) {
      // User may not be logged in.
    }
  }

  double get _displayRating => _previewScore > 0 ? _previewScore : (_userRating ?? 0);

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
        _averageRating = (data['rating'] as num?)?.toDouble() ?? _averageRating;
        _ratingCount = (data['ratingCount'] as num?)?.toInt() ?? _ratingCount;
        _userRating = (data['userRating'] as num?)?.toDouble() ?? score;
        _previewScore = 0;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
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
        ),
        if (_userRating != null)
          Text(
            'Bạn: ${_userRating!.toStringAsFixed(1)}/10',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        Text(
          'TB: ${_averageRating.toStringAsFixed(1)}/10 ($_ratingCount người)',
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
      children: [
        Icon(Icons.star_border, size: 24, color: Theme.of(context).colorScheme.outline),
        ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: fill,
            child: Icon(Icons.star, size: 24, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
