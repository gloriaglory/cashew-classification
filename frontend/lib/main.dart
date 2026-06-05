import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'presentation/splash/splash_screen.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/dashboard/dashboard_screen.dart';
import 'presentation/detection/scan_screen.dart';
import 'presentation/detection/result_screen.dart';
import 'presentation/history/history_screen.dart';
import 'presentation/profile/profile_screen.dart';
import 'presentation/admin/admin_login_screen.dart';
import 'presentation/admin/admin_dashboard_screen.dart';
import 'presentation/admin/admin_diseases_screen.dart';
import 'presentation/admin/admin_pesticides_screen.dart';
import 'presentation/admin/admin_activities_screen.dart';
import 'presentation/admin/admin_users_screen.dart';
import 'presentation/admin/admin_model_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const CashewCareApp());
}

class CashewCareApp extends StatelessWidget {
  const CashewCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
      ],
      child: MaterialApp(
        title: 'CashewCare',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/':                    (_) => const SplashScreen(),
          '/login':               (_) => const LoginScreen(),
          '/register':            (_) => const RegisterScreen(),
          '/dashboard':           (_) => const DashboardScreen(),
          '/scan':                (_) => const ScanScreen(),
          '/history':             (_) => const HistoryScreen(),
          '/profile':             (_) => const ProfileScreen(),
          '/admin/login':         (_) => const AdminLoginScreen(),
          '/admin/dashboard':     (_) => const AdminDashboardScreen(),
          '/admin/diseases':      (_) => const AdminDiseasesScreen(),
          '/admin/pesticides':    (_) => const AdminPesticidesScreen(),
          '/admin/activities':    (_) => const AdminActivitiesScreen(),
          '/admin/users':         (_) => const AdminUsersScreen(),
          '/admin/model':         (_) => const AdminModelScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/result') {
            return MaterialPageRoute(
              builder: (_) => ResultScreen(result: settings.arguments as Map<String, dynamic>),
            );
          }
          return null;
        },
      ),
    );
  }
}
