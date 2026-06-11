import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartsolar/models/daily_stats.dart';
import 'package:smartsolar/models/energy_data.dart';
import 'package:smartsolar/services/auth_service.dart';
import 'package:smartsolar/utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getToken();
    return {
      ...Constants.headers,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<EnergyData> getStatus() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('${Constants.baseUrl}${Constants.endpointStatus}'),
            headers: headers,
          )
          .timeout(Constants.timeout);

      if (response.statusCode == 200) {
        return EnergyData.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<DailyStats> getDailyStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('${Constants.baseUrl}${Constants.endpointDailyStats}'),
            headers: headers,
          )
          .timeout(Constants.timeout);

      if (response.statusCode == 200) {
        return DailyStats.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load daily stats');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<HourlyData>> getHourlyData() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('${Constants.baseUrl}${Constants.endpointHourlyData}'),
            headers: headers,
          )
          .timeout(Constants.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => HourlyData.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load hourly data');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<dynamic>> getEvents() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('${Constants.baseUrl}${Constants.endpointEvents}'),
            headers: headers,
          )
          .timeout(Constants.timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<dynamic>> getAlerts() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('${Constants.baseUrl}${Constants.endpointAlerts}'),
            headers: headers,
          )
          .timeout(Constants.timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load alerts');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<bool> sendCommand(String type, int value) async {
    return sendCommandPayload(type, value);
  }

  Future<bool> sendCommandPayload(String type, Object value) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('${Constants.baseUrl}${Constants.endpointCommand}'),
            headers: headers,
            body: json.encode({'type': type, 'value': value}),
          )
          .timeout(Constants.timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearEvents() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse('${Constants.baseUrl}${Constants.endpointClearEvents}'),
            headers: headers,
          )
          .timeout(Constants.timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAlertsRead() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(
              '${Constants.baseUrl}${Constants.endpointMarkAlertsRead}',
            ),
            headers: headers,
          )
          .timeout(Constants.timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAlertRead(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('${Constants.baseUrl}${Constants.endpointMarkAlertRead}'),
            headers: headers,
            body: json.encode({'id': id}),
          )
          .timeout(Constants.timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
