import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class WaterBottle extends StatelessWidget {
  final double waterMl;

  const WaterBottle({super.key, required this.waterMl});

  @override
  Widget build(BuildContext context) {
    // Cap visual fill at 500ml for the bottle size
    final double fillPercent = (waterMl / 500).clamp(0.0, 1.0);

    return Column(
      children: [
        Container(
          width: 60,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.05),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Water liquid
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                height: 116 * fillPercent, // 120 - borders
                width: 56,
                decoration: const BoxDecoration(
                  color: AppTheme.neonCyan,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
              ),
              // Bubbles / Glint
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 5,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "${waterMl.toStringAsFixed(1)} ml",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppTheme.neonCyan),
        ),
        Text("Water Consumed", style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
