import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.stock({
    required double stock,
    required double minStock,
    required String unit,
  }) {
    final formattedQty = (stock % 1 == 0) ? stock.toInt().toString() : stock.toString();
    if (stock <= 0) {
      return const StatusBadge(
        label: 'Out of Stock',
        backgroundColor: Color(0xFFFFEBEE),
        textColor: AppColors.error,
        icon: Icons.error_outline,
      );
    } else if (stock <= minStock) {
      return StatusBadge(
        label: 'Low: $formattedQty $unit',
        backgroundColor: const Color(0xFFFFF3E0),
        textColor: AppColors.warning,
        icon: Icons.warning_amber_rounded,
      );
    } else {
      return StatusBadge(
        label: '$formattedQty $unit',
        backgroundColor: AppColors.primaryContainer,
        textColor: AppColors.primary,
        icon: Icons.inventory_2_outlined,
      );
    }
  }

  factory StatusBadge.paymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return const StatusBadge(
          label: 'CASH',
          backgroundColor: Color(0xFFE8F5E9),
          textColor: AppColors.chipCash,
          icon: Icons.payments_outlined,
        );
      case 'upi':
        return const StatusBadge(
          label: 'UPI',
          backgroundColor: Color(0xFFE3F2FD),
          textColor: AppColors.chipUpi,
          icon: Icons.qr_code,
        );
      default:
        return const StatusBadge(
          label: 'OTHER',
          backgroundColor: Color(0xFFF3E5F5),
          textColor: AppColors.chipOther,
          icon: Icons.credit_card,
        );
    }
  }

  factory StatusBadge.saleStatus(String status) {
    if (status.toLowerCase() == 'cancelled') {
      return const StatusBadge(
        label: 'CANCELLED',
        backgroundColor: Color(0xFFFFEBEE),
        textColor: AppColors.error,
        icon: Icons.cancel_outlined,
      );
    }
    return const StatusBadge(
      label: 'COMPLETED',
      backgroundColor: Color(0xFFE8F5E9),
      textColor: AppColors.success,
      icon: Icons.check_circle_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
