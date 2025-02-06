import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/task_provider.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/models/task.dart';

void showAddNoteDialog(BuildContext context, Task task, String taskId) {
  String note = '';
  final token = context.read<AuthProvider>().user?.token;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Center(
          child: Text('Add Note'),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
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
              ],
            ),
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
                      await context.read<TaskProvider>().updateTask(
                            taskId: int.parse(taskId),
                            token: token,
                            note: note,
                            status: task.status,
                          );
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  }
                : null,
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}
