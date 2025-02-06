import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/task_provider.dart';
import 'package:who_location_app/models/task.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/utils/helpers.dart';

void showEditTaskDialog(BuildContext context, Task task, String taskId) async {
  String? newStatus = task.status;
  String? newAssignedTo = task.assignedTo?.toString();
  final token = context.read<AuthProvider>().user?.token;
  final username = context.read<AuthProvider>().user?.username ?? 'Unknown';
  final TextEditingController noteController = TextEditingController(
    text: 'Task edited by $username',
  );
  String note = noteController.text;

  // Get user list
  List<Map<String, dynamic>> ambulanceUsers = [];
  List<Map<String, dynamic>> cleaningTeamUsers = [];
  if (token != null) {
    ambulanceUsers =
        await context.read<TaskProvider>().getUserByRole(token, 'ambulance');
    cleaningTeamUsers = await context
        .read<TaskProvider>()
        .getUserByRole(token, 'cleaning_team');
  }

  // Convert to username maps for easier lookup
  Map<String, String> ambulanceUserMap = {
    for (var user in ambulanceUsers)
      user['username'].toString(): user['id'].toString()
  };
  Map<String, String> cleaningTeamMap = {
    for (var user in cleaningTeamUsers)
      user['username'].toString(): user['id'].toString()
  };

  // Get original assigned username if exists
  String? originalAssignedUsername;
  if (task.assignedTo != null) {
    final originalUser = [...ambulanceUsers, ...cleaningTeamUsers].firstWhere(
      (user) => user['id'].toString() == task.assignedTo.toString(),
      orElse: () => {'username': task.assignedTo.toString()},
    );
    originalAssignedUsername = originalUser['username'].toString();
  }

  // Convert assigned user ID to username if it exists
  if (newAssignedTo != null) {
    final assignedUser = [...ambulanceUsers, ...cleaningTeamUsers].firstWhere(
      (user) => user['id'].toString() == newAssignedTo,
      orElse: () => {'username': newAssignedTo},
    );
    newAssignedTo = assignedUser['username'].toString();
  }

  void updateNoteText() {
    String changeNote = 'Task edited by $username:';

    // Add status change info if status changed
    if (newStatus != task.status) {
      changeNote +=
          '\nStatus changed from ${formatStatus(task.status)} to ${formatStatus(newStatus ?? '')}';
    }

    // Add assignee change info if assignee changed
    if (originalAssignedUsername != newAssignedTo) {
      if (originalAssignedUsername == null) {
        changeNote += '\nAssigned to $newAssignedTo';
      } else if (newAssignedTo == null) {
        changeNote += '\nUnassigned from $originalAssignedUsername';
      } else {
        changeNote +=
            '\nReassigned from $originalAssignedUsername to $newAssignedTo';
      }
    }

    noteController.text = changeNote;
    note = changeNote;
  }

  // Status options
  List<String> statusOptions = [];
  if (newStatus == 'new') {
    statusOptions = ['new', 'in_progress', 'issue_reported', 'completed'];
  } else {
    statusOptions = ['in_progress', 'issue_reported', 'completed'];
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Center(
              child: Text('Edit Task'),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Change Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<String>(
                        value: newStatus ?? 'in_progress',
                        isExpanded: true,
                        underline: Container(),
                        items: statusOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(formatStatus(value)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            newStatus = newValue;
                            newAssignedTo = null;
                            updateNoteText();
                          });
                        },
                      ),
                    ),
                    if (newStatus != null) ...[
                      const SizedBox(height: 16),
                      const Text('Assign To',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          )),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButton<String>(
                          value: newAssignedTo,
                          isExpanded: true,
                          underline: Container(),
                          hint: Text(
                            newStatus == 'new'
                                ? 'Select Ambulance'
                                : 'Select Cleaning Team',
                            style: const TextStyle(fontSize: 14),
                          ),
                          items: (newStatus == 'new'
                                  ? ambulanceUserMap.keys
                                  : cleaningTeamMap.keys)
                              .map((String username) {
                            return DropdownMenuItem<String>(
                              value: username,
                              child: Text(username),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              newAssignedTo = newValue;
                              updateNoteText();
                            });
                          },
                        ),
                      ),
                    ],
                    if (newAssignedTo != null) ...[
                      const SizedBox(height: 16),
                      const Text('Note',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          )),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        decoration: const InputDecoration(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  // Validate all necessary fields
                  bool isValid = true;
                  String? errorMessage;

                  // Validate status
                  if (newStatus == null || newStatus!.isEmpty) {
                    isValid = false;
                    errorMessage = 'Please select task status';
                  }

                  // Validate assigned user
                  if (newAssignedTo == null || newAssignedTo!.isEmpty) {
                    isValid = false;
                    errorMessage = 'Please select assigned user';
                  }

                  // Validate note
                  if (note.isEmpty) {
                    isValid = false;
                    errorMessage = 'Please enter note';
                  }

                  // Validate if there are actual changes
                  bool hasChanges = newStatus != task.status ||
                      newAssignedTo != task.assignedTo?.toString();

                  if (!hasChanges) {
                    isValid = false;
                    errorMessage = 'No changes made';
                  }

                  if (!isValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage ?? 'Please check input'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // If validation passes, execute save
                  if (token != null) {
                    // Convert username back to ID before sending to API
                    String? selectedUserId;
                    if (newAssignedTo != null) {
                      selectedUserId = newStatus == 'new'
                          ? ambulanceUserMap[newAssignedTo]
                          : cleaningTeamMap[newAssignedTo];
                    }

                    context
                        .read<TaskProvider>()
                        .updateTask(
                          taskId: int.parse(taskId),
                          token: token,
                          status: _getStatusString(newStatus ?? 'in_progress'),
                          assignedTo: selectedUserId,
                          note: note,
                        )
                        .then((_) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Update failed: ${error.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

String _getStatusString(String status) {
  return status.toLowerCase();
}
