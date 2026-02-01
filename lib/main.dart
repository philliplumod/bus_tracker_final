import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/di/dependency_injection.dart';
import 'domain/entities/user.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/rider_navigation_wrapper.dart';
import 'presentation/pages/passenger_navigation_wrapper.dart';
import 'service/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_cubit.dart';
import 'theme/theme_state.dart';
import 'firebase_options.dart';

Future<void> requestNotificationPermission() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final androidImplementation =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  if (androidImplementation != null) {
    await androidImplementation.requestNotificationsPermission();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize HydratedBloc storage
  final appDoc = await getApplicationDocumentsDirectory();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(appDoc.path),
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
  }

  // Initialize notifications
  await requestNotificationPermission();
  await NotificationService.init();

  // Initialize dependency injection
  await DependencyInjection.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: DependencyInjection.providers,
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Bus Tracker',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.themeMode,
            home: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, authState) {
                // Handle errors at the app level to ensure SnackBar shows
                if (authState is AuthError) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  authState.message,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red.shade700,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 5),
                          action: SnackBarAction(
                            label: 'Dismiss',
                            textColor: Colors.white,
                            onPressed: () {
                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();
                            },
                          ),
                        ),
                      );
                    }
                  });
                }
              },
              builder: (context, authState) {
                if (authState is AuthLoading || authState is AuthInitial) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (authState is AuthAuthenticated) {
                  // Route based on user role
                  final user = authState.user;

                  switch (user.role) {
                    case UserRole.rider:
                      return SafeArea(
                        child: RiderNavigationWrapper(rider: user),
                      );
                    case UserRole.passenger:
                      return const SafeArea(
                        child: PassengerNavigationWrapper(),
                      );
                    case UserRole.admin:
                      // TODO: Create admin page
                      return const SafeArea(
                        child: PassengerNavigationWrapper(),
                      );
                  }
                }

                // Default to login page if unauthenticated or error
                return const LoginPage();
              },
            ),
          );
        },
      ),
    );
  }
}
