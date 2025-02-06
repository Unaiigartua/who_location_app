import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:who_location_app/screens/home/task_history_screen.dart';
import 'package:who_location_app/screens/admin/user_management_screen.dart';
import 'package:who_location_app/screens/report_screen.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  AccountTabState createState() => AccountTabState();
}

class AccountTabState extends State<AccountTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String formatRole(String? role) {
    if (role == null) return 'Unknown';

    // Split role name into words by underscore.
    final words = role.split('_');

    // Capitalize the first letter of each word.
    return words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              // Show confirmation dialog
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Center(
                      child: Text(
                        'Confirm Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    content: const Text('Are you sure you want to log out?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  );
                },
              );

              // If user confirms, proceed with logout
              if (confirm == true) {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.username ?? 'User',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Role: ${formatRole(user?.role)}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.assignment_ind),
              title: Text(user?.role == 'admin' ? 'All Tasks' : 'My Tasks'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskHistoryScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Reports'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportScreen(
                      isAdmin: user?.role == 'admin',
                      onUnauthorized: () {
                        // Handle unauthorized access, e.g., redirect to login
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ),
                );
              },
            ),
            if (user?.role == 'admin')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('User Management'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserManagementScreen(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
