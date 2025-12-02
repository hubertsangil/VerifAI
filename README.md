# Verity.ai - AI-Powered Fact-Checking App

A minimalistic, modern Flutter mobile application that receives shared links, authenticates users via Firebase, stores history in Firestore, and uses the Gemini API for AI-powered fact-checking.

## Features

- 🔐 **Firebase Authentication** - Secure email/password authentication
- 🔗 **Share Intent Support** - Receive URLs from other apps via Android share sheet
- 🤖 **AI Fact-Checking** - Powered by Google's Gemini API
- 📱 **Material 3 Design** - Modern, minimalistic UI with light/dark theme support
- 📊 **History Tracking** - Store and view past fact-checks with Firestore
- 🌍 **SDG Alignment** - Committed to UN Sustainable Development Goals

## Project Structure

```
lib/
├── main.dart                      # App entry point with Firebase initialization
├── models/
│   └── fact_check_model.dart     # Data models for fact-check results
├── services/
│   ├── gemini_service.dart       # Gemini API integration
│   └── history_service.dart      # Firestore history management
└── screens/
    ├── auth_screen.dart          # Sign in/Sign up screen
    ├── home_screen.dart          # Main app screen with fact-checking
    └── history_screen.dart       # History view with StreamBuilder
```

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (latest stable version)
- Firebase account
- Google Cloud account (for Gemini API)

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Enable the following services:
   - Authentication (Email/Password)
   - Cloud Firestore

#### Android Setup
1. Add an Android app in Firebase Console
2. Download `google-services.json`
3. Place it in `android/app/google-services.json`

#### iOS Setup
1. Add an iOS app in Firebase Console
2. Download `GoogleService-Info.plist`
3. Place it in `ios/Runner/GoogleService-Info.plist`

### 4. API Configuration

#### Gemini API Key
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create an API key
3. Open `lib/services/gemini_service.dart`
4. Replace `YOUR_GEMINI_API_KEY` with your actual API key

#### Firebase App ID
1. Open `lib/services/history_service.dart`
2. Replace `YOUR_APP_ID` with your Firebase app ID

### 5. Firestore Database Setup

Create the following Firestore structure:

```
artifacts/
  └── {appId}/
      └── users/
          └── {userId}/
              └── factChecks/
                  └── {documentId}
                      ├── verdict: string
                      ├── summary: string
                      ├── sources: array
                      ├── timestamp: timestamp
                      └── originalUrl: string
```

**Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /artifacts/{appId}/users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Running the App

```bash
# Run on connected device or emulator
flutter run

# Run in release mode
flutter run --release
```

## Key Dependencies

- `firebase_core` - Firebase initialization
- `firebase_auth` - User authentication
- `cloud_firestore` - Cloud database
- `http` - HTTP requests for Gemini API
- `receive_sharing_intent` - Handle shared content from other apps

## Features Walkthrough

### Authentication
- Users can sign up with email/password
- Automatic sign-in persistence
- Secure logout functionality

### Fact-Checking
1. Enter a URL or share a link from another app
2. Tap "Analyze Link"
3. AI analyzes the content and provides:
   - Verdict (Accurate/Misleading/False)
   - Detailed summary
   - Source citations

### History
- View all past fact-checks
- Sorted by timestamp (most recent first)
- Color-coded verdicts
- Tap to view full details

## UN Sustainable Development Goals

This project aligns with:
- **SDG 16**: Peace, Justice, and Strong Institutions
- **SDG 4**: Quality Education
- **SDG 9**: Industry, Innovation, and Infrastructure

## Design Philosophy

Verity.ai follows a minimalistic, modern design aesthetic using:
- Material 3 design system
- Clean, uncluttered interfaces
- Intuitive navigation
- Accessible color schemes
- Responsive layouts

## License

This project is created for educational purposes.

## Support

For issues or questions, please check the Firebase and Flutter documentation:
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Gemini API Documentation](https://ai.google.dev/docs)
