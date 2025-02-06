import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/task_provider.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/models/task.dart';

void showHandleTaskDialog(BuildContext context, Task task, String taskId) {
  String note = '';
  final token = context.read<AuthProvider>().user?.token;
  final username = context.read<AuthProvider>().user?.username ?? 'Unknown';
  final TextEditingController noteController = TextEditingController(
    text: 'Task handled by $username',
  );
  note = noteController.text;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Center(
          child: Text('Handle Task'),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'Enter your note here',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              note = value;
              // Trigger rebuild to update button state
              (context as Element).markNeedsBuild();
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            onPressed: note.isNotEmpty
                ? () async {
                    if (token != null) {
                      if (task.status == 'issue_reported') {
                        await context.read<TaskProvider>().updateTask(
                              taskId: int.parse(taskId),
                              token: token,
                              note: note,
                              status: 'in_progress',
                            );
                      } else if (task.status == 'new') {
                        await context.read<TaskProvider>().updateTask(
                              taskId: int.parse(taskId),
                              token: token,
                              note: note,
                              status: 'in_progress',
                            );
                      }
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  }
                : null,
            child: const Text('Handle'),
          ),
        ],
      );
    },
  );
}
