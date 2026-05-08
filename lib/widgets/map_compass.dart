import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MapCompass extends StatelessWidget {
  final double bearing;

  const MapCompass({
    super.key,
    required this.bearing,
  });

  @override
  Widget build(BuildContext context) {
    if (bearing.abs() < 0.5) return const SizedBox.shrink();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedRotation(
        turns: -bearing / 360,
        duration: const Duration(milliseconds: 200),
        child: const Icon(
          Icons.navigation,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }
}
