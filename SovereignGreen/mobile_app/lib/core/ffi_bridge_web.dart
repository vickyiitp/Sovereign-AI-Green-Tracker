// Web implementation of FFIBridge (Stub)
// dart:ffi is not supported on web, so we provide a mock implementation.

class FFIBridge {
  static final FFIBridge _instance = FFIBridge._internal();

  factory FFIBridge() {
    return _instance;
  }

  FFIBridge._internal();

  // Mock method matching the IO signature
  Future<double> calculateImpactAsync(
      int tokens, double gridIntensity, bool isB200) async {
    // Return a dummy value or a JS-based calculation if needed
    // For now, just return a safe default to prevent crash
    return (tokens * 0.0001) + (isB200 ? 0.05 : 0.01);
  }
}
