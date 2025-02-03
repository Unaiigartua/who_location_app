import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/screens/home/map_tab.dart';
import 'package:who_location_app/screens/home/tasks_tab.dart';
import 'package:who_location_app/screens/home/profile_tab.dart';
import 'package:go_router/go_router.dart';
import 'package:who_location_app/services/websocket_service.dart';
import 'package:who_location_app/utils/token_storage.dart';

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
    _initializeWebSocket();
  }

  void _initializeWebSocket() async {
    final token = await TokenStorage.getToken();
    if (token != null) {
      _wsService.connect(
        token,
        onNotificationReceived: (data) {
          // Get the current user ID through AuthProvider
          final currentUserId = context.read<AuthProvider>().user?.id;
          if (currentUserId != null && (data['notification']['users'] as List).contains(currentUserId)) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Notification'),
                  content: Text(data['notification']['message']),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
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
      appBar: AppBar(
        title: const Text('Home'),
      ),
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
