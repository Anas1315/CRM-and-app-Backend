import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:smartsolar/providers/auth_provider.dart';
import 'package:smartsolar/providers/energy_provider.dart';
import 'package:smartsolar/providers/theme_provider.dart';
import 'package:smartsolar/screens/alerts_screen.dart';
import 'package:smartsolar/screens/analytics_screen.dart';
import 'package:smartsolar/screens/controls_screen.dart';
import 'package:smartsolar/screens/home_screen.dart';
import 'package:smartsolar/screens/login_screen.dart';
import 'package:smartsolar/screens/settings_screen.dart';
import 'package:smartsolar/screens/setup_screen.dart';
import 'package:smartsolar/services/notification_service.dart';
import 'package:smartsolar/utils/constants.dart';
import 'package:smartsolar/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await Constants.initBaseUrl();
  runApp(const SmartEnergyApp());
  Future<void>.microtask(() async {
    await NotificationService().initialize();
  });
}

class SmartEnergyApp extends StatelessWidget {
  final bool autoConnect;

  const SmartEnergyApp({super.key, this.autoConnect = true});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(checkSetup: autoConnect),
        ),
        ChangeNotifierProvider(
          create: (_) => EnergyProvider(autoConnect: autoConnect),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Smart Energy Controller',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (authProvider.needsSetup) {
                  return const SetupScreen();
                }
                return authProvider.isAuthenticated
                    ? const MainNavigation()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final Map<int, Widget> _screensCache = {};

  Widget _screenForIndex(int index, bool isWapdaOnly) {
    final cacheKey = isWapdaOnly ? index + 100 : index;
    if (_screensCache.containsKey(cacheKey)) {
      return _screensCache[cacheKey]!;
    }

    Widget screen;
    if (isWapdaOnly) {
      screen = switch (index) {
        1 => const ControlsScreen(),
        2 => const AlertsScreen(),
        3 => const SettingsScreen(),
        _ => const HomeScreen(),
      };
    } else {
      screen = switch (index) {
        1 => const ControlsScreen(),
        2 => const AnalyticsScreen(),
        3 => const AlertsScreen(),
        4 => const SettingsScreen(),
        _ => const HomeScreen(),
      };
    }
    _screensCache[cacheKey] = screen;
    return screen;
  }

  void _selectTab(int index, bool isWapdaOnly) {
    final alertsIndex = isWapdaOnly ? 2 : 3;
    if (index == alertsIndex) {
      final provider = Provider.of<EnergyProvider>(context, listen: false);
      provider.markAllAlertsAsRead();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final energyProvider = context.watch<EnergyProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isWapdaOnly = user?.isWapdaOnly ?? false;

    // Reset index if it gets out of bounds when SKU status changes
    final maxIndex = isWapdaOnly ? 3 : 4;
    if (_currentIndex > maxIndex) {
      _currentIndex = 0;
    }

    final unreadCount = energyProvider.alerts.where((a) {
      if (a is! Map) return false;
      return !(a['isRead'] ?? a['read'] ?? false);
    }).length;

    final items = <Widget>[
      Icon(
        _currentIndex == 0 ? Icons.home : Icons.home_outlined,
        size: 30,
        color: _currentIndex == 0 ? Colors.white : Colors.grey,
      ),
      Icon(
        _currentIndex == 1 ? Icons.tune : Icons.tune_outlined,
        size: 30,
        color: _currentIndex == 1 ? Colors.white : Colors.grey,
      ),
      if (!isWapdaOnly)
        Icon(
          _currentIndex == 2 ? Icons.bar_chart : Icons.bar_chart_outlined,
          size: 30,
          color: _currentIndex == 2 ? Colors.white : Colors.grey,
        ),
      Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        backgroundColor: Colors.red,
        textColor: Colors.white,
        child: Icon(
          _currentIndex == (isWapdaOnly ? 2 : 3)
              ? Icons.notifications
              : Icons.notifications_none_outlined,
          size: 30,
          color: _currentIndex == (isWapdaOnly ? 2 : 3)
              ? Colors.white
              : Colors.grey,
        ),
      ),
      Icon(
        _currentIndex == (isWapdaOnly ? 3 : 4)
            ? Icons.settings
            : Icons.settings_outlined,
        size: 30,
        color: _currentIndex == (isWapdaOnly ? 3 : 4)
            ? Colors.white
            : Colors.grey,
      ),
    ];

    return Scaffold(
      body: _screenForIndex(_currentIndex, isWapdaOnly),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        height: 60.0,
        items: items,
        color: isDark ? AppTheme.cardDark : Colors.white,
        buttonBackgroundColor: AppTheme.primary,
        backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF5F7FA),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) => _selectTab(index, isWapdaOnly),
      ),
    );
  }
}
