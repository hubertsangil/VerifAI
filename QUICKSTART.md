# 🚀 Verity.ai - Quick Start Guide

## Get Started in 5 Minutes!

### Prerequisites
- ✅ Flutter installed
- ✅ Firebase account
- ✅ Google Cloud account (for Gemini API)

### Step 1: Firebase Setup (2 minutes)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "Verity AI"
3. **Enable Authentication**:
   - Click "Authentication" → "Get Started"
   - Enable "Email/Password" provider
4. **Create Firestore Database**:
   - Click "Firestore Database" → "Create database"
   - Start in test mode (we'll add security rules later)
5. **Register Android App**:
   - Click "Add app" → Android icon
   - Package name: `com.example.verity_ai`
   - Download `google-services.json`
   - Place it in `android/app/google-services.json`

### Step 2: API Keys (1 minute)

1. **Get Gemini API Key**:
   - Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Click "Create API Key"
   - Copy the key

2. **Configure App**:
   - Open `lib/config/app_config.dart`
   - Replace `YOUR_GEMINI_API_KEY` with your actual Gemini API key
   - Replace `YOUR_APP_ID` with your Firebase project ID (found in Firebase Console → Project Settings)

### Step 3: Firestore Security Rules (1 minute)

In Firebase Console → Firestore Database → Rules, paste this:

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

Click "Publish"

### Step 4: Run the App (1 minute)

```bash
# Make sure you're in the project directory
cd d:\Downloads\mobcom\verity_ai

# Get dependencies (already done, but just in case)
flutter pub get

# Connect your Android device or start emulator

# Run the app
flutter run
```

## 🎉 That's It!

You should now see the Verity.ai login screen!

### First Time Use

1. **Sign Up**:
   - Enter your email
   - Create a password (min 6 characters)
   - Click "Sign Up"

2. **Test Fact-Checking**:
   - Enter a news article URL
   - Click "Analyze Link"
   - Wait for AI analysis (10-30 seconds)
   - View results with verdict and sources

3. **Test Share Feature**:
   - Open a web browser on your device
   - Share a URL
   - Select Verity.ai
   - URL auto-populates in the app

## 🐛 Quick Troubleshooting

### "Firebase not initialized"
- Check that `google-services.json` is in `android/app/`
- Package name in Firebase Console matches `com.example.verity_ai`

### "API key invalid"
- Verify your Gemini API key in `lib/config/app_config.dart`
- Make sure there are no extra spaces or quotes

### "Permission denied" on Firestore
- Check that security rules are published
- Verify user is logged in

### Can't connect to internet
- Check that INTERNET permission is in `AndroidManifest.xml`
- Verify device has internet connection

## 📱 Test Checklist

- [ ] Sign up with email/password ✓
- [ ] Sign in works ✓
- [ ] Can enter URL ✓
- [ ] Analysis returns results ✓
- [ ] Results show verdict (colored) ✓
- [ ] Sources are displayed ✓
- [ ] History saves automatically ✓
- [ ] Can view past analyses ✓
- [ ] Share from browser works ✓
- [ ] Logout works ✓

## 💡 Pro Tips

1. **Better Results**: Use full article URLs, not just domain names
2. **Faster Analysis**: Gemini API typically responds in 10-20 seconds
3. **History**: All your fact-checks are saved automatically
4. **Dark Mode**: Enable dark mode in device settings - app adapts automatically
5. **Share**: Long-press any URL in any app → Share → Verity.ai

## 🎯 Next Steps

Once everything works:

1. **Customize Branding**:
   - Update app icon in `android/app/src/main/res/mipmap-*/`
   - Change app name in `android/app/src/main/AndroidManifest.xml`

2. **Production Build**:
   ```bash
   flutter build apk --release
   ```

3. **Add iOS Support**:
   - Download `GoogleService-Info.plist` from Firebase
   - Place in `ios/Runner/`
   - Run on iOS device

## 📚 Learn More

- Read `README.md` for detailed documentation
- Check `ARCHITECTURE.md` for system design
- Follow `SETUP_CHECKLIST.md` for comprehensive setup

---

**Need Help?** Check the documentation files or Firebase/Flutter docs!

**Happy Fact-Checking! 🎉**
