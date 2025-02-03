import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/screens/auth/login_screen.dart';
import 'package:who_location_app/screens/auth/register_screen.dart';
import 'package:who_location_app/screens/home/home_screen.dart';
import 'package:who_location_app/screens/error/not_found_screen.dart';
import 'package:who_location_app/screens/home/task_detail_screen.dart';
import 'package:who_location_app/services/navigation_service.dart';
final goRouter = GoRouter(
  navigatorKey: navigatorKey, // Using the same navigator key
  initialLocation: '/',
  errorBuilder: (context, state) => const NotFoundScreen(),
  redirect: (context, state) {
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated;
    final isGoingToAuth = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isGoingToAuth) {
      return '/login';
    }

    if (isLoggedIn && isGoingToAuth) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RegisterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
      routes: [
        GoRoute(
          path: 'tasks/:id',
          pageBuilder: (context, state) {
            final taskId = state.pathParameters['id']!;
            return CustomTransitionPage(
              key: state.pageKey,
              child: TaskDetailScreen(taskId: taskId),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  )),
                  child: child,
                );
              },
            );
          },
        ),
      ],
    ),
  ],
);
