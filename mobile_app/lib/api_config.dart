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
}