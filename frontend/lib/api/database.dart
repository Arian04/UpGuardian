import 'package:http/http.dart' as http;

class UpGuardianAPI {
  static const String baseUrl = 'http://localhost:8000';
  static const String profile = "example-corp";

  /// Reusable HTTP client (package:http) to allow connection pooling and fewer socket allocations.
  final http.Client httpClient;

  UpGuardianAPI({http.Client? httpClient}) : httpClient = httpClient ?? http.Client();

  /// Build a service URI for the given id: {baseUrl}/services/{id}
  Uri serviceUri(int id) => Uri.parse('$baseUrl/services/$id');

  /// Close the underlying client when the API is no longer needed.
  void close() => httpClient.close();
}