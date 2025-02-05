import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/config/app_config.dart';
import 'package:who_location_app/config/routes.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/providers/task_provider.dart';
import 'package:who_location_app/services/task_service.dart';
import 'package:dio/dio.dart';
import 'package:who_location_app/services/notification_service.dart';

/*
Entry point of the application, setting up the environment and running the app.
*/
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();

  // Set up the environment for development.
  AppConfig.environment = Environment.dev;

  runApp(MyApp());
}

/*
Main application widget that sets up providers and routing.
*/
class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        Provider<TaskService>(
          create: (_) => TaskService(Dio()),
        ),
        ChangeNotifierProvider(
          create: (context) => TaskProvider(
            () => context.read<AuthProvider>().handleUnauthorized(),
          ),
        ),
      ],
      child: MaterialApp.router(
        // No need to define navigatorKey here since goRouter configures it internally.
        title: 'WHO Location Client',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        routerConfig: goRouter,
      ),
    );
  }

  // Build the MaterialApp with providers and router configuration.
}
