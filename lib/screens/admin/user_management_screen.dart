import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/services/task_service.dart';
import 'package:who_location_app/api/user_api.dart';
import 'package:dio/dio.dart';
import 'package:who_location_app/screens/admin/admin_register_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Future<List<Map<String, dynamic>>> _usersFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    final authProvider = context.read<AuthProvider>();
    final token = await authProvider.getToken();
    debugPrint('Token obtained: $token');
    if (token != null) {
      final taskService = TaskService(Dio(BaseOptions(headers: {'Authorization': 'Bearer $token'})));
      setState(() {
        _usersFuture = taskService.getUserByRole(token, null);
      });
      _usersFuture.then((users) => debugPrint('Users obtained: $users')).catchError((error) => debugPrint('Error obtaining users: $error'));
    } else {
      setState(() {
        _usersFuture = Future.error('Token not available');
      });
      debugPrint('Token not available');
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userApi = UserApi(() => authProvider.logout());
      await userApi.deleteUser(int.parse(userId));
      setState(() {
        _loadUsers();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminRegisterScreen(),
              ),
            ),
            tooltip: 'Add New User',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userId = user['id'] as int;
              final userName = user['username'] as String;
              final userRole = user['role'] as String;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('$userName (ID: $userId)'),
                  subtitle: Text('Rol: $userRole'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: const Text('Are you sure you want to delete this user?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        _deleteUser(userId.toString());
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}