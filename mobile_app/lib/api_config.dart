import 'api_config_platform.dart';

class ApiConfig {
  // Can be set at runtime or overridden via --dart-define=SERVER_IP=192.168.x.x
  static String? customServerIp;
  static const String envServerIp = String.fromEnvironment('SERVER_IP', defaultValue: '');
  static const String envPort = String.fromEnvironment('SERVER_PORT', defaultValue: '8000');

  static String get serverIp {
    if (customServerIp != null && customServerIp!.isNotEmpty) {
      return customServerIp!;
    }
    if (envServerIp.isNotEmpty) {
      return envServerIp;
    }
    return platformServerIp;
  }

  static String port = envPort;

  static String get baseUrl => 'http://$serverIp:$port/api';

  // Endpoint helpers
  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get dashboardEndpoint => '$baseUrl/dashboard';

  /// Resolves any media URL (like photo_url) to work properly across
  /// Android emulators (10.0.2.2), physical devices (LAN IP), and localhost.
  static String resolveUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    final trimmed = rawUrl.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return trimmed;

    // Normalize path: map /storage/... to /api/storage/... for guaranteed CORS support
    String path = uri.path;
    if (path.startsWith('/storage/')) {
      path = '/api$path';
    } else if (path.startsWith('storage/')) {
      path = '/api/$path';
    }

    // If it's an absolute URL pointing to localhost or 127.0.0.1
    if (uri.hasScheme && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      final portNum = int.tryParse(port) ?? (uri.hasPort ? uri.port : 8000);
      return uri.replace(
        host: serverIp,
        port: portNum,
        path: path,
      ).toString();
    }

    // If it's a relative path like /storage/... or storage/...
    if (!uri.hasScheme) {
      final cleanPath = path.startsWith('/') ? path : '/$path';
      return 'http://$serverIp:$port$cleanPath';
    }

    // For any other absolute URL that had its path normalized
    if (path != uri.path) {
      return uri.replace(path: path).toString();
    }

    return trimmed;
  }
}