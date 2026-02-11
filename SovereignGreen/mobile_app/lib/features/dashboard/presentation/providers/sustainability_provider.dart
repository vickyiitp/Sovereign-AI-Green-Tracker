import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/ffi_bridge.dart';
import '../../../../core/config.dart';

enum ConnectionStatus { idle, connecting, processing, success, error, offline }

class SustainabilityProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final String _baseUrl = AppConfig.baseUrl;

  ConnectionStatus _status = ConnectionStatus.idle;
  String? _region;
  double _carbonGrams = 0.0;
  double _waterMl = 0.0;
  String _efficiencyLabel = "Standard";
  String _aiResponse = "";
  double _processingTime = 0.0;
  String _engineUsed = "Unknown";
  // Track continuous water filling
  double _totalWaterConsumed = 0.0;
  String? _accessToken; // JWT Token

  // Getters
  ConnectionStatus get status => _status;
  String? get region => _region;
  double get carbonGrams => _carbonGrams;
  double get waterMl => _waterMl;
  String get efficiencyLabel => _efficiencyLabel;
  String get aiResponse => _aiResponse;
  double get processingTime => _processingTime;
  String get engineUsed => _engineUsed;
  double get totalWaterConsumed => _totalWaterConsumed;
  bool get isOffline => _status == ConnectionStatus.offline;

  Future<void> _authenticate() async {
    if (_accessToken != null) return;
    try {
      // Dummy Login for Demo
      final response = await _dio.post(
        '$_baseUrl/token',
        data: {'username': 'demo_user', 'password': 'password'},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      _accessToken = response.data['access_token'];
    } catch (e) {
      print("Auth Failed: $e");
      throw Exception("Authentication Failed");
    }
  }

  Future<void> sendPrompt(String message) async {
    _status = ConnectionStatus.connecting;
    notifyListeners();

    try {
      await _authenticate();

      // Simulate network lag for UI demo if on localhost
      await Future.delayed(const Duration(milliseconds: 300));
      _status = ConnectionStatus.processing;
      notifyListeners();

      // Determine region based on platform?
      // For now, we hardcode a region header to demo the feature
      // In a real app, this would come from location services or IP
      const String demoRegion = "asia-south1"; // High intensity demo

      final response = await _dio.post(
        '$_baseUrl/v1/chat',
        data: {
          'message': message,
          'model': 'gemini-pro-b200',
        }, // Requesting B200 class
        options: Options(
          headers: {
            'x-goog-region': demoRegion,
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _aiResponse = data['ai_answer'];
        final metrics = data['metrics'];

        _region = metrics['region_detected'];
        _carbonGrams = (metrics['carbon_grams'] as num).toDouble();
        _waterMl = (metrics['water_ml'] as num).toDouble();
        _efficiencyLabel = metrics['efficiency_label'];
        _processingTime = (metrics['processing_time_sec'] as num).toDouble();
        _engineUsed = metrics['energy_engine'];

        // Accumulate water for the bottle animation
        _totalWaterConsumed += _waterMl;

        _status = ConnectionStatus.success;
      } else {
        _status = ConnectionStatus.error;
        _aiResponse = "Error: Server returned ${response.statusCode}";
      }
    } catch (e) {
      // Offline Mode Fallback
      print("Connection Error: $e. Switching to Offline Mode.");
      _switchToOfflineMode(message);
    }

    notifyListeners();
  }

  Future<void> _switchToOfflineMode(String message) async {
    _status = ConnectionStatus.offline;
    _aiResponse = "OFFLINE MODE: AI unavailable. Estimating impact locally...";
    notifyListeners();

    // Local Calculation using FFI Bridge logic
    final ffi = FFIBridge();
    int estimatedTokens = message.split(' ').length + 50; // Input + Est Output

    // Run in background Isolate
    _carbonGrams = await ffi.calculateImpactAsync(estimatedTokens, 0.475, true);

    _waterMl = _carbonGrams * 20.0;
    _efficiencyLabel =
        _carbonGrams < 0.1 ? "Green (Local)" : "Standard (Local)";
    _processingTime = 0.05;
    _region = "Offline-Local";
    _engineUsed = "Dart FFI (Isolate)";
    _totalWaterConsumed += _waterMl;

    notifyListeners();
  }

  void reset() {
    _totalWaterConsumed = 0.0;
    _carbonGrams = 0.0;
    _waterMl = 0.0;
    _status = ConnectionStatus.idle;
    notifyListeners();
  }
}
