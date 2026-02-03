import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/di/dependency_injection.dart';
import 'core/services/app_lifecycle_manager.dart';
import 'data/datasources/supabase_user_assignment_data_source.dart';
import 'domain/entities/user.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/bloc/settings/app_settings_bloc.dart';
import 'presentation/bloc/settings/app_settings_state.dart';
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
    debugPrint('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize Firebase: $e');
  }

  // Initialize Supabase
  try {
    debugPrint('🚀 Initializing Supabase...');
    await SupabaseUserAssignmentDataSource.initialize();
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize Supabase: $e');
    debugPrint(
      '   Make sure you have set your Supabase credentials in supabase_config.dart',
    );
  }

  // Initialize notifications
  await requestNotificationPermission();
  await NotificationService.init();

  // Initialize dependency injection (includes Hive)
  await DependencyInjection.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLifecycleManager _lifecycleManager;

  @override
  void initState() {
    super.initState();

    // Initialize lifecycle manager
    _lifecycleManager = AppLifecycleManager(
      settingsRepository: DependencyInjection.appSettingsRepository,
      hiveService: DependencyInjection.hiveService,
      onResumed: () {
        debugPrint('App resumed - refreshing data');
        // You can trigger data refresh here if needed
      },
      onPaused: () {
        debugPrint('App paused - saving state');
      },
    );
    _lifecycleManager.init();
  }

  @override
  void dispose() {
    _lifecycleManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: DependencyInjection.providers,
      child: BlocBuilder<AppSettingsBloc, AppSettingsState>(
        builder: (context, settingsState) {
          return BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              // Use settings theme mode if available, otherwise use ThemeCubit
              final themeMode =
                  settingsState is AppSettingsLoaded
                      ? settingsState.themeMode
                      : themeState.themeMode;

              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Bus Tracker',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
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
                      }
                    }

                    // Default to login page if unauthenticated or error
                    return const LoginPage();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
