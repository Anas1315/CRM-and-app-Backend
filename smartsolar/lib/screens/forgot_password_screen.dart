import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartsolar/providers/auth_provider.dart';
import 'package:smartsolar/utils/theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  int? _userId;
  bool _codeSent = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _contactController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRequestCode() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final contact = _contactController.text.trim();

      // Determine if it's email or phone
      final isEmail = contact.contains('@');

      final result = await authProvider.forgotPassword(
        email: isEmail ? contact : null,
        phone: !isEmail ? contact : null,
      );

      if (result != null && mounted) {
        setState(() {
          _userId = result['user_id'];
          _codeSent = true;
          if (result['code'] != null) {
            _codeController.text = result['code'].toString();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset code: ${result['code']} (Autofilled for testing)'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 6),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Request failed'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.resetPassword(
        userId: _userId!,
        code: _codeController.text.trim(),
        newPassword: _passwordController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successful! Please login.'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Reset failed'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTheme.textDark;
    final subtitleColor = isDark ? AppTheme.textLight : AppTheme.textMuted;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    AppTheme.darkerBg,
                    AppTheme.darkBg,
                    AppTheme.cardDarkAlt,
                  ]
                : const [
                    AppTheme.lightCream,
                    AppTheme.lightBg,
                    AppTheme.lightSky,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shadowColor: (isDark ? Colors.black : AppTheme.primaryDark)
                    .withValues(alpha: isDark ? 0.4 : 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: isDark ? AppTheme.cardDark : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _codeSent
                                ? Icons.lock_reset
                                : Icons.contact_support_outlined,
                            size: 48,
                            color: isDark ? AppTheme.primaryLight : AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _codeSent ? 'New Password' : 'Forgot Password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _codeSent
                              ? 'Enter the code and your new password'
                              : 'Enter your email or phone number to receive a reset code',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 36),
                        if (!_codeSent) ...[
                          TextFormField(
                            controller: _contactController,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Email or Phone Number',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your contact info';
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          TextFormField(
                            controller: _codeController,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '6-Digit Reset Code',
                              prefixIcon: const Icon(Icons.pin_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter code';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _isPasswordVisible = !_isPasswordVisible,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter new password';
                              }
                              if (value.length < 6) {
                                return 'At least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : (_codeSent ? _handleResetPassword : _handleRequestCode),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppTheme.primaryLight : AppTheme.primary,
                            foregroundColor: isDark ? AppTheme.textDark : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: isDark ? AppTheme.textDark : Colors.white,
                                  ),
                                )
                              : Text(
                                  _codeSent ? 'Reset Password' : 'Send Code',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
