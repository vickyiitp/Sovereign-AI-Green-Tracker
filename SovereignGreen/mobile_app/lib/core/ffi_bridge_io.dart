import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

// C Function Signature
typedef CalculateImpactFunc = Double Function(
    Int32 tokens, Float gridIntensity, Int32 isB200);
typedef CalculateImpact = double Function(
    int tokens, double gridIntensity, int isB200);

class FFIBridge {
  static final FFIBridge _instance = FFIBridge._internal();
  late DynamicLibrary _nativeLib;
  late CalculateImpact _calculateImpact;
  bool _isLoaded = false;

  factory FFIBridge() {
    return _instance;
  }

  FFIBridge._internal() {
    _loadLibrary();
  }

  void _loadLibrary() {
    try {
      if (Platform.isWindows) {
        _nativeLib = DynamicLibrary.open('libenergy.dll');
      } else if (Platform.isLinux) {
        _nativeLib = DynamicLibrary.open('libenergy.so');
      } else if (Platform.isAndroid) {
        _nativeLib = DynamicLibrary.open('libenergy.so');
      } else {
        print("Platform not supported for FFI");
        return;
      }

      _calculateImpact = _nativeLib
          .lookup<NativeFunction<CalculateImpactFunc>>('calculate_impact')
          .asFunction();
      _isLoaded = true;
      print("Native Library Loaded Successfully");
    } catch (e) {
      print("Failed to load native library: $e");
      _isLoaded = false;
    }
  }

  bool get isLoaded => _isLoaded;

  // Public method to calculate impact using Isolate
  Future<double> calculateImpactAsync(
      int tokens, double gridIntensity, bool isB200) async {
    if (!_isLoaded) {
      // Fallback/Mock if library failed
      return _fallbackCalculation(tokens, gridIntensity, isB200);
    }

    final receivePort = ReceivePort();
    await Isolate.spawn(_isolateEntryPoint, {
      'sendPort': receivePort.sendPort,
      'tokens': tokens,
      'gridIntensity': gridIntensity,
      'isB200': isB200 ? 1 : 0,
      'libPath': Platform.isWindows ? 'libenergy.dll' : 'libenergy.so'
    });

    final result = await receivePort.first;
    if (result is double) {
      return result;
    } else {
      // Error in isolate
      return _fallbackCalculation(tokens, gridIntensity, isB200);
    }
  }

  static double _fallbackCalculation(
      int tokens, double gridIntensity, bool isB200) {
    double energyPerToken = isB200 ? 0.003 : 0.05;
    double totalEnergyKwh = (tokens * energyPerToken) / 1000.0;
    return totalEnergyKwh * gridIntensity * 1000.0;
  }

  // Isolate Entry Point
  static void _isolateEntryPoint(Map<String, dynamic> message) {
    final sendPort = message['sendPort'] as SendPort;
    final tokens = message['tokens'] as int;
    final gridIntensity = message['gridIntensity'] as double;
    final isB200 = message['isB200'] as int;
    // We need to reload lib in the new isolate or pass the address (complex).
    // Simple way: Reload.

    try {
      // Re-opening logic for the isolate
      DynamicLibrary nativeLib;
      if (Platform.isWindows) {
        nativeLib = DynamicLibrary.open('libenergy.dll');
      } else {
        nativeLib = DynamicLibrary.open('libenergy.so');
      }

      final calculate = nativeLib
          .lookup<NativeFunction<CalculateImpactFunc>>('calculate_impact')
          .asFunction<CalculateImpact>();

      final result = calculate(tokens, gridIntensity, isB200);
      sendPort.send(result);
    } catch (e) {
      sendPort.send("Error: $e");
    }
  }
}
