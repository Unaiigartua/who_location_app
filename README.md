# WHO Location Client

[![GitHub Repository](https://img.shields.io/badge/GitHub-Repository-blue.svg)](https://github.com/Unaiigartua/who_location_app)

## Description

"WHO Location Client" is a Flutter application designed for real-time management of reports, tasks, and users. The app connects to a server via WebSocket to receive live updates and offers full functionalities such as creating, editing, and deleting tasks; generating and downloading reports; and managing users with different roles. Additionally, it integrates geolocation to assign tasks based on location and synchronize data with the server.

## Features

- Real-time connection via WebSocket to receive notifications about task updates and other events.
- Complete user management: registration, login, and role management (e.g., administrator, ambulance).
- Task management with geolocation support: creation, editing, deletion, and detailed tracking.
- Generation, synchronization, and downloading of reports with local file management.
- Integration of Providers for state management along with services that facilitate communication with external APIs.

## App Screens

The application includes several screens and dialogs that provide a comprehensive user experience:

- **Home Screen**: The main screen displaying a summary of active tasks, user information, and quick access to other functionalities.
- **Login Screen**: Allows users to enter their credentials and log into their accounts.
- **Register Screen**: Enables new users to register on the platform.
- **Admin Register Screen**: A specialized screen for registering administrators, facilitating permission and role management.
- **User Management Screen**: An interface for managing users where existing users can be listed, edited, or deleted.
- **Task Detail Screen**: Displays detailed information about a specific task, including its status, location, and description.
- **Task History Screen**: Provides a history of tasks, allowing filtering and search of past tasks based on various criteria.
- **Tasks Tab**: A tab that groups tasks by status or other criteria, making access and tracking easier.
- **Map Tab**: A map view used for selecting and visualizing real-time locations, essential for task assignment based on geolocation.
- **Profile Tab**: Displays the user's profile information, allowing editing of personal details and settings.
- **Add Task Dialog**: A pop-up dialog that enables the creation of new tasks, where details such as title, description, location, and ambulance assignment can be entered.

## App Logic

The application follows a modern architecture based on Providers and services, ensuring efficient data flow and a clear separation of responsibilities:

- **Authentication and User Management**: Utilizes `AuthProvider` for handling authentication, token storage, and session management. It also includes logic to manage unauthorized users.
- **Task Management**: Task creation, editing, and deletion are managed through `TaskProvider` and `TaskService`, which communicate with the backend using REST APIs and WebSocket for real-time updates.
- **Reports and Synchronization**: Reports are generated via `ReportApi`, and the app synchronizes local files with the server's list, deleting those that no longer exist on the server.
- **Real-time Notifications**: `WebSocketService` establishes a connection with the server to receive instant updates on task status, enhancing the app's responsiveness.
- **State Management and Navigation**: The app uses `Provider` for global state management and `goRouter` for navigation between screens, ensuring a smooth user experience.

## Project Structure

The project is organized as follows:

- **lib/**: Contains all of the source code.
  - **api/**: Interactions with the server's APIs (e.g., `report_api.dart`, `task_api.dart`).
  - **config/**: General configurations and routes (e.g., `app_config.dart`, `routes.dart`).
  - **providers/**: State management and business logic (e.g., `auth_provider.dart`, `task_provider.dart`).
  - **screens/**: Definitions of the application's screens (e.g., `home_screen.dart`, `report_screen.dart`, etc.).
  - **services/**: Classes that encapsulate communication with external services (e.g., `websocket_service.dart`, `task_service.dart`, `navigation_service.dart`).
  - **widgets/**: Reusable UI components (e.g., `custom_button.dart`).
  - **dialogs/**: Dialog components (e.g., `add_task_dialog.dart`, `edit_task_dialog.dart`).

## Installation and Execution

1. Clone the repository:
   ```sh
   git clone <REPOSITORY_URL>
   cd who_location_app
   ```

2. Install dependencies:
   ```sh
   flutter pub get
   ```

3. Run the application:
   ```sh
   flutter run
   ```
