import 'package:mechmate_app/features/auth/auth.dart';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:mechmate_app/core/core.dart';
import 'package:mechmate_app/features/owner/screens/owner_main_screen.dart';
import 'package:mechmate_app/features/mechanic/screens/mechanic_main_screen.dart';
import 'package:mechmate_app/shared/shared.dart';
import 'package:mechmate_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
    // FlutterError.onError still catches startup crashes
  }

  // Route Flutter errors through Crashlytics
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await ConnectivityService.instance.initialize();

  runApp(const MechMateApp());
}

// ignore: prefer-mixin
class MechMateApp extends StatelessWidget {
  const MechMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => AppAuthProvider(AuthService()),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, _) {
          return ErrorBoundary(
            child: OfflineBanner(
              child: MaterialApp(
                title: 'MechMate',
                debugShowCheckedModeBanner: false,
                themeMode: themeProvider.themeMode,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                initialRoute: AppRoutes.splash,
                routes: {
                  AppRoutes.splash: (_) => const SplashScreen(),
                  AppRoutes.roleSelect: (_) => const RoleSelectionScreen(),
                  AppRoutes.login: (_) => const LoginScreen(),
                  AppRoutes.registerOwner: (_) => const RegisterOwnerScreen(),
                  AppRoutes.registerMechanic: (_) =>
                      const RegisterMechanicScreen(),
                  AppRoutes.ownerMain: (_) => const OwnerMainScreen(),
                  AppRoutes.mechanicMain: (_) => const MechanicMainScreen(),
                  AppRoutes.otpVerification: (_) => const OtpVerificationScreen(),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
