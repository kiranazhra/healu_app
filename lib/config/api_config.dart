import 'package:http/http.dart' as http;

class ApiConfig {
  static const String baseUrl = 'https://chump-vividness-escapable.ngrok-free.dev/healu_api';

  static const Map<String, String> headers = {
    'ngrok-skip-browser-warning': 'true',
  };
}

class ApiClient {
  static Future<http.Response> get(Uri url) {
    return http.get(url, headers: ApiConfig.headers);
  }

  static Future<http.Response> post(Uri url, {Object? body}) {
    return http.post(url, headers: ApiConfig.headers, body: body);
  }
}