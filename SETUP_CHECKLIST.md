# Verity.ai Setup Checklist

Follow this checklist to get Verity.ai up and running:

## ✅ Initial Setup

- [ ] Flutter SDK installed and configured
- [ ] Run `flutter pub get` to install dependencies
- [ ] Android Studio or VS Code with Flutter extension installed

## ✅ Firebase Configuration

### Firebase Console Setup
- [ ] Create a Firebase project at https://console.firebase.google.com/
- [ ] Enable Authentication → Email/Password provider
- [ ] Create a Cloud Firestore database
- [ ] Set up Firestore security rules (see README.md)

### Android Configuration
- [ ] Register Android app in Firebase Console
- [ ] Download `google-services.json`
- [ ] Place file in `android/app/google-services.json`
- [ ] Verify `android/build.gradle.kts` has Google Services classpath
- [ ] Verify `android/app/build.gradle.kts` applies Google Services plugin

### iOS Configuration (Optional)
- [ ] Register iOS app in Firebase Console
- [ ] Download `GoogleService-Info.plist`
- [ ] Place file in `ios/Runner/GoogleService-Info.plist`

## ✅ API Configuration

### Gemini API
- [ ] Create Gemini API key at https://makersuite.google.com/app/apikey
- [ ] Open `lib/config/app_config.dart`
- [ ] Replace `YOUR_GEMINI_API_KEY` with your actual API key

### Firebase App ID
- [ ] Get your Firebase App ID from Firebase Console
- [ ] Open `lib/config/app_config.dart`
- [ ] Replace `YOUR_APP_ID` with your actual Firebase app ID

## ✅ Firestore Database Structure

Set up the following Firestore structure:
```
artifacts/
  └── {YOUR_APP_ID}/
      └── users/
          └── {userId}/
              └── factChecks/ (collection)
```

Apply these security rules in Firestore:
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

## ✅ Testing

- [ ] Connect Android device or start emulator
- [ ] Run `flutter run` to test the app
- [ ] Test sign up with email/password
- [ ] Test fact-checking with a sample URL
- [ ] Test sharing a URL from another app
- [ ] Verify history is saved and displayed

## ✅ Common Issues

### Firebase not initializing
- Verify `google-services.json` is in correct location
- Check that package name matches in Firebase Console
- Clean and rebuild: `flutter clean && flutter pub get`

### API calls failing
- Verify internet permission in AndroidManifest.xml
- Check Gemini API key is correct
- Ensure device has internet connection

### Firestore permission denied
- Verify security rules are set up correctly
- Check that user is authenticated
- Confirm Firebase App ID is correct

## 📱 Ready to Launch!

Once all items are checked:
```bash
# Run in debug mode
flutter run

# Build release APK
flutter build apk --release

# Build release app bundle
flutter build appbundle --release
```

## 📚 Additional Resources

- [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [Flutter Documentation](https://docs.flutter.dev/)
