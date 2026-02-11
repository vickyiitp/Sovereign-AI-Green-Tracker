import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:mobile_app/features/dashboard/presentation/providers/sustainability_provider.dart';
import 'package:mobile_app/core/theme.dart';
import 'package:mobile_app/features/dashboard/presentation/widgets/live_carbon_meter.dart';

// Mock Provider
class MockSustainabilityProvider extends ChangeNotifier
    implements SustainabilityProvider {
  @override
  ConnectionStatus _status = ConnectionStatus.idle;
  @override
  String _aiResponse = "";
  @override
  double _carbonGrams = 0.0;
  @override
  final double _waterMl = 0.0;
  @override
  String _efficiencyLabel = "Standard";
  @override
  final double _processingTime = 0.0;
  @override
  final String _engineUsed = "Mock Engine";
  @override
  final double _totalWaterConsumed = 0.0;
  @override
  final String? _region = "Mock Region";

  @override
  ConnectionStatus get status => _status;
  @override
  String get aiResponse => _aiResponse;
  @override
  double get carbonGrams => _carbonGrams;
  @override
  double get waterMl => _waterMl;
  @override
  String get efficiencyLabel => _efficiencyLabel;
  @override
  double get processingTime => _processingTime;
  @override
  String get engineUsed => _engineUsed;
  @override
  double get totalWaterConsumed => _totalWaterConsumed;
  @override
  String? get region => _region;
  @override
  bool get isOffline => false;

  @override
  Future<void> sendPrompt(String message) async {
    _status = ConnectionStatus.connecting;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate Connect

    _status = ConnectionStatus.processing;
    notifyListeners();
    await Future.delayed(const Duration(
        milliseconds: 500)); // Simulate Process (Badge limit check)

    _status = ConnectionStatus.success;
    _aiResponse = "Mock AI Response";
    _carbonGrams = 0.05; // Green
    _efficiencyLabel = "Green";
    notifyListeners();
  }

  @override
  void reset() {}
}

void main() {
  testWidgets(
      'Golden Path: User enters prompt and sees Sustainability Badge/Metrics',
      (WidgetTester tester) async {
    // 1. Setup
    final mockProvider = MockSustainabilityProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SustainabilityProvider>.value(
              value: mockProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const DashboardScreen(),
        ),
      ),
    );

    // 2. Verify Initial State
    expect(find.text("SovereignGreen"), findsOneWidget);
    expect(find.text("Waiting for prompt..."), findsOneWidget);

    // 3. Enter Prompt
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);
    await tester.enterText(textField, "How to build a green AI?");
    await tester.tap(find.byIcon(Icons.send));

    // 4. Verify Processing State
    await tester.pump(); // Start animation
    // Check for provider state change reflected in UI or just wait
    // The UI shows CircularProgressIndicator when processing

    // We need to pump frames to let the Future.delayed in mock complete
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 5. Verify Success State
    await tester.pump(const Duration(milliseconds: 600)); // Finish processing
    expect(find.text("Mock AI Response"), findsOneWidget);

    // Verify Badge (LiveCarbonMeter) shows correct label
    expect(find.text("Green"), findsOneWidget);
    expect(find.byType(LiveCarbonMeter), findsOneWidget);
  });
}
