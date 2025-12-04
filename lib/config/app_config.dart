/// Configuration constants for VerifAI app
/// 
/// IMPORTANT: Update these values with your actual credentials before running the app
class AppConfig {
  // TODO: Replace with your Gemini API key from https://makersuite.google.com/app/apikey
  // Get your key at: https://makersuite.google.com/app/apikey
  static const String geminiApiKey = 'AIzaSyCgeJW_Yo1XN01HaynKI4zgONQ30lck0Z4';
  
  // TODO: Replace with your Firebase App ID from Firebase Console
  static const String firebaseAppId = '1:951237820554:android:d1ac95f2b2ed9e1a872d73';
  
  // App information
  static const String appName = 'VerifAI';
  static const String appVersion = '1.0.0';
  
  // API endpoints
  static const String geminiBaseUrl = 
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash-lite:generateContent';
  
  // Firestore paths
  static String userFactChecksPath(String userId) => 
      'artifacts/$firebaseAppId/users/$userId/factChecks';
  
  // Validation
  static bool get isConfigured {
    return geminiApiKey.isNotEmpty && 
           geminiApiKey != 'YOUR_GEMINI_API_KEY_HERE' &&
           geminiApiKey.length > 20; // API keys are typically longer than 20 chars
  }
  
  static String get configurationStatus {
    if (geminiApiKey.isEmpty || geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      return 'Missing configuration: Gemini API Key';
    }
    
    return 'Configuration complete!';
  }
}
