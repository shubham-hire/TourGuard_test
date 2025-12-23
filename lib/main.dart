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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ExploreScreen(),
    const EmergencyScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allow body to extend behind the floating navbar
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [AppColors.saffron, Colors.white, AppColors.indiaGreen],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2), // Gradient border width
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0, // Remove internal elevation
            selectedItemColor: AppColors.navyBlue,
            unselectedItemColor: AppColors.textLight,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 10),
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emergency_outlined),
                activeIcon: Icon(Icons.emergency),
                label: 'Emergency',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}