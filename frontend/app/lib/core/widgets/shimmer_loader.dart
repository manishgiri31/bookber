import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerLoader({Key? key, this.width = double.infinity, this.height = 16, this.borderRadius = const BorderRadius.all(Radius.circular(8))}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.accentPrimary.withOpacity(0.15);
    final highlight = AppColors.accentPrimary.withOpacity(0.35);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: baseColor, borderRadius: borderRadius),
      ),
    );
  }
}
