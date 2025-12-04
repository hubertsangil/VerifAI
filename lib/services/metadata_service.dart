import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:flutter/foundation.dart';

class MetadataService {
  /// Extract metadata from a URL (title, description, Open Graph data)
  Future<UrlMetadata?> extractMetadata(String url) async {
    try {
      debugPrint('Extracting metadata from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body length: ${response.body.length}');
      
      if (response.statusCode != 200) {
        debugPrint('Failed to fetch URL: ${response.statusCode}');
        return null;
      }

      if (response.body.isEmpty) {
        debugPrint('Response body is empty');
        return null;
      }

      final document = html.parse(response.body);
      debugPrint('HTML parsed successfully');
      
      // Extract Open Graph metadata (used by Facebook, Twitter, etc.)
      String? title = _getMetaContent(document, 'og:title') 
                   ?? _getMetaContent(document, 'twitter:title')
                   ?? document.querySelector('title')?.text;
      
      String? description = _getMetaContent(document, 'og:description')
                         ?? _getMetaContent(document, 'twitter:description')
                         ?? _getMetaContent(document, 'description');
      
      String? image = _getMetaContent(document, 'og:image')
                   ?? _getMetaContent(document, 'twitter:image');
      
      String? siteName = _getMetaContent(document, 'og:site_name');
      
      String? author = _getMetaContent(document, 'author')
                    ?? _getMetaContent(document, 'article:author');

      // Try to extract main content text (first few paragraphs)
      String? contentPreview = _extractContentPreview(document);

      debugPrint('Metadata extracted - Title: $title, Description: $description');
      debugPrint('Content preview length: ${contentPreview?.length ?? 0}');
      
      return UrlMetadata(
        url: url,
        title: title,
        description: description,
        image: image,
        siteName: siteName,
        author: author,
        contentPreview: contentPreview,
      );
    } catch (e, stackTrace) {
      debugPrint('Error extracting metadata: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  String? _getMetaContent(document, String property) {
    // Try Open Graph format: <meta property="og:title" content="...">
    var element = document.querySelector('meta[property="$property"]');
    if (element != null) {
      return element.attributes['content'];
    }
    
    // Try name format: <meta name="description" content="...">
    element = document.querySelector('meta[name="$property"]');
    if (element != null) {
      return element.attributes['content'];
    }
    
    return null;
  }

  String? _extractContentPreview(document) {
    try {
      // Try to get main article content
      final article = document.querySelector('article') 
                   ?? document.querySelector('main')
                   ?? document.querySelector('.post-content')
                   ?? document.querySelector('.article-content');
      
      if (article != null) {
        final paragraphs = article.querySelectorAll('p');
        if (paragraphs.isNotEmpty) {
          // Get first 3 paragraphs
          final preview = paragraphs
              .take(3)
              .map((p) => p.text.trim())
              .where((text) => text.length > 50) // Filter out short paragraphs
              .join('\n\n');
          
          if (preview.length > 100) {
            return preview.length > 500 
                ? '${preview.substring(0, 500)}...' 
                : preview;
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
}

class UrlMetadata {
  final String url;
  final String? title;
  final String? description;
  final String? image;
  final String? siteName;
  final String? author;
  final String? contentPreview;

  UrlMetadata({
    required this.url,
    this.title,
    this.description,
    this.image,
    this.siteName,
    this.author,
    this.contentPreview,
  });

  String toAnalysisText() {
    final buffer = StringBuffer();
    buffer.writeln('URL: $url');
    
    if (siteName != null) buffer.writeln('Site: $siteName');
    if (author != null) buffer.writeln('Author: $author');
    if (title != null) buffer.writeln('Title: $title');
    if (description != null) buffer.writeln('Description: $description');
    if (contentPreview != null) {
      buffer.writeln('\nContent Preview:');
      buffer.writeln(contentPreview);
    }
    
    return buffer.toString();
  }
}
