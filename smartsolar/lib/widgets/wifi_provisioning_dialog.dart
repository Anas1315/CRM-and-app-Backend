import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsolar/providers/auth_provider.dart';
import 'package:smartsolar/utils/constants.dart';
import 'package:smartsolar/utils/theme.dart';

class WifiProvisioningDialog extends StatefulWidget {
  const WifiProvisioningDialog({super.key});

  @override
  State<WifiProvisioningDialog> createState() => _WifiProvisioningDialogState();
}

class _WifiProvisioningDialogState extends State<WifiProvisioningDialog> {
  int _stage = 1; // 1: Connection Guide, 2: SSID & Password Config
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
    final _uidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _ssidController.text = prefs.getString('wifi_name') ?? '';
      _uidController.text = authProvider.user?.deviceId ?? '';
    });
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _uidController.dispose();
    super.dispose();
  }

  Future<void> _submitProvisioning() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final ssid = Uri.encodeComponent(_ssidController.text.trim());
    final pass = Uri.encodeComponent(_passwordController.text.trim());
    final uid = Uri.encodeComponent(_uidController.text.trim());

    // ESP32 Provisioning Portal Endpoint
    final url =
        'http://192.168.4.1/save-config?ssid=$ssid&pass=$pass&device_uid=$uid';

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        // Save the Wi-Fi name locally for convenience next time
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('wifi_name', _ssidController.text.trim());

        setState(() {
          _successMessage =
              'Configuration sent successfully!\nDevice is restarting to connect...';
        });

        // Auto-close dialog after 3.5 seconds
        await Future.delayed(const Duration(milliseconds: 3500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to configure: Server returned code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Connection timeout. Make sure you are connected to the "SolarController-XXXX" Wi-Fi network and try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.cardDarkAlt : Colors.white;
    final textCol = isDark ? Colors.white : AppTheme.textDark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: cardBg,
      elevation: 24,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 620),
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? _buildLoadingState()
              : _successMessage != null
              ? _buildSuccessState()
              : _stage == 1
              ? _buildGuideStage(textCol, isDark)
              : _buildFormStage(textCol, isDark),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
        const CircularProgressIndicator(
          color: AppTheme.primary,
          strokeWidth: 4,
        ),
        const SizedBox(height: 24),
        const Text(
          'Provisioning Device...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Sending credentials to the ESP32 controller. Please keep your phone close to the device.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        const Text(
          'Configured Successfully!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _successMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGuideStage(Color textCol, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wifi_tethering, color: AppTheme.primary, size: 26),
            const SizedBox(width: 10),
            Text(
              'WiFi Provisioning',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: textCol,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Step 1: Connect to Solar Controller',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.primaryLight : AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Go to your phone\'s Wi-Fi Settings.',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 6),
              Text(
                '2. Connect to Wi-Fi network: SolarController-XXXXXX',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '3. Enter Password: solar1234',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 6),
              Text(
                '4. Once connected, return to this app and tap Next.',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => setState(() => _stage = 2),
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormStage(Color textCol, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: AppTheme.primary, size: 26),
              const SizedBox(width: 10),
              Text(
                'Device Setup',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textCol,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Text(
            'Step 2: Enter WiFi & Device Identity',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.primaryLight : AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _ssidController,
            decoration: InputDecoration(
              labelText: 'Home Wi-Fi Name (SSID)',
              labelStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.wifi, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter Wi-Fi SSID' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Wi-Fi Password',
              labelStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter Wi-Fi Password' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _uidController,
            decoration: InputDecoration(
              labelText: 'Device UID',
              labelStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.fingerprint, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter Device UID' : null,
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                onPressed: () => setState(() => _stage = 1),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onPressed: _submitProvisioning,
                child: const Text('Save & Connect'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
