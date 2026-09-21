import 'package:flutter/material.dart';

/// Khối placeholder nhấp nháy nhẹ nhàng khi đang tải dữ liệu lần đầu — thay
/// cho CircularProgressIndicator để giao diện mượt và ít giật hơn.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: base.withAlpha(120 + (_controller.value * 80).round()),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Bố cục skeleton mô phỏng một hàng thẻ truyện ngang — dùng khi màn hình
/// chưa có cache để hiển thị (lần mở app đầu tiên).
class SkeletonNovelRow extends StatelessWidget {
  const SkeletonNovelRow({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 226,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: 122,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 122, height: 155, borderRadius: 10),
              const SizedBox(height: 8),
              SkeletonBox(width: 100, height: 12),
              const SizedBox(height: 6),
              SkeletonBox(width: 60, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
