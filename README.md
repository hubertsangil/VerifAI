# VerifAI - AI-Powered Fact-Checking App

A modern Flutter mobile application that works as an **AI layer for social media apps** like Facebook, TikTok, Twitter, and Instagram. VerifAI helps users verify the accuracy of online content through AI-powered fact-checking by receiving shared links from any app, extracting metadata from web pages, and using Google's Gemini API to analyze and fact-check the content.

## Key Concept: AI Layer for Social Media

VerifAI acts as an intelligent intermediary between you and social media platforms:

1. **See a suspicious post** on Facebook, TikTok, Twitter, Instagram, or any app
2. **Tap the share button** on that post/reel/article
3. **Select VerifAI** from the share menu
4. **Get instant AI analysis** - accurate, misleading, or false
5. **View detailed sources** and make informed decisions

No need to copy-paste URLs manually - VerifAI integrates seamlessly with Android's share functionality!

## Features

- 📲 **Share Intent Integration** - Receive content from any app via Android share sheet
- 🤖 **AI Fact-Checking** - Powered by Google's Gemini 2.0 Flash Lite model
- 🌐 **Smart Metadata Extraction** - Extracts Open Graph metadata (title, description, content) from web pages
- ⚡ **Instant Analysis** - Auto-analyzes shared content with confirmation dialog
- 🔐 **Firebase Authentication** - Secure email/password authentication with user profiles
- 📊 **History Tracking** - Store and view past fact-checks with Firestore
- 📱 **Material 3 Design** - Modern UI with animated blue gradient background
- 🌍 **SDG Alignment** - Committed to UN Sustainable Development Goals (4, 9, 16)
- 🔗 **Multi-Platform Support** - Works with Facebook, TikTok, Twitter, Instagram, news sites, and more

## How to Use VerifAI as an AI Layer

### Method 1: Share from Any App (Recommended)

1. **Open any social media app** (Facebook, TikTok, Twitter, Instagram, etc.)
2. **Find a post, reel, or article** you want to verify
3. **Tap the share button** (usually represented by an arrow icon)
4. **Select "VerifAI"** from the share options
5. **Confirm the analysis** - VerifAI will show what it's about to check
6. **View results** - Get an instant verdict with detailed analysis and sources

### Method 2: Manual URL Entry

1. **Copy the URL** of the content you want to verify
2. **Open VerifAI**
3. **Paste the URL** in the input field
4. **Tap "Analyze"**
5. **View results**

### Supported Platforms

- ✅ Facebook posts and articles
- ✅ TikTok videos (via share URL)
- ✅ Twitter/X posts
- ✅ Instagram posts (public content)
- ✅ News websites and blogs
- ✅ YouTube videos
- ✅ Any website with Open Graph metadata

## How Fact-Checking Works

1. **URL Input**: User enters a URL or shares a link from another app
2. **Metadata Extraction**: The app fetches the web page and extracts:
   - Open Graph tags (og:title, og:description, og:image)
   - Twitter Card metadata
   - Page title and meta descriptions
   - Content preview from the first few paragraphs
3. **AI Analysis**: Extracted metadata is sent to Gemini API with a detailed prompt asking for:
   - Verdict classification (ACCURATE/MISLEADING/FALSE)
   - Detailed analysis summary
   - Credible source citations
4. **Results Display**: The app shows color-coded results with verdict, summary, and sources
5. **History Storage**: All fact-checks are stored in Firestore for future reference

This approach allows VerifAI to analyze content from authentication-gated platforms (like Facebook, Twitter) by accessing publicly available metadata without requiring login credentials.

## Project Structure

```
lib/
├── main.dart                      # App entry point with Firebase initialization
├── config/
│   └── app_config.dart           # API keys and configuration
├── models/
│   └── fact_check_model.dart     # Data models for fact-check results
├── services/
│   ├── gemini_service.dart       # Gemini API integration
│   ├── metadata_service.dart     # Web page metadata extraction
│   ├── history_service.dart      # Firestore history management
│   └── cloud_function_service.dart # Firebase Functions (optional)
├── screens/
│   ├── auth_screen.dart          # Sign in/Sign up with animated splash
│   ├── home_screen.dart          # Main app screen with fact-checking
│   └── history_screen.dart       # History view with StreamBuilder
└── widgets/
    └── (custom widgets)
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

Create and configure `lib/config/app_config.dart`:

```dart
class AppConfig {
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
  static const String firebaseAppId = 'YOUR_FIREBASE_APP_ID_HERE';
  static const String geminiBaseUrl = 
    'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash-lite:generateContent';
  
  static bool get isConfigured => 
    geminiApiKey.isNotEmpty && 
    geminiApiKey != 'YOUR_GEMINI_API_KEY_HERE' &&
    geminiApiKey.length > 20;
}
```

#### Gemini API Key
1. Go to [Google AI Studio](https://aistudio.google.com/apikey)
2. Create an API key
3. Replace `YOUR_GEMINI_API_KEY_HERE` in `app_config.dart`
4. Current model: `gemini-2.0-flash-lite` (free tier, optimized for speed and low token usage)

#### Firebase App ID (Optional)
1. Find your app ID in Firebase Console → Project Settings
2. Replace `YOUR_FIREBASE_APP_ID_HERE` in `app_config.dart`

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

- `firebase_core: ^3.15.2` - Firebase initialization
- `firebase_auth: ^5.3.4` - User authentication
- `cloud_firestore: ^5.5.2` - Cloud database
- `http: ^1.2.2` - HTTP requests for API calls
- `html: ^0.15.4` - HTML parsing for metadata extraction
- `receive_sharing_intent: ^1.8.0` - Handle shared content from other apps

## Technical Details

### Gemini API Integration
- **Model**: `gemini-2.0-flash-lite` (Google's latest fast, lightweight model)
- **API Version**: v1 stable
- **Temperature**: 0.4 (balanced between creativity and accuracy)
- **Max Output Tokens**: 2048
- **Features**: Content generation with safety filters

### Metadata Extraction
The app uses Open Graph protocol and meta tags to extract:
- Page title and description
- Site name and author
- Featured images
- Content previews (first 3 paragraphs)
- Handles Facebook, Twitter, and standard web pages

### Authentication
- Email/password authentication with Firebase Auth
- User profile storage in Firestore
- Automatic session persistence
- Custom error messages for better UX

### UI/UX
- Material 3 design system
- Animated gradient background (5-color blue gradient, 3-second loop)
- Smooth transitions and loading states
- Color-coded verdicts (green/yellow/red)
- SDG badges with official colors

## Features Walkthrough

### Authentication
- Sign up with full name, email, password, and age
- Sign in with email/password
- Custom error messages (e.g., "This user does not exist" for invalid credentials)
- Animated splash screen during login/registration
- Automatic sign-in persistence
- Secure logout functionality

### Share Integration (AI Layer Feature)
- **Seamless sharing** from any app with share functionality
- **Auto-populate** URL field when content is shared
- **Confirmation dialog** shows what will be analyzed
- **Smart detection** works with both text URLs and media files
- **Background listening** catches shares even when app is running
- **Intent filters** for multiple MIME types (text/plain, text/x-uri, http/https schemes)
- **Works with:**
  - Social media: Facebook, TikTok, Twitter, Instagram, LinkedIn
  - Messaging apps: WhatsApp, Telegram, Messenger
  - Browsers: Chrome, Firefox, Edge, Brave
  - News apps: Google News, Reddit, Medium
  - Any app with a share button!

### Fact-Checking
1. **Input URL**: Enter a URL manually or share from any app (browser, social media, etc.)
2. **Metadata Extraction**: App fetches web page and extracts Open Graph metadata
3. **AI Analysis**: Gemini analyzes the metadata for accuracy and credibility
4. **Results**: Display includes:
   - Color-coded verdict badge (ACCURATE/MISLEADING/FALSE)
   - Detailed analysis summary
   - Source citations with links
5. **Save to History**: Automatically stored in Firestore for future reference

### History
- View all past fact-checks in chronological order
- Color-coded verdict badges
- Quick summary preview
- Tap to view full analysis details
- Real-time updates with StreamBuilder
- Persistent storage across devices

### Share Integration
- Receive URLs from any app via Android share sheet
- Direct link analysis from clipboard
- Supports multiple URL formats
- Works with social media platforms (Facebook, Twitter, etc.) via metadata

## UN Sustainable Development Goals

VerifAI aligns with three key UN SDGs:

- **SDG 4: Quality Education** 🎓
  - Promotes media literacy and critical thinking
  - Empowers users to identify misinformation
  - Educational tool for digital citizenship

- **SDG 9: Industry, Innovation, and Infrastructure** 🔧
  - Leverages cutting-edge AI technology (Gemini 2.0)
  - Innovative metadata extraction approach
  - Scalable mobile-first architecture

- **SDG 16: Peace, Justice, and Strong Institutions** ⚖️
  - Combats misinformation and disinformation
  - Promotes transparent information verification
  - Supports informed decision-making

## Design Philosophy

VerifAI follows a modern, user-friendly design aesthetic:
- **Visual Design**: Animated blue gradient background with smooth transitions
- **Material 3**: Latest Material Design guidelines for consistency
- **Accessibility**: Clear typography, high contrast, intuitive navigation
- **Minimalism**: Clean interfaces without clutter
- **Responsive**: Optimized for various screen sizes
- **Color Coding**: Intuitive visual feedback (green = accurate, yellow = misleading, red = false)

## Known Limitations

- **Content Access**: Cannot access full content from authentication-required platforms (Facebook private posts, paywalled articles). Uses publicly available metadata instead.
- **Language**: Currently optimized for English content
- **Rate Limits**: Subject to Gemini API free tier limits
- **Platform**: Android support only (iOS requires additional configuration)

## Future Enhancements

- Image and video fact-checking
- Multi-language support
- Browser extension integration
- Bulk URL analysis
- Community reporting features
- Advanced filtering and search in history

## License

This project is created for educational purposes as part of a mobile computing course.

## Contributors

- Hubert San Gil (@hubertsangil)
- Janison Bustos (@jgianee)

## Support

For issues or questions, please refer to the official documentation:
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Gemini API Documentation](https://ai.google.dev/gemini-api/docs)
- [Open Graph Protocol](https://ogp.me/)

---

**VerifAI** - Empowering truth in the digital age 🔍✨
