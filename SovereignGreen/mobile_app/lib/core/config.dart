class AppConfig {
  // Toggle this for local vs remote (Ngrok) debugging
  static const bool useRemote = false;

  // Localhost for Android Emulator (10.0.2.2) vs iOS/Web (127.0.0.1)
  // But since we are running "flutter run -d chrome", localhost is fine.
  static const String _localUrl = 'http://127.0.0.1:8004';

  // Ngrok URL (Replace this with your generated URL)
  static const String _remoteUrl = 'https://YOUR-NGROK-ID.ngrok-free.app';

  static String get baseUrl => useRemote ? _remoteUrl : _localUrl;
}
