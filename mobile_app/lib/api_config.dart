import 'package:flutter/foundation.dart';
import 'api_config_platform.dart';

class ApiConfig {
  // Can be set at runtime or overridden via --dart-define=SERVER_IP=192.168.x.x
  static String? customServerIp;
  static const String envServerIp = String.fromEnvironment('SERVER_IP', defaultValue: '');
  static const String envPort = String.fromEnvironment('SERVER_PORT', defaultValue: '8000');
  static String? customGoogleClientId;
  static const String envGoogleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '913573270503-vpd62vl8a38p8jmug5i50fbjc6h515o1.apps.googleusercontent.com',
  );

  static String get googleClientId {
    if (customGoogleClientId != null && customGoogleClientId!.isNotEmpty) {
      return customGoogleClientId!;
    }
    return envGoogleClientId;
  }

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

  static const String envBaseUrl = String.fromEnvironment('BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }
    return 'https://sumbersarihub.web.id/api';
  }

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

    // On Flutter Web, external images from third-party domains (like Google, Imgur, etc.)
    // are blocked by browser CORS when rendered via CanvasKit/HTML canvas.
    // Wrap with a CORS image cache proxy so they render seamlessly on web.
    if (kIsWeb && uri.hasScheme && !uri.host.contains('sumbersarihub.web.id') && uri.host != 'localhost' && uri.host != '127.0.0.1') {
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(trimmed)}&default=${Uri.encodeComponent(trimmed)}';
    }

    return trimmed;
  }
}