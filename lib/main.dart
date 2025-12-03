import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:bus_tracker/bloc/map_bloc.dart';
import 'package:bus_tracker/bloc/map_event.dart';
import 'package:bus_tracker/service/notification_service.dart';
import 'package:bus_tracker/theme/app_theme.dart';
import 'package:bus_tracker/theme/theme_cubit.dart';
import 'package:bus_tracker/theme/theme_state.dart';
import 'screens/map_page.dart';
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

  // Correct way for your version of hydrated_bloc
  final appDoc = await getApplicationDocumentsDirectory();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(appDoc.path),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
  }

  await requestNotificationPermission();
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => MapBloc()..add(LoadUserLocation())),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Bus Tracker',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.themeMode,
            home: const SafeArea(child: MapPage()),
          );
        },
      ),
    );
  }
}
