import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderSide? border;
  final double borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.border,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: border ?? const BorderSide(color: AppColors.borderLight, width: 1),
    );

    if (onTap != null) {
      return Material(
        color: color ?? AppColors.surfaceLight,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primaryContainer.withValues(alpha: 0.3),
          highlightColor: AppColors.primaryContainer.withValues(alpha: 0.1),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      );
    }

    return Container(
      padding: padding,
      decoration: ShapeDecoration(
        color: color ?? AppColors.surfaceLight,
        shape: shape,
      ),
      child: child,
    );
  }
}
