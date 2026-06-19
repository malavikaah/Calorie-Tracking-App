import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/dietitian_registration_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/dietitian_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'models/user_account.dart';
import 'services/firebase_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  
  final firebaseService = FirebaseService();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: firebaseService),
        ChangeNotifierProvider(create: (_) => AppState(firebaseService)),
      ],
      child: const CalotrackApp(),
    ),
  );
}

class CalotrackApp extends StatelessWidget {
  const CalotrackApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        // Show Splash Screen if not initialized
        if (!appState.isInitialized) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFFF4F9F1), // Pastel green
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/logo.png', height: 200),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        Widget home;
        if (appState.isLoggedIn) {
          if (appState.userAccount!.role == UserRole.admin) {
            home = const AdminDashboardScreen();
          } else if (appState.userAccount!.role == UserRole.dietitian) {
            home = appState.hasDietitianProfile
                ? (appState.dietitianProfile!.isApproved 
                    ? const DietitianDashboardScreen()
                    : const PendingApprovalScreen())
                : const DietitianRegistrationScreen();
          } else {
            home = appState.hasProfile
                ? const DashboardScreen()
                : const RegistrationScreen();
          }
        } else {
          home = const LoginScreen();
        }

        return MaterialApp(
          title: 'CaloTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(appState.activeTheme),
          home: home,
        );
      },
    );
  }
}
