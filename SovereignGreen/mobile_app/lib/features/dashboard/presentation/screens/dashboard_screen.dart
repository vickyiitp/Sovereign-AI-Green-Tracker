import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sustainability_provider.dart';
import '../widgets/floating_card.dart';
import '../widgets/live_carbon_meter.dart';
import '../widgets/water_bottle.dart';
import '../widgets/connectivity_status.dart';
import '../../../../core/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _promptController = TextEditingController();

  void _sendPrompt() {
    if (_promptController.text.isNotEmpty) {
      context.read<SustainabilityProvider>().sendPrompt(_promptController.text);
      _promptController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive Layout
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "SovereignGreen",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.ecoGreen,
              ),
        ),
        actions: [
          Consumer<SustainabilityProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: ConnectivityStatus(
                  status: provider.status,
                  processingTime: provider.processingTime,
                  region: provider.region ?? "Unknown",
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.midnightBlue, Color(0xFF1A1F2C)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return _buildDesktopLayout(context);
            } else {
              return _buildMobileLayout(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left Column: Inputs & Response
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPromptInput(),
                const SizedBox(height: 20),
                Expanded(child: _buildResponseCard()),
              ],
            ),
          ),
        ),
        // Right Column: Metrics
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Expanded(
                  child: FloatingCard(
                    glowColor: AppTheme.ecoGreen,
                    child: Consumer<SustainabilityProvider>(
                      builder: (context, provider, _) => LiveCarbonMeter(
                        carbonGrams: provider.carbonGrams,
                        efficiencyLabel: provider.efficiencyLabel,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: FloatingCard(
                    glowColor: AppTheme.neonCyan,
                    child: Consumer<SustainabilityProvider>(
                      builder: (context, provider, _) =>
                          WaterBottle(waterMl: provider.totalWaterConsumed),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
      child: Column(
        children: [
          _buildPromptInput(),
          const SizedBox(height: 20),
          FloatingCard(
            height: 250,
            width: MediaQuery.of(context).size.width * 0.9,
            glowColor: AppTheme.ecoGreen,
            child: Consumer<SustainabilityProvider>(
              builder: (context, provider, _) => LiveCarbonMeter(
                carbonGrams: provider.carbonGrams,
                efficiencyLabel: provider.efficiencyLabel,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FloatingCard(
            height: 200,
            width: MediaQuery.of(context).size.width * 0.9,
            glowColor: AppTheme.neonCyan,
            child: Consumer<SustainabilityProvider>(
              builder: (context, provider, _) => WaterBottle(
                waterMl: provider.totalWaterConsumed,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 300, child: _buildResponseCard()),
        ],
      ),
    );
  }

  Widget _buildPromptInput() {
    return FloatingCard(
      height: 80,
      glowColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promptController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText:
                      "Ask AI something (e.g., 'Optimize my React code')...",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendPrompt(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppTheme.neonCyan),
              onPressed: _sendPrompt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseCard() {
    return FloatingCard(
      glowColor: AppTheme.midnightBlue,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Consumer<SustainabilityProvider>(
          builder: (context, provider, _) {
            if (provider.status == ConnectionStatus.processing) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.neonCyan),
              );
            }
            if (provider.status == ConnectionStatus.idle) {
              return const Center(
                  child: Text("Waiting for prompt...",
                      style: TextStyle(color: Colors.grey)));
            }
            // Offline Mode Banner
            final bool isOffline = provider.status == ConnectionStatus.offline;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOffline)
                    Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Text("Offline: Using Local C Engine",
                              style: TextStyle(
                                  color: Colors.orange, fontSize: 12)),
                        ],
                      ),
                    ),
                  Text(
                    "AI Response:",
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: AppTheme.neonCyan),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    provider.aiResponse,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  if (provider.status == ConnectionStatus.success ||
                      isOffline) ...[
                    const Divider(color: Colors.white24),
                    Text(
                      "Backend Engine: ${provider.engineUsed}",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
