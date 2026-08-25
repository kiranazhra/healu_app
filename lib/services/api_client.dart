import 'package:http/http.dart' as http;

class ApiClient extends http.BaseClient {
  static final ApiClient instance = ApiClient._internal();
  final http.Client _inner = http.Client();

  ApiClient._internal();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['ngrok-skip-browser-warning'] = 'true';
    return _inner.send(request);
  }
}
