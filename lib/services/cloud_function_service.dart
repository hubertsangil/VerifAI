import 'package:cloud_functions/cloud_functions.dart';
import '../models/fact_check_model.dart';

/// Service for calling Firebase Cloud Functions to fact-check URLs
/// This keeps the Gemini API key secure on the server
class CloudFunctionService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Analyzes a URL by calling the Firebase Cloud Function
  Future<FactCheckResult> analyzeUrl(String url) async {
    try {
      // Call the cloud function
      final callable = _functions.httpsCallable('factCheckUrl');
      final result = await callable.call({'url': url});
      
      // Parse the response
      final data = result.data as Map<String, dynamic>;
      
      return FactCheckResult(
        verdict: FactCheckVerdict.fromString(data['verdict'] as String),
        summary: data['summary'] as String,
        sources: (data['sources'] as List<dynamic>?)
                ?.map((s) => Source.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        timestamp: DateTime.parse(data['timestamp'] as String),
        originalUrl: data['originalUrl'] as String,
      );
    } catch (e) {
      // Return an error result
      return FactCheckResult(
        verdict: FactCheckVerdict.unknown,
        summary: 'Error analyzing URL: ${e.toString()}',
        sources: [],
        timestamp: DateTime.now(),
        originalUrl: url,
      );
    }
  }
}
