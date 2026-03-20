import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kanairoxo/app.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/providers/connection_provider.dart';
import 'package:kanairoxo/providers/events_provider.dart';
import 'package:kanairoxo/providers/notification_provider.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:kanairoxo/providers/theme_provider.dart';
import 'package:kanairoxo/services/notification_service.dart';
import 'package:kanairoxo/services/widget_service.dart';
import 'package:kanairoxo/services/moment_service.dart';
import 'package:provider/provider.dart';

final NotificationService notificationService = NotificationService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register observer for widget refreshing
  WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
  
  // Run app immediately
  runApp(const MyApp());

  // Initialize services in the background
  _initializeServices();
}

Future<void> _initializeServices() async {
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 5));
    await notificationService.init();
  } catch (e) {
    debugPrint('Service initialization timed out or failed: $e');
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshWidgets();
    }
  }

  Future<void> _refreshWidgets() async {
    try {
      final momentService = MomentService();
      final moments = await momentService.getMoments();
      // Using unread count 0 as fallback if provider is not accessible directly here
      await WidgetService.refreshAllWidgets(moments, 0, 0);
    } catch (e) {
      debugPrint('Widget refresh error: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (_) => ProfileProvider(),
          update: (_, auth, previous) => (previous ?? ProfileProvider())..update(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, EventsProvider>(
          create: (_) => EventsProvider(),
          update: (_, auth, previous) => (previous ?? EventsProvider())..update(auth),
        ),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider(create: (context) => ConnectionProvider()),
      ],
      child: const KanairoXOApp(),
    );
  }
}
