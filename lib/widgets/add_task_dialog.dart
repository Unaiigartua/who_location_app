import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/task_provider.dart';
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/utils/constants.dart';
import 'package:who_location_app/services/task_service.dart';

class AddTaskDialog extends StatefulWidget {
  final Position? initialPosition;

  const AddTaskDialog({
    super.key,
    this.initialPosition,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  String? selectedAmbulance;
  List<String> ambulances = [];
  bool useMapSelection = true;

  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    if (_currentPosition != null) {
      latitudeController.text = _currentPosition!.latitude.toString();
      longitudeController.text = _currentPosition!.longitude.toString();
    }
    final userRole = context.read<AuthProvider>().user?.role;
    if (userRole == 'admin') {
      _fetchAmbulances();
    }
  }

  Future<void> _fetchAmbulances() async {
    try {
      final taskService = context.read<TaskService>();
      final authProvider = context.read<AuthProvider>();
      final token = await authProvider.getToken();
      final fetchedAmbulances =
          await taskService.getUserByRole(token!, 'ambulance');
      if (mounted) {
        setState(() {
          ambulances = fetchedAmbulances
              .map((ambulance) => ambulance['id'].toString())
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching ambulances: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load ambulances')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          latitudeController.text = position.latitude.toString();
          longitudeController.text = position.longitude.toString();
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        String errorMessage;
        if (e is TimeoutException) {
          errorMessage =
              'Unable to get location. Please check your GPS signal and try again.';
        } else {
          errorMessage =
              'Unable to access location services. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _getCurrentLocation,
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_currentPosition == null && useMapSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final latitude = useMapSelection
          ? _currentPosition!.latitude
          : double.parse(latitudeController.text);
      final longitude = useMapSelection
          ? _currentPosition!.longitude
          : double.parse(longitudeController.text);

      final success = await context.read<TaskProvider>().createTask(
            title: titleController.text,
            latitude: latitude,
            longitude: longitude,
            description: descriptionController.text.isEmpty
                ? null
                : descriptionController.text,
            assignedTo: selectedAmbulance,
          );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close task creation dialog

      // Show result of task creation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Task created successfully' : 'Failed to create task',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: success
              ? null
              : SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: _handleSubmit,
                ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _handleSubmit,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.read<AuthProvider>().user?.role;
    return AlertDialog(
      title: const Center(
        child: Text(
          'New Request',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentPosition != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Current Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 20,
                                height: 20,
                                alignment: Alignment.center,
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: InkWell(
                                    onTap: _getCurrentLocation,
                                    customBorder: const CircleBorder(),
                                    child: const Icon(
                                      Icons.refresh,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_currentPosition!.latitude.toStringAsFixed(6)}, '
                            '${_currentPosition!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (userRole == AppConstants.roleAdmin) ...[
              DropdownButtonFormField<String>(
                value: selectedAmbulance,
                items: ambulances.map((ambulanceId) {
                  return DropdownMenuItem(
                    value: ambulanceId,
                    child: Text(ambulanceId),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAmbulance = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Assign to Ambulance',
                ),
              ),
            ],
            if (userRole != AppConstants.roleAmbulance) ...[
              CheckboxListTile(
                title: const Text('Use current location'),
                value: useMapSelection,
                onChanged: (value) {
                  setState(() {
                    useMapSelection = value!;
                  });
                },
              ),
              if (!useMapSelection) ...[
                TextField(
                  controller: latitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: longitudeController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _currentPosition != null ? _handleSubmit : null,
          child: const Text('Send'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }
}
