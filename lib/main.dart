import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kanairoxo/app.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:kanairoxo/providers/connection_provider.dart';
import 'package:kanairoxo/providers/events_provider.dart';
import 'package:kanairoxo/providers/notification_provider.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:kanairoxo/providers/theme_provider.dart';
import 'package:kanairoxo/providers/moment_provider.dart';
import 'package:kanairoxo/providers/date_plan_provider.dart';
import 'package:kanairoxo/services/notification_service.dart';
import 'package:kanairoxo/services/moment_service.dart';
import 'package:kanairoxo/services/spotify_service.dart';
import 'package:kanairoxo/services/widget_service.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/auth_gate.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

final NotificationService notificationService = NotificationService();

// Must be a top-level function — handles FCM when app is in background/terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background messages are shown automatically by FCM on Android
  // No extra work needed here
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp();
    // Register background handler before anything else
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('Firebase initialized. Initializing Notification Service...');
    await notificationService.init();
  } catch (e) {
    debugPrint('Critical service initialization failed: $e');
  }

  WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
  GoogleFonts.config.allowRuntimeFetching = true;
  
  runApp(const MyApp());
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
      await WidgetService.refreshAllWidgets(moments, 0, 0);
    } catch (e) {
      debugPrint('Widget refresh error: $e');
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription? _linkSub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initial = await _appLinks.getInitialAppLink();
      if (initial != null) {
        _handleDeepLink(initial.toString());
      }
      _linkSub = _appLinks.uriLinkStream.listen((uri) {
        _handleDeepLink(uri.toString());
      }, onError: (e) {
        debugPrint('Deep link error: $e');
      });
    } catch (e) {
      debugPrint('Deep link init error: $e');
    }
  }

  void _handleDeepLink(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    debugPrint('Deep link received: $uri');
    if (uri.scheme == 'kanairoxo' && uri.host == 'spotify') {
      if (uri.path == '/success') {
        SpotifyService().syncProfile();
      } else if (uri.path == '/callback') {
        final code = uri.queryParameters['code'];
        if (code != null) {
          SpotifyService().handleCallback(code);
        }
      }
    }
  }

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
        ChangeNotifierProxyProvider<AuthProvider, MomentProvider>(
          create: (_) => MomentProvider(),
          update: (_, auth, previous) => (previous ?? MomentProvider())..update(auth),
        ),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider(create: (context) => ConnectionProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DatePlanProvider>(
          create: (_) => DatePlanProvider(),
          update: (_, auth, previous) => (previous ?? DatePlanProvider())..update(auth),
        ),
      ],
      child: const KanairoXOApp(),
    );
  }
}
