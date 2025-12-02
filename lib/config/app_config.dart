/// Configuration constants for Verity.ai
/// 
/// IMPORTANT: Update these values with your actual credentials before running the app
class AppConfig {
  // TODO: Replace with your Gemini API key from https://makersuite.google.com/app/apikey
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  
  // TODO: Replace with your Firebase App ID from Firebase Console
  static const String firebaseAppId = 'YOUR_APP_ID';
  
  // App information
  static const String appName = 'Verity.ai';
  static const String appVersion = '1.0.0';
  
  // API endpoints
  static const String geminiBaseUrl = 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  // Firestore paths
  static String userFactChecksPath(String userId) => 
      'artifacts/$firebaseAppId/users/$userId/factChecks';
  
  // Validation
  static bool get isConfigured {
    return geminiApiKey != 'YOUR_GEMINI_API_KEY' && 
           firebaseAppId != 'YOUR_APP_ID';
  }
  
  static String get configurationStatus {
    final List<String> missing = [];
    
    if (geminiApiKey == 'YOUR_GEMINI_API_KEY') {
      missing.add('Gemini API Key');
    }
    if (firebaseAppId == 'YOUR_APP_ID') {
      missing.add('Firebase App ID');
    }
    
    if (missing.isEmpty) {
      return 'Configuration complete!';
    }
    
    return 'Missing configuration: ${missing.join(", ")}';
  }
}
