import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/dashboard_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/emergency_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/incident_report_screen.dart';
import '../presentation/pages/splash_screen.dart';
import '../presentation/pages/login_screen.dart';
import '../presentation/pages/registration_screen.dart';
import '../presentation/pages/otp_screen.dart';
import '../presentation/pages/success_screen.dart';
import '../presentation/pages/profile_photo_screen.dart';
import '../presentation/pages/forgot_password_screen.dart';
import '../presentation/pages/reset_password_screen.dart';
import '../screens/settings_screen_v2.dart';
import '../core/constants/app_colors.dart';

/// Main navigation shell - holds the bottom nav bar
/// Screens stay in memory when switching tabs = instant navigation
class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _tabs = [
    '/dashboard',
    '/explore', 
    '/emergency',
    '/profile',
  ];

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      context.go(_tabs[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update selected index based on current location
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) {
        if (_selectedIndex != i) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedIndex = i);
          });
        }
        break;
      }
    }

    return Scaffold(
      extendBody: true,
      body: widget.child,
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
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
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

/// GoRouter configuration
/// Uses ShellRoute to keep MainShell (and its nav bar) persistent
final router = GoRouter(
  initialLocation: '/',
  routes: [
    // Auth flow routes (no bottom nav)
    GoRoute(path: '/', builder: (_, __) => SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => RegistrationScreen()),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final phoneNumber = state.extra as String? ?? '';
        return OtpScreen(phoneNumber: phoneNumber);
      },
    ),
    GoRoute(
      path: '/profile-photo',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        return ProfilePhotoScreen(
          hashId: args['hashId'] ?? '',
          userName: args['userName'] ?? '',
          phone: args['phone'] ?? '',
        );
      },
    ),
    GoRoute(path: '/success', builder: (_, __) => SuccessScreen()),
    
    // Password Reset Flow
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return ResetPasswordScreen(phone: phone);
      },
    ),
    
    // Settings Route
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    
    // Incident Report Route (Outside shell - no bottom nav)
    GoRoute(
      path: '/incident-report',
      builder: (context, state) => const IncidentReportScreen(),
    ),

    // Main app with bottom navigation (ShellRoute keeps nav bar persistent)
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/explore',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ExploreScreen(),
          ),
        ),
        GoRoute(
          path: '/emergency',
          pageBuilder: (context, state) {
             final autoTrigger = state.uri.queryParameters['autoTrigger'] == 'true';
             return NoTransitionPage(
               child: EmergencyScreen(autoTrigger: autoTrigger),
             );
          },
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),
  ],
);
