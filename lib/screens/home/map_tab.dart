import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:who_location_app/providers/task_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:who_location_app/models/task.dart';
import 'dart:math' as math;
import 'package:who_location_app/providers/auth_provider.dart';
import 'package:who_location_app/utils/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:who_location_app/widgets/add_task_dialog.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  String _statusFilter = 'all'; // Add status filter variable
  Position? _currentPosition; // Add current position state
  AnimationController? _animationController; // Add this line

  // Add this getter to keep the page alive
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When the tab switches to the map, refresh tasks
    context.read<TaskProvider>().loadTasks();
  }

  // Modify zoom level calculation method
  double _getZoomLevel(double delta) {
    // Limit minimum and maximum zoom levels
    const minZoom = 7.0; // Minimum zoom level to maintain provincial range
    const maxZoom = 18.0; // Maximum zoom level remains unchanged

    // Adjust the calculation formula to better display task clusters
    double suggestedZoom =
        15.5 - math.log(delta * 111) / math.ln2; // Increase base value to 15.5

    // Ensure zoom level is within a reasonable range
    return suggestedZoom.clamp(minZoom, maxZoom);
  }

  // Modify relevant parts in the _fitBounds method
  void _fitBounds(List<Task> tasks) {
    if (tasks.isEmpty) {
      // If there are no tasks, do not change the map view
      return;
    }

    // Only collect task coordinates
    final points = tasks
        .map((task) => LatLng(
              task.location['latitude']!,
              task.location['longitude']!,
            ))
        .toList();

    // Calculate boundaries
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    // If there is only one point, use a fixed zoom level
    if (points.length == 1) {
      _animatedMapMove(
        LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
        15.0, // Use a fixed zoom level for a single point
      );
      return;
    }

    // Calculate boundary range
    final latDelta = math.max(
        maxLat - minLat, 0.015); // Minimum range is about 1.5 kilometers
    final lngDelta = math.max(maxLng - minLng, 0.015);

    // Add padding to the boundaries
    minLat -= latDelta * 0.1;
    maxLat += latDelta * 0.1;
    minLng -= lngDelta * 0.1;
    maxLng += lngDelta * 0.1;

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    final latZoom = _getZoomLevel(latDelta);
    final lngZoom = _getZoomLevel(lngDelta);
    final zoom = math.min(latZoom, lngZoom);

    _animatedMapMove(center, zoom);
  }

  // Add method to get location
  Future<void> _getCurrentLocation() async {
    try {
      // Verify if location services are enabled.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('Location services enabled: $serviceEnabled');

      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location services are disabled. Please enable them in settings.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Verify location permissions.
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('Location permission status: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permissions are denied.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      try {
        // Attempt to obtain the current position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );

        if (mounted) {
          // Update state only if the position has changed
          if (_currentPosition == null ||
              _currentPosition!.latitude != position.latitude ||
              _currentPosition!.longitude != position.longitude) {
            setState(() {
              _currentPosition = position;
            });
          }
          // Use the move method to smoothly move the map
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            13.0, // Use the same zoom level here
          );
        }
      } catch (e) {
        debugPrint('Error getting actual position: $e');
        // Use default position if no current position is available
        if (_currentPosition == null && mounted) {
          final defaultPosition = Position(
            latitude: 45.4642, // Latitude of Milan
            longitude: 9.1900, // Longitude of Milan
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );

          setState(() {
            _currentPosition = defaultPosition;
          });
          _mapController.move(
            LatLng(defaultPosition.latitude, defaultPosition.longitude),
            13.0, // Maintain consistent zoom level
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e'); // Retain debug logs
      if (context.mounted) {
        String errorMessage;
        if (e == 'location_timeout') {
          errorMessage = 'Unable to get location. Please try again.';
        } else if (e is TimeoutException) {
          errorMessage =
              'Location request timed out. Please check your GPS signal.';
        } else {
          errorMessage = 'Unable to access location services.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _getCurrentLocation,
            ),
          ),
        );
      }
    }
  }

  // Add animated move method
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.zoom,
      end: destZoom,
    );

    // Ensure to handle the old animation controller first
    _animationController?.dispose();

    _animationController = AnimationController(
      duration: const Duration(
          milliseconds: 700), // Increase duration for smoother transition
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut, // Change curve for a smoother effect
    );

    _animationController!.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController?.dispose();
        _animationController = null;
      } else if (status == AnimationStatus.dismissed) {
        _animationController?.dispose();
        _animationController = null;
      }
    });

    _animationController!.forward();
  }

  // Modify the handling method of the location button
  void _moveToCurrentLocation() {
    _getCurrentLocation().then((_) {
      if (_currentPosition != null) {
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          13.0, // Lower zoom level to display a larger range
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Must call super.build
    super.build(context);

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.tasks;
        debugPrint('Number of tasks: ${tasks.length}'); // Add log
        debugPrint('Current position in build: $_currentPosition'); // Add log

        // Filter tasks
        final filteredTasks = _statusFilter == 'all'
            ? tasks
            : tasks.where((task) => task.status == _statusFilter).toList();

        // Automatically adjust map position when tasks are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitBounds(filteredTasks);
        });

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition != null
                    ? LatLng(
                        _currentPosition!.latitude, _currentPosition!.longitude)
                    : const LatLng(39.9042, 116.4074),
                initialZoom: 13.0,
                onLongPress: (tapPosition, point) {
                  // Check user role
                  final user = context.read<AuthProvider>().user;
                  if (user?.role == AppConstants.roleAmbulance) {
                    debugPrint(
                        'Selected location: ${point.latitude}, ${point.longitude}');
                    _showAddTaskDialog(
                        context, point); // Pass the selected location
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.who_location_app',
                ),
                MarkerLayer(
                  markers: [
                    // Current location marker (placed at the front to ensure at the bottom layer)
                    if (_currentPosition != null)
                      Marker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        width: 60, // Increase width
                        height: 60, // Increase height
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer circle animation effect
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withOpacity(0.1),
                              ),
                            ),
                            // Middle circle
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withOpacity(0.2),
                              ),
                            ),
                            // Inner circle
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            // Center point
                            Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Task markers (placed at the back to ensure at the top layer)
                    ...filteredTasks.map((task) {
                      final location = task.location;
                      return Marker(
                        point: LatLng(
                          location['latitude']!,
                          location['longitude']!,
                        ),
                        width: 120, // Increase width to accommodate more text
                        height: 80,
                        child: GestureDetector(
                          onTap: () => context.go('/tasks/${task.id}'),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(task.status),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  // Use Column to display two lines of text
                                  children: [
                                    Text(
                                      task.title, // Display task title
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _formatStatus(
                                          task.status), // Display status
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _getStatusIcon(task.status),
                                color: _getStatusColor(task.status),
                                size: 30,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
            // Filter
            Positioned(
              top: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All Tasks'),
                      ),
                      DropdownMenuItem(
                        value: 'new',
                        child: Text('Open'),
                      ),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('Ongoing'),
                      ),
                      DropdownMenuItem(
                        value: 'issue_reported',
                        child: Text('Blocked'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Closed'),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value != null) {
                        // Load new data first
                        await context.read<TaskProvider>().loadTasks();

                        // After data is loaded, update the filter state
                        if (mounted) {
                          setState(() {
                            _statusFilter = value;
                          });
                          // Delay one frame to ensure marker list is updated
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final filteredTasks = value == 'all'
                                ? tasks
                                : tasks
                                    .where((task) => task.status == value)
                                    .toList();
                            _fitBounds(filteredTasks);
                          });
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
            // Location button
            Positioned(
              bottom: 16,
              left: 16,
              child: FloatingActionButton(
                heroTag: 'location',
                onPressed: _moveToCurrentLocation, // Use new method
                child: const Icon(Icons.my_location),
                tooltip: 'Get Current Location',
              ),
            ),
            // Add new task button (only displayed for ambulance and admin role)
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final userRole = authProvider.user?.role;
                if (userRole == AppConstants.roleAmbulance ||
                    userRole == AppConstants.roleAdmin) {
                  return Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      heroTag: 'add_task',
                      onPressed: () {
                        // Use current location to create task
                        if (_currentPosition != null) {
                          _showAddTaskDialog(
                            context,
                            LatLng(_currentPosition!.latitude,
                                _currentPosition!.longitude),
                          );
                        } else {
                          // If there is no location information, get the location first
                          _getCurrentLocation().then((_) {
                            if (_currentPosition != null && mounted) {
                              _showAddTaskDialog(
                                context,
                                LatLng(_currentPosition!.latitude,
                                    _currentPosition!.longitude),
                              );
                            }
                          });
                        }
                      },
                      child: const Icon(Icons.add_location_alt),
                      tooltip: 'Add Task at Current Location',
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        );
      },
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Icons.local_hospital; // Ambulance new tasks use hospital icon
      case 'in_progress':
        return Icons.cleaning_services; // Cleaning teams use cleaning icon
      case 'issue_reported':
        return Icons.warning; // Issue reported uses warning icon
      case 'completed':
        return Icons.verified; // Completed uses verified icon
      default:
        return Icons.help; // Default uses question mark icon
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Colors
            .red; // New tasks are represented in red to indicate urgency
      case 'in_progress':
        return Colors
            .amber; // In progress is represented in amber to indicate processing
      case 'issue_reported':
        return Colors
            .deepOrange; // Issues are represented in deep orange to indicate warning
      case 'completed':
        return Colors
            .green; // Completed is represented in green to indicate safety
      default:
        return Colors.grey;
    }
  }

  // Modify the _showAddTaskDialog method
  void _showAddTaskDialog(BuildContext context, LatLng? location) {
    Position? position = location != null
        ? Position(
            latitude: location.latitude,
            longitude: location.longitude,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          )
        : _currentPosition;

    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        initialPosition: position,
      ),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose(); // Add this line
    _mapController.dispose();
    super.dispose();
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return 'Open';
      case 'in_progress':
        return 'Ongoing';
      case 'issue_reported':
        return 'Blocked';
      case 'completed':
        return 'Closed';
      default:
        return status;
    }
  }
}
