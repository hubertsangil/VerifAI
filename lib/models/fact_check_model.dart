import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing the verdict of a fact-check analysis
enum FactCheckVerdict {
  accurate,
  misleading,
  false_,
  unknown;

  @override
  String toString() {
    switch (this) {
      case FactCheckVerdict.accurate:
        return 'ACCURATE';
      case FactCheckVerdict.misleading:
        return 'MISLEADING';
      case FactCheckVerdict.false_:
        return 'FALSE';
      case FactCheckVerdict.unknown:
        return 'UNKNOWN';
    }
  }

  static FactCheckVerdict fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ACCURATE':
        return FactCheckVerdict.accurate;
      case 'MISLEADING':
        return FactCheckVerdict.misleading;
      case 'FALSE':
        return FactCheckVerdict.false_;
      default:
        return FactCheckVerdict.unknown;
    }
  }
}

/// Class representing a source citation
class Source {
  final String title;
  final String uri;

  Source({
    required this.title,
    required this.uri,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'uri': uri,
    };
  }

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      title: json['title'] ?? '',
      uri: json['uri'] ?? '',
    );
  }
}

/// Main class representing a fact-check result
class FactCheckResult {
  final FactCheckVerdict verdict;
  final String summary;
  final List<Source> sources;
  final DateTime timestamp;
  final String originalUrl;

  FactCheckResult({
    required this.verdict,
    required this.summary,
    required this.sources,
    required this.timestamp,
    required this.originalUrl,
  });

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    return {
      'verdict': verdict.toString(),
      'summary': summary,
      'sources': sources.map((s) => s.toJson()).toList(),
      'timestamp': Timestamp.fromDate(timestamp),
      'originalUrl': originalUrl,
    };
  }

  /// Create from Firestore document
  factory FactCheckResult.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return FactCheckResult(
      verdict: FactCheckVerdict.fromString(data['verdict'] ?? 'UNKNOWN'),
      summary: data['summary'] ?? '',
      sources: (data['sources'] as List<dynamic>?)
              ?.map((s) => Source.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      originalUrl: data['originalUrl'] ?? '',
    );
  }

  /// Alternative factory method from Map
  factory FactCheckResult.fromMap(Map<String, dynamic> data) {
    return FactCheckResult(
      verdict: FactCheckVerdict.fromString(data['verdict'] ?? 'UNKNOWN'),
      summary: data['summary'] ?? '',
      sources: (data['sources'] as List<dynamic>?)
              ?.map((s) => Source.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.parse(data['timestamp']),
      originalUrl: data['originalUrl'] ?? '',
    );
  }
}
