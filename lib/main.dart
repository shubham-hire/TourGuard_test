import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'core/constants/app_colors.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/pages/splash_screen.dart';
import 'presentation/pages/login_screen.dart';
import 'presentation/pages/registration_screen.dart';
import 'presentation/pages/otp_screen.dart';
import 'presentation/pages/success_screen.dart';
import 'presentation/pages/profile_photo_screen.dart';
import 'package:tourguard/screens/dashboard_screen.dart';
// geofence_demo is available in the project but not set as the home screen.
import 'package:tourguard/screens/profile_screen.dart';
import 'package:tourguard/screens/explore_screen.dart';
import 'package:tourguard/screens/emergency_screen.dart';
import 'package:tourguard/screens/settings_screen_v2.dart';
import 'package:tourguard/services/notification_service.dart';
import 'package:tourguard/services/api_service.dart';
import 'package:tourguard/services/chat_service.dart';
import 'package:tourguard/services/incident_service.dart';
import 'package:tourguard/services/localization_service.dart';
import 'package:tourguard/services/offline_map_service.dart';
import 'package:tourguard/services/location_service.dart';
import 'package:tourguard/services/location_emitter.dart';
import 'package:tourguard/services/websocket_service.dart';
import 'package:tourguard/app/router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  
  // Initialize services
  await NotificationService.initialize();
  await ApiService.initCache();
  await ChatService.initialize();
  await IncidentService.initIncidents();
  await LocalizationService.initialize();
  await OfflineMapService.initialize();
  // Initialize location services in background (non-blocking)
  // Don't await - app starts immediately, location initializes in parallel
  LocationService().initialize().then((_) {
    WebSocketService().init(); // Connect to backend
    LocationEmitter().start(); // Start sending updates
  });
  
  runApp(
    // Riverpod ProviderScope wraps entire app - state persists across navigation
    const ProviderScope(
      child: TouristSafetyHub(),
    ),
  );
}

class TouristSafetyHub extends StatelessWidget {
  const TouristSafetyHub({super.key});

  @override
  Widget build(BuildContext context) {
    return provider_pkg.MultiProvider(
      providers: [
        provider_pkg.ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp.router(
        title: 'TourGuard',
        theme: ThemeData(
          primaryColor: AppColors.navyBlue,
          scaffoldBackgroundColor: AppColors.surfaceWhite,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.navyBlue,
            primary: AppColors.navyBlue,
            secondary: AppColors.saffron,
            surface: AppColors.surfaceWhite,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surfaceWhite,
            foregroundColor: AppColors.textDark,
            elevation: 0,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.navyBlue,
            unselectedItemColor: AppColors.textLight,
            elevation: 8,
            type: BottomNavigationBarType.fixed,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        routerConfig: router, // GoRouter handles all navigation
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// MainNavigationScreen is now in lib/app/router.dart as MainShell