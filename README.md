# FishCAP - Precision Aquaculture Management

A Flutter mobile application for aquaculture management with bilingual support (English/Khmer).

## Features

- **Authentication**: Login and registration screens
- **Home Dashboard**: Water quality monitoring, schedule overview, and recent activities
- **Schedule Management**: View and manage daily aquaculture tasks
- **History Tracking**: Track past activities and operations
- **Notifications**: Real-time alerts and reminders
- **Profile Management**: User profile and settings
- **Bilingual Support**: English and Khmer languages
- **Backend Integration**: Connected to FishCap backend API

## Screens

1. **Login Screen** - User authentication
2. **Register Screen** - New user registration
3. **Home Screen** - Dashboard with water quality metrics and schedule
4. **Schedule Screen** - Daily task management
5. **History Screen** - Activity history and logs
6. **Notifications Screen** - Alerts and notifications
7. **Profile Screen** - User profile and settings
8. **Settings Screen** - App configuration

## Getting Started

### Prerequisites

- Flutter SDK (3.12.1 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Backend server running at `http://10.0.2.2:3000/api` (for emulator)
- For physical device, update the IP address in `lib/services/api_service.dart`

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

5. Or build APK:
   ```bash
   flutter build apk --debug
   ```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── app/
│   └── theme.dart              # App theme and colors
├── l10n/
│   ├── app_en.arb              # English translations
│   ├── app_km.arb              # Khmer translations
│   └── app_localizations.dart  # Generated localization code
├── models/
│   └── user.dart               # User model
├── services/
│   └── api_service.dart        # Backend API integration
└── screens/
    ├── auth/
    │   ├── login_screen.dart   # Login page
    │   └── register_screen.dart # Registration page
    ├── home/
    │   └── home_screen.dart    # Home dashboard
    ├── schedule/
    │   └── schedule_screen.dart # Schedule page
    ├── history/
    │   └── history_screen.dart  # History page
    ├── notifications/
    │   └── notifications_screen.dart # Notifications page
    ├── profile/
    │   └── profile_screen.dart  # Profile page
    └── settings/
        └── settings_screen.dart # Settings page
```

## Backend API

The app connects to the FishCap backend API. Update the base URL in `lib/services/api_service.dart`:

- For Android emulator: `http://10.0.2.2:3000/api`
- For physical device: `http://YOUR_COMPUTER_IP:3000/api`

## Technologies Used

- Flutter 3.x
- Dart
- Provider (State Management)
- HTTP (API calls)
- Shared Preferences (Local storage)
- Flutter Localizations (i18n)

## Design

The app follows the FishCAP design system with:
- Primary color: Teal (#0D7377)
- Modern card-based UI
- Material Design 3
- Responsive layout

## License

This project is part of the FishCap internship program.