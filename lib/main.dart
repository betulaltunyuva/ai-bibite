import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'services/theme_service.dart';

// Firebase Messaging Background Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("BACKGROUND MESSAGE: ${message.notification?.title}");
}

void main() {
  // WidgetsFlutterBinding'i hemen başlat
  WidgetsFlutterBinding.ensureInitialized();

  // Uygulamayı HEMEN başlat (Android splash ekranı minimum süre görünsün)
  runApp(const MyApp());

  // Tüm initialization'ları arka planda yap (await yok, hemen devam eder)
  _initializeAppInBackground();
}

// Initialization işlemlerini arka planda yap
Future<void> _initializeAppInBackground() async {
  // Supabase'i başlat
  try {
    await Supabase.initialize(
      url: 'https://ucrrhykwxsanswkxytsa.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjcnJoeWt3eHNhbnN3a3h5dHNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwMTA1NjQsImV4cCI6MjA4MDU4NjU2NH0.AlLiMba43jlw42-DTMj6zInG6gqK1LkuxFST4udA9o0',
    );
  } catch (e) {
    // Sessiz mod
  }

  // Firebase Core'u başlat
  try {
    print("Firebase: Initializing Firebase Core...");
    await Firebase.initializeApp();
    print("Firebase: Firebase Core initialized successfully");
  } catch (e, stackTrace) {
    print("Firebase Core ERROR: $e");
    print("Stack trace: $stackTrace");
    if (kDebugMode) {
      developer.log('Firebase Core initialization error: $e', name: 'Firebase');
    }
  }

  // Firebase Messaging Background Handler'ı kaydet (Firebase.initializeApp() sonrası)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Firebase Notification Channel'ı oluştur
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications.',
    importance: Importance.high,
  );

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Foreground bildirim gösterimini aktif et
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Firebase Messaging permission request
  try {
    print("Firebase Messaging: Requesting permission...");
    final permissionStatus = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: true
    );
    print("Firebase Messaging: Permission status: $permissionStatus");

    // Token al ve yazdır
    print("Firebase Messaging: Getting token...");
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      print("FCM TOKEN FROM MAIN: $token");
    } else {
      print("FCM TOKEN FROM MAIN: null - Token alınamadı!");
    }

    // Token refresh listener
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print("NEW FCM TOKEN: $newToken");
    });
  } catch (e, stackTrace) {
    print("Firebase Messaging ERROR: $e");
    print("Stack trace: $stackTrace");
    if (kDebugMode) {
      developer.log('Firebase Messaging initialization error: $e', name: 'FirebaseMessaging');
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _themeService.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _themeService.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI BiBite',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        primaryColor: const Color(0xFF2F6F3E),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6FBF8),
        cardColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.teal,
        primaryColor: const Color(0xFF2F6F3E),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1F1C),
        cardColor: const Color(0xFF2A2F2C),
        dividerColor: const Color(0xFF3A3F3C),
        useMaterial3: true,
      ),
      themeMode: _themeService.themeMode,
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/profile-info': (context) => const ProfileScreen(),
        '/home': (context) => const HomeScreen(),
        '/chat': (context) => const ChatScreen(),
      },
    );
  }
}
