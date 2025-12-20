import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
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

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Initialize services
  await NotificationService.initialize();
  await ApiService.initCache();
  await ChatService.initialize();
  await IncidentService.initIncidents();
  await LocalizationService.initialize();
  await OfflineMapService.initialize();
  
  runApp(const TouristSafetyHub());
}

class TouristSafetyHub extends StatelessWidget {
  const TouristSafetyHub({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the MaterialApp whenever the language changes so that any
    // widgets using tr() pick up the new translations.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: ValueListenableBuilder<String>(
        valueListenable: LocalizationService.languageNotifier,
        builder: (context, languageCode, _) {
          return MaterialApp(
            title: 'TourGuard',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              fontFamily: 'Roboto',
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.grey[100],
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.grey[800],
                elevation: 0,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            initialRoute: '/',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(builder: (_) => SplashScreen());
                case '/login':
                  return MaterialPageRoute(builder: (_) => LoginScreen());
                case '/register':
                  return MaterialPageRoute(builder: (_) => RegistrationScreen());
                case '/otp':
                  final phoneNumber = settings.arguments as String;
                  return MaterialPageRoute(
                    builder: (_) => OtpScreen(phoneNumber: phoneNumber),
                  );
                case '/profile-photo':
                  final args = settings.arguments as Map<String, dynamic>;
                  return MaterialPageRoute(
                    builder: (_) => ProfilePhotoScreen(
                      hashId: args['hashId'],
                      userName: args['userName'],
                      phone: args['phone'],
                    ),
                  );
                case '/success':
                  return MaterialPageRoute(builder: (_) => SuccessScreen());
                case '/dashboard':
                  return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
                case '/home':
                  return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
                default:
                  return MaterialPageRoute(builder: (_) => LoginScreen());
              }
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ProfileScreen(),
    ExploreScreen(),
    EmergencyScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: ValueListenableBuilder<String>(
        valueListenable: LocalizationService.languageNotifier,
        builder: (context, language, child) {
          return BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: tr('dashboard'),
                backgroundColor: Colors.blue[800],
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                label: tr('profile'),
                backgroundColor: Colors.blue[800],
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.explore_outlined),
                label: tr('explore'),
                backgroundColor: Colors.blue[800],
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.warning_amber_rounded),
                label: tr('emergency'),
                backgroundColor: Colors.blue[800],
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_outlined),
                label: tr('settings'),
                backgroundColor: Colors.blue[800],
              ),
            ],
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          );
        },
      ),
    );
  }
}