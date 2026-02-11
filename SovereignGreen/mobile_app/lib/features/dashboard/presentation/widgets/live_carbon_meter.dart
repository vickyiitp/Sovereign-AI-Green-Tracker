import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme.dart';

class LiveCarbonMeter extends StatelessWidget {
  final double carbonGrams;
  final String efficiencyLabel;

  const LiveCarbonMeter({
    super.key,
    required this.carbonGrams,
    required this.efficiencyLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color based on impact
    Color statusColor;
    if (carbonGrams < 0.1) {
      statusColor = AppTheme.ecoGreen;
    } else if (carbonGrams < 0.4) {
      statusColor = Colors.yellow;
    } else {
      statusColor = AppTheme.alertRed;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 150,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              startDegreeOffset: 180, // Half Circle
              sections: [
                PieChartSectionData(
                  color: statusColor,
                  value: (carbonGrams * 100)
                      .clamp(0, 100)
                      .toDouble(), // Scale for visual
                  title: '${carbonGrams.toStringAsFixed(3)}g',
                  radius: 20,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.white.withOpacity(0.1),
                  value: 100 - (carbonGrams * 100).clamp(0, 100).toDouble(),
                  title: '',
                  radius: 15,
                ),
              ],
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "Carbon Footprint",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor, width: 1),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              efficiencyLabel,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
