import 'dart:io' show Platform;

String devServerUrl() {
  if (Platform.isAndroid) return 'http://10.0.2.2:5173';
  return 'http://localhost:5173';
}
