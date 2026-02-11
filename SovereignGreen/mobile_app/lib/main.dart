import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'features/dashboard/presentation/providers/sustainability_provider.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SustainabilityProvider()),
      ],
      child: const SovereignGreenApp(),
    ),
  );
}

class SovereignGreenApp extends StatelessWidget {
  const SovereignGreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SovereignGreen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}
