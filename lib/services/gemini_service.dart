import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/fact_check_model.dart';
import '../config/app_config.dart';
import 'metadata_service.dart';

class GeminiService {
  static const String _apiKey = AppConfig.geminiApiKey;
  static const String _baseUrl = AppConfig.geminiBaseUrl;
  final _metadataService = MetadataService();

  /// Analyzes a URL for fact-checking using metadata and Gemini API
  Future<FactCheckResult> analyzeUrl(String url) async {
    try {
      // Extract metadata from URL
      debugPrint('Fetching metadata for: $url');
      final metadata = await _metadataService.extractMetadata(url);
      
      String contentToAnalyze;
      if (metadata != null) {
        contentToAnalyze = metadata.toAnalysisText();
        debugPrint('Metadata extracted successfully');
      } else {
        contentToAnalyze = 'URL: $url\n(Unable to extract metadata - URL may require authentication or be inaccessible)';
        debugPrint('Could not extract metadata, using URL only');
      }
      
      // Construct the request
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': '''You are a professional fact-checker. Analyze the following content for accuracy and credibility.

$contentToAnalyze

Please provide your analysis in the following JSON format:
{
  "verdict": "ACCURATE/MISLEADING/FALSE",
  "summary": "A detailed summary of your fact-check analysis",
  "sources": [
    {
      "title": "Source Title",
      "uri": "https://source-url.com"
    }
  ]
}

IMPORTANT: 
1. Your response MUST start with "VERDICT: " followed by exactly one of: ACCURATE, MISLEADING, or FALSE
2. Analyze the claims made in the title, description, and content
3. Cross-reference with known facts and credible sources
4. Provide a clear summary explaining your verdict
5. Include at least 2-3 credible sources to support your analysis
4. Be objective and thorough in your analysis'''
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 1,
          'maxOutputTokens': 2048,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
        ]
      };

      // Make the API request
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract the generated text
        final generatedText = data['candidates'][0]['content']['parts'][0]['text'] as String;
        
        return _parseGeminiResponse(generatedText, url);
      } else {
        throw Exception('Failed to analyze URL: ${response.statusCode} - ${response.body}');
      }
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

  /// Parses the Gemini API response and extracts fact-check information
  FactCheckResult _parseGeminiResponse(String responseText, String originalUrl) {
    try {
      // Extract verdict from the response
      FactCheckVerdict verdict = FactCheckVerdict.unknown;
      if (responseText.toUpperCase().contains('VERDICT: ACCURATE')) {
        verdict = FactCheckVerdict.accurate;
      } else if (responseText.toUpperCase().contains('VERDICT: MISLEADING')) {
        verdict = FactCheckVerdict.misleading;
      } else if (responseText.toUpperCase().contains('VERDICT: FALSE')) {
        verdict = FactCheckVerdict.false_;
      }

      // Try to parse JSON if present
      String summary = '';
      List<Source> sources = [];

      // Look for JSON structure in the response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch != null) {
        try {
          final jsonData = jsonDecode(jsonMatch.group(0)!);
          
          // Override verdict if present in JSON
          if (jsonData['verdict'] != null) {
            verdict = FactCheckVerdict.fromString(jsonData['verdict']);
          }
          
          summary = jsonData['summary'] ?? responseText;
          
          if (jsonData['sources'] is List) {
            sources = (jsonData['sources'] as List)
                .map((s) => Source.fromJson(s as Map<String, dynamic>))
                .toList();
          }
        } catch (e) {
          // If JSON parsing fails, use the full response as summary
          summary = responseText;
        }
      } else {
        // No JSON found, use full response as summary
        summary = responseText;
      }

      // Extract sources from text if not found in JSON
      if (sources.isEmpty) {
        sources = _extractSourcesFromText(responseText);
      }

      return FactCheckResult(
        verdict: verdict,
        summary: summary.isNotEmpty ? summary : responseText,
        sources: sources,
        timestamp: DateTime.now(),
        originalUrl: originalUrl,
      );
    } catch (e) {
      return FactCheckResult(
        verdict: FactCheckVerdict.unknown,
        summary: responseText,
        sources: [],
        timestamp: DateTime.now(),
        originalUrl: originalUrl,
      );
    }
  }

  /// Extracts source URLs and titles from text
  List<Source> _extractSourcesFromText(String text) {
    final List<Source> sources = [];
    
    // Pattern to match URLs
    final urlPattern = RegExp(r'https?://[^\s\)]+');
    final matches = urlPattern.allMatches(text);
    
    for (final match in matches) {
      final url = match.group(0)!;
      
      // Simple heuristic: use domain name as title
      final uri = Uri.tryParse(url);
      final title = uri?.host ?? 'Source ${sources.length + 1}';
      
      sources.add(Source(title: title, uri: url));
      
      // Limit to 5 sources
      if (sources.length >= 5) break;
    }
    
    return sources;
  }
}
