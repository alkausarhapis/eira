import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'services/app_blocking_service.dart';
import 'services/blocked_apps_database.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/blocked_apps_viewmodel.dart';
import 'viewmodels/microtask_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'views/blocked_apps_page.dart';
import 'views/home_page.dart';
import 'views/settings_page.dart';

// TODO: Remove logging
// TODO: Remove smell codes
// TODO: Remove unnecessary comments & codes
// TODO: Hapus semua kata kata "Pembatasan Aplikasi" ganti jadi "Pemblokiran Aplikasi"
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService.instance.initialize();
  debugPrint('✅ Notification service initialized');

  // Set up notification listener from native
  const platform = MethodChannel('com.eira/native_block');
  platform.setMethodCallHandler((call) async {
    if (call.method == 'showNotification') {
      final action = call.arguments['action'] as String;
      final appName = call.arguments['appName'] as String;

      if (action == 'showOneMinuteWarning') {
        await NotificationService.instance.showOneMinuteWarning(appName);
      } else if (action == 'showBlockedNotification') {
        await NotificationService.instance.showBlockedNotification(appName);
      }
    }
  });

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Environment variables loaded');
  } catch (e) {
    debugPrint('⚠️ Could not load .env file: $e');
    debugPrint('⚠️ Make sure to create a .env file with your GEMINI_API_KEY');
  }

  // Initialize blocked apps in Accessibility Service on startup
  try {
    final database = BlockedAppsDatabase.instance;
    final blockingService = AppBlockingService();

    // Load blocked apps from database
    final blockedApps = await database.getBlockedApps();
    final packageNames = blockedApps.map((app) => app.packageName).toList();

    // Update Accessibility Service with blocked apps list
    await blockingService.setBlockedApps(packageNames);
    debugPrint('✅ Initialized ${packageNames.length} blocked apps on startup');
  } catch (e) {
    debugPrint('❌ Error initializing blocked apps: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => MicrotaskViewModel()),
        ChangeNotifierProvider(create: (_) => BlockedAppsViewModel()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<ThemeViewModel>();

    return MaterialApp(
      title: 'Eira',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeViewModel.themeMode,
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    BlockedAppsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.brightness == Brightness.light
                  ? Colors.grey.shade300
                  : Colors.grey.shade800,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: theme.textTheme.bodyMedium?.color,
          elevation: 0,
          enableFeedback: false,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.block_outlined),
              activeIcon: Icon(Icons.block),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
