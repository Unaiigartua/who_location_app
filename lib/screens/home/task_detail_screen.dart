import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/task_provider.dart';
import 'package:who_location_app/models/task.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/utils/helpers.dart';
import 'package:who_location_app/widgets/task_details_widget.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTaskDetails();
    });
  }

  Future<void> _loadTaskDetails() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.loadTaskDetails(widget.taskId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task #${widget.taskId}'),
        centerTitle: true,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoadingDetails) {
            return const Center(child: CircularProgressIndicator());
          }
          // Load task details for the task detail screen in _currentTask
          final task = taskProvider.currentTask;
          if (task == null) {
            return const Center(child: Text('Task not found'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TaskInfoWidget(task: task),
                    const SizedBox(height: 24),
                    const Text(
                      'Task History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: TaskLogsWidget(
                  task: task,
                  onRefresh: () async {
                    await context
                        .read<TaskProvider>()
                        .loadTaskDetails(widget.taskId);
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButton(task),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton(Task task) {
    final userRole = context.read<AuthProvider>().user?.role;
    final userId = context.read<AuthProvider>().user?.id;

    if (task.status == 'completed') {
      return Container(); // No mostrar botón
    }

    if (task.status == 'new') {
      if (userRole == 'ambulance') {
        return task.assignedTo == userId ? _buildAddNoteButton() : Container();
      } else if (userRole == 'cleaning_team') {
        return _buildHandleButton(task); // Permitir manejar la tarea
      }
    }

    if (task.status == 'in_progress') {
      if (userRole == 'cleaning_team') {
        return task.assignedTo == userId
            ? _buildChangeStatusButton()
            : Container();
      }
    }

    if (task.status == 'issue_reported') {
      if (userRole == 'cleaning_team') {
        return task.assignedTo == userId
            ? _buildChangeStatusButton()
            : Container();
      }
    }

    if (userRole == 'admin') {
      return _buildEditTaskButton(task);
    }

    return Container(); // Default, no mostrar botón
  }

  Widget _buildAddNoteButton() {
    return ElevatedButton(
      onPressed: _showAddNoteDialog,
      child: const Text('Add Note'),
    );
  }

  Widget _buildChangeStatusButton() {
    return ElevatedButton(
      onPressed: () =>
          _showChangeStatusDialog(context.read<TaskProvider>().currentTask!),
      child: const Text('Change Status'),
    );
  }

  Widget _buildHandleButton(Task task) {
    return ElevatedButton(
      onPressed: () => _showHandleDialog(task),
      child: const Text('Handle'),
    );
  }

  Widget _buildEditTaskButton(Task task) {
    return ElevatedButton(
      onPressed: () => _showEditTaskDialog(task),
      child: const Text('Edit Task'),
    );
  }

  String _getStatusString(String status) {
    if (status == 'Issue Reported') {
      return 'issue_reported';
    } else if (status == 'Closed') {
      return 'completed';
    } else if (status == 'In Progress') {
      return 'in_progress';
    } else if (status == 'New') {
      return 'new';
    }
    return status;
  }

  String _getStringStatus(String status) {
    if (status == 'new') {
      return 'New';
    } else if (status == 'in_progress') {
      return 'In Progress';
    } else if (status == 'completed') {
      return 'Completed';
    } else if (status == 'issue_reported') {
      return 'Issue Reported';
    }
    return status;
  }

  void _showAddNoteDialog() {
    String note = '';
    final token = context.read<AuthProvider>().user?.token;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Note'),
          content: TextField(
            decoration: const InputDecoration(hintText: 'Enter your note here'),
            onChanged: (value) {
              note = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (token != null) {
                  await context.read<TaskProvider>().updateTask(
                        taskId: int.parse(widget.taskId),
                        token: token,
                        note: note,
                      );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showChangeStatusDialog(Task task) {
    String? newStatus;
    String note = '';
    final token = context.read<AuthProvider>().user?.token;

    List<String> statusOptions;
    if (task.status == 'in_progress') {
      statusOptions = ['In Progress', 'Closed', 'Issue Reported'];
    } else if (task.status == 'issue_reported') {
      statusOptions = ['Issue Reported', 'In Progress'];
    } else {
      statusOptions = ['Closed', 'Issue Reported'];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButton<String>(
                    hint: Text('Select Status'),
                    value: newStatus,
                    items: statusOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        newStatus = newValue;
                      });
                    },
                  ),
                  TextField(
                    decoration:
                        const InputDecoration(hintText: 'Enter your note here'),
                    onChanged: (value) {
                      note = value;
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Change'),
                  onPressed: () async {
                    if (newStatus != null && token != null) {
                      await context.read<TaskProvider>().updateTask(
                            taskId: int.parse(widget.taskId),
                            token: token,
                            status:
                                _getStatusString(newStatus ?? 'in_progress'),
                            note: note,
                          );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select a status.')),
                      );
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

  void _showHandleDialog(Task task) {
    String note = '';
    final token = context.read<AuthProvider>().user?.token;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Handle Task'),
          content: TextField(
            decoration: const InputDecoration(hintText: 'Enter your note here'),
            onChanged: (value) {
              note = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Handle'),
              onPressed: () async {
                if (token != null) {
                  if (task.status == 'issue_reported') {
                    await context.read<TaskProvider>().updateTask(
                          taskId: int.parse(widget.taskId),
                          token: token,
                          note: note,
                          status: 'issue_reported',
                        );
                  } else {
                    await context.read<TaskProvider>().updateTask(
                          taskId: int.parse(widget.taskId),
                          token: token,
                          note: note,
                          status: 'in_progress',
                        );
                  }
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(Task task) async {
    String? newStatus = task.status;
    String? newAssignedTo = task.assignedTo?.toString();
    String note = '';
    final token = context.read<AuthProvider>().user?.token;

    // Obtener usuarios por rol
    List<Map<String, dynamic>> ambulanceUsers = [];
    List<Map<String, dynamic>> cleaningTeamUsers = [];
    if (token != null) {
      ambulanceUsers =
          await context.read<TaskProvider>().getUserByRole(token, 'ambulance');
      cleaningTeamUsers = await context
          .read<TaskProvider>()
          .getUserByRole(token, 'cleaning_team');
    }
    // Convertir a listas de IDs de usuario (string)
    List<String> ambulanceUserIds =
        ambulanceUsers.map((user) => user['id'].toString()).toList();
    List<String> cleaningTeamUserIds =
        cleaningTeamUsers.map((user) => user['id'].toString()).toList();

    // Obtener todos los usuarios para el desplegable
    List<String> userOptions = [...ambulanceUserIds, ...cleaningTeamUserIds];

    // Asegurarse de que newStatus esté en las opciones
    List<String> statusOptions = [
      'New',
      'In Progress',
      'Completed',
      'Issue Reported'
    ];
    if (!statusOptions.contains(newStatus)) {
      statusOptions.add(newStatus);
    }

    // Asegurarse de que newAssignedTo esté en las opciones
    if (newAssignedTo != null &&
        !ambulanceUserIds.contains(newAssignedTo) &&
        !cleaningTeamUserIds.contains(newAssignedTo)) {
      userOptions.add(newAssignedTo);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Change Status',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _getStringStatus(newStatus ?? 'in_progress'),
                    items: statusOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        newStatus = newValue;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Text('Assign To',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: newAssignedTo,
                    items: userOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        newAssignedTo = newValue;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  TextField(
                    decoration:
                        InputDecoration(hintText: 'Enter your note here'),
                    onChanged: (value) {
                      note = value;
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Save'),
                  onPressed: () async {
                    if (token != null) {
                      // Comprobar el rol del usuario asignado
                      if (newStatus?.toLowerCase() == 'new' &&
                          !ambulanceUserIds.contains(newAssignedTo)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Assigned user must be an Ambulancer for New tasks.')),
                        );
                        return;
                      } else if (newStatus?.toLowerCase() != 'new' &&
                          !cleaningTeamUserIds.contains(newAssignedTo)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Assigned user must be a Cleaner for non-New tasks.')),
                        );
                        return;
                      }
                      await context.read<TaskProvider>().updateTask(
                            taskId: int.parse(widget.taskId),
                            token: token,
                            status:
                                _getStatusString(newStatus ?? 'in_progress'),
                            assignedTo: newAssignedTo,
                            note: note,
                          );
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
