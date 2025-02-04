class AppConstants {
  // API Status codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusUnauthorized = 401;
  static const int statusNotFound = 404;
  
  // Task statuses
  static const String taskStatusNew = 'new';
  static const String taskStatusInProgress = 'in_progress';
  static const String taskStatusCompleted = 'completed';
  
  // User roles
  static const String roleAdmin = 'admin';
  static const String roleAmbulance = 'ambulance';
  static const String roleCleaningTeam = 'cleaning_team';
} 