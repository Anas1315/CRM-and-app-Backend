import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Constants {
  // ─── API Configuration ───────────────────────────────────────
  // Production cloud backend (Render)
  static const String productionBaseUrl = 'https://crm-backend-ukfa.onrender.com';
  // Local development fallbacks
  static const String lanBaseUrl = 'http://172.23.200.125:5000';
  static const String localDevBaseUrl = 'http://localhost:5000';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:5000';

  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String? _dynamicBaseUrl;

  static void setDynamicBaseUrl(String url) {
    final normalized = _normalizeBaseUrl(url);
    if (normalized.isNotEmpty) {
      _dynamicBaseUrl = normalized;
    } else {
      _dynamicBaseUrl = null;
    }
  }

  static String _normalizeBaseUrl(String url) {
    var normalized = url.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (normalized.isNotEmpty &&
        !normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }
    return normalized;
  }

  /// Detect and set the best base URL on app startup.
  /// Priority: saved preference → local probe → production cloud.
  static Future<void> initBaseUrl() async {
    // 1. Compile-time override wins
    if (configuredBaseUrl.isNotEmpty) return;

    // 2. User-saved URL (from settings dialog) wins next
    final prefs = await SharedPreferences.getInstance();
    final savedApiBaseUrl = prefs.getString('api_base_url');
    if (savedApiBaseUrl != null && savedApiBaseUrl.trim().isNotEmpty) {
      setDynamicBaseUrl(savedApiBaseUrl);
      return;
    }
    final savedLocalUrl = prefs.getString('local_server_url');
    if (savedLocalUrl != null && savedLocalUrl.trim().isNotEmpty) {
      setDynamicBaseUrl(savedLocalUrl);
      return;
    }

    // 3. Web platform — use production cloud
    if (kIsWeb) {
      _dynamicBaseUrl = productionBaseUrl;
      return;
    }

    // 4. Android / iOS — probe local servers first, then fall back to cloud
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      final client = http.Client();
      try {
        // 4a. Try emulator loopback first (only works on emulator in debug)
        if (kDebugMode) {
          try {
            final response = await client
                .get(Uri.parse('$androidEmulatorBaseUrl/api/status'))
                .timeout(const Duration(milliseconds: 800));
            if (response.statusCode == 200) {
              _dynamicBaseUrl = androidEmulatorBaseUrl;
              return;
            }
          } catch (_) {}
        }

        // 4b. Try LAN IP (works on physical device on same network)
        try {
          final response = await client
              .get(Uri.parse('$lanBaseUrl/api/status'))
              .timeout(const Duration(milliseconds: 1500));
          if (response.statusCode == 200) {
            _dynamicBaseUrl = lanBaseUrl;
            return;
          }
        } catch (_) {}
      } finally {
        client.close();
      }

      // 4c. No local server found — use production cloud backend
      _dynamicBaseUrl = productionBaseUrl;
    }
  }

  static String get baseUrl {
    // Compile-time override
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }
    // Runtime-detected or user-saved URL
    if (_dynamicBaseUrl != null && _dynamicBaseUrl!.trim().isNotEmpty) {
      return _dynamicBaseUrl!;
    }
    // Final fallback: always use the production cloud backend
    return productionBaseUrl;
  }

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  static const Duration timeout = Duration(seconds: 15);

  // App Configuration
  static const String appName = 'Smart Energy Controller';
  static const String appVersion = '1.0.0';

  // Cost Calculation
  static const double costPerUnit = 30.0; // PKR per kWh
  static const double co2PerUnit = 0.4; // kg CO2 per kWh

  // Thresholds
  static const int ldrSunnyThreshold = 1800;
  static const int ldrDarkThreshold = 1200;
  static const double lowVoltageProtection = 170.0;

  // API Endpoints
  static const String endpointStatus = '/api/status';
  static const String endpointDailyStats = '/api/daily-stats';
  static const String endpointHourlyData = '/api/hourly-data';
  static const String endpointEvents = '/api/events';
  static const String endpointAlerts = '/api/alerts';
  static const String endpointCommand = '/api/command';
  static const String endpointClearEvents = '/api/clear-events';
  static const String endpointMarkAlertsRead = '/api/mark-alerts-read';
  static const String endpointMarkAlertRead = '/api/mark-alert-read';
  static const String endpointSystemStatus = '/api/system-status';
  static const String endpointLastSeen = '/api/last-seen';
  static const String endpointUserMode = '/api/user-mode';
  static const String endpointLogin = '/api/app/auth/login';
  static const String endpointVerify2FA = '/api/auth/verify-2fa';
  static const String endpointForgotPassword = '/api/auth/forgot-password';
  static const String endpointResetPassword = '/api/auth/reset-password';
  static const String endpointSignup = '/api/app/auth/signup';
  static const String endpointMe = '/api/auth/me';
  static const String endpointSetupStatus = '/api/auth/setup-status';
  static const String endpointSetup = '/api/auth/setup';
}
