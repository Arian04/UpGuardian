import 'dart:convert';

import 'package:http/http.dart' as http;

import 'database.dart';

/// Represents a service and provides methods to update its fields on the server.
class Service {
  final UpGuardianAPI api;
  final int id;
  String name;
  String oldEndpoint;
  String newEndpoint;

  Service({
    required this.api,
    required this.id,
    required this.name,
    required this.oldEndpoint,
    required this.newEndpoint,
  });

  /// Update the name on the server (sends all three fields in the request).
  Future<void> updateName(String updatedName) async {
    await _sendUpdate(updatedName, oldEndpoint, newEndpoint);
    name = updatedName;
  }

  /// Update the old endpoint on the server (sends all three fields in the request).
  Future<void> updateOldEndpoint(String updatedOld) async {
    await _sendUpdate(name, updatedOld, newEndpoint);
    oldEndpoint = updatedOld;
  }

  /// Update the new endpoint on the server (sends all three fields in the request).
  Future<void> updateNewEndpoint(String updatedNew) async {
    await _sendUpdate(name, oldEndpoint, updatedNew);
    newEndpoint = updatedNew;
  }

  /// Sends a PUT request to /services/{id} with the provided values.
  /// The JSON uses snake_case keys: name, old_endpoint, new_endpoint.
  Future<void> _sendUpdate(String nameValue, String oldValue, String newValue) async {
    final uri = api.serviceUri(id);
    final payload = jsonEncode({
      'name': nameValue,
      'old_endpoint': oldValue,
      'new_endpoint': newValue,
    });

    try {
      final http.Response response = await api.httpClient.put(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: payload,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = response.body;
        var msg = 'Failed to update service (status ${response.statusCode})';
        if (body.isNotEmpty) msg = '$msg: $body';
        throw Exception(msg);
      }
    } catch (e) {
      throw Exception('Error updating service id=$id: $e');
    }
  }
}

/// Extension on UpGuardianAPI to list services for a profile.
extension UpGuardianAPIServiceList on UpGuardianAPI {
  /// Fetches services for the given [profile] from `/profiles/{profile}/services`.
  ///
  /// Expects a JSON array where each element is an object containing at least
  /// `id` and `name` and either `old_endpoint`/`new_endpoint` (snake_case) or
  /// `oldEndpoint`/`newEndpoint` (camelCase). Returns a list of [Service]
  /// instances backed by this API's `httpClient`.
  Future<List<Service>> listServices(String profile) async {
    final uri = Uri.parse('${UpGuardianAPI.baseUrl}/profiles/$profile/services');

    try {
      final http.Response response = await httpClient.get(uri);
      final body = response.body;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        var msg = 'Failed to list services (status ${response.statusCode})';
        if (body.isNotEmpty) msg = '$msg: $body';
        throw Exception(msg);
      }

      final decoded = jsonDecode(body);
      if (decoded is! List) {
        throw FormatException('Expected JSON array from $uri');
      }

      final List<Service> result = [];
      for (final item in decoded) {
        if (item is! Map) continue;

        // id may be int or string; try to coerce
        final int rawId = item['id'];
        final String name = item['name'];

        // accept both snake_case and camelCase keys
        final String oldEp = item['old_endpoint'];
        final String newEp = item['new_endpoint'];

        result.add(Service(api: this, id: rawId, name: name, oldEndpoint: oldEp, newEndpoint: newEp));
      }

      return result;
    } catch (e) {
      throw Exception('Error listing services for profile="$profile": $e');
    }
  }

  /// Create a new service under the given [profile]. Sends a POST to
  /// `/profiles/{profile}/services` with JSON body containing `name`,
  /// `old_endpoint`, and `new_endpoint`. Expects a JSON response containing
  /// an `id` field for the newly-created resource. Returns a [Service]
  /// instance representing the created service.
  Future<Service> createService(String profile, String name, String oldEndpoint, String newEndpoint) async {
    final uri = Uri.parse('${UpGuardianAPI.baseUrl}/profiles/$profile/services');

    final payload = jsonEncode({
      'name': name,
      'old_endpoint': oldEndpoint,
      'new_endpoint': newEndpoint,
    });

    try {
      final http.Response response = await httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: payload,
      );

      final body = response.body;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        var msg = 'Failed to create service (status ${response.statusCode})';
        if (body.isNotEmpty) msg = '$msg: $body';
        throw Exception(msg);
      }

      final decoded = jsonDecode(body);
      if (decoded is Map && decoded.containsKey('id')) {
        final int rawId = decoded['id'];
        return Service(api: this, id: rawId, name: name, oldEndpoint: oldEndpoint, newEndpoint: newEndpoint);
      }

      throw FormatException('Invalid response from server when creating service: missing "id"');
    } catch (e) {
      throw Exception('Error creating service for profile="$profile": $e');
    }

  }

  /// Delete a service by id using DELETE /services/{id}.
    /// Throws an Exception on non-2xx response or other errors.
    Future<void> deleteService(int id) async {
      final uri = serviceUri(id);
      try {
        final http.Response response = await httpClient.delete(uri);
        final body = response.body;
        if (response.statusCode < 200 || response.statusCode >= 300) {
          var msg = 'Failed to delete service (status ${response.statusCode})';
          if (body.isNotEmpty) msg = '$msg: $body';
          throw Exception(msg);
        }
      } catch (e) {
        throw Exception('Error deleting service id=$id: $e');
      }
    }
  }