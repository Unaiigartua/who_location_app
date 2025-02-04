import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/screens/home/map_tab.dart';
import 'package:who_location_app/screens/home/tasks_tab.dart';
import 'package:who_location_app/screens/home/profile_tab.dart';
import 'package:who_location_app/services/websocket_service.dart';
import 'package:who_location_app/utils/token_storage.dart';
import 'package:who_location_app/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final WebSocketService _wsService = WebSocketService();

  final List<Widget> _tabs = const [
    MapTab(),
    TasksTab(),
    AccountTab(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _initializeWebSocket();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.instance.initialize();
  }

  void _initializeWebSocket() async {
    final token = await TokenStorage.getToken();
    if (token != null) {
      _wsService.connect(
        token,
        onNotificationReceived: (data) {
          if (!mounted) return;

          final currentUserId = context.read<AuthProvider>().user?.id;
          if (currentUserId != null &&
              (data['notification']['users'] as List).contains(currentUserId)) {
            final notificationType = data['notification']['type'] ?? 'update';
            final title = switch (notificationType) {
              'new_task' => 'New Task Assigned',
              'status_change' => 'Task Status Updated',
              'assignment' => 'Task Assignment Changed',
              _ => 'Task Update'
            };

            NotificationService.instance.showNotification(
              title,
              data['notification']['message'],
            );
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _wsService.disconnect();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onBottomNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const ClampingScrollPhysics(),
          children: _tabs,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
