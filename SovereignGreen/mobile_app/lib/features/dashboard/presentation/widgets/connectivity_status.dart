import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../providers/sustainability_provider.dart';

class ConnectivityStatus extends StatelessWidget {
  final ConnectionStatus status;
  final double processingTime;
  final String region;

  const ConnectivityStatus({
    super.key,
    required this.status,
    required this.processingTime,
    required this.region,
  });

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    String statusText;

    switch (status) {
      case ConnectionStatus.connecting:
        indicatorColor = Colors.yellow;
        statusText = "Negotiating...";
        break;
      case ConnectionStatus.processing:
        indicatorColor = AppTheme.neonCyan;
        statusText = "AI Processing...";
        break;
      case ConnectionStatus.success:
        indicatorColor = AppTheme.ecoGreen;
        statusText = "Connected: ${region.isNotEmpty ? region : 'Local'}";
        break;
      case ConnectionStatus.offline:
        indicatorColor = Colors.orange;
        statusText = "Offline Mode (Local FFI)";
        break;
      case ConnectionStatus.error:
        indicatorColor = AppTheme.alertRed;
        statusText = "Connection Failed";
        break;
      case ConnectionStatus.idle:
      default:
        indicatorColor = Colors.grey;
        statusText = "Ready";
        break;
    }

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: indicatorColor.withOpacity(0.5),
                blurRadius: 5,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              statusText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (status == ConnectionStatus.success)
              Text(
                "Latency: ${(processingTime * 1000).toInt()}ms",
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
      ],
    );
  }
}
