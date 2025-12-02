import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import '../services/gemini_service.dart';
import '../services/history_service.dart';
import '../models/fact_check_model.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlController = TextEditingController();
  final _geminiService = GeminiService();
  final _historyService = HistoryService();
  
  int _currentIndex = 0;
  bool _isAnalyzing = false;
  bool _isMissionExpanded = false;
  FactCheckResult? _currentResult;
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initSharingIntent();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  void _initSharingIntent() {
    // Listen for shared content while app is running
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty && value.first.path.isNotEmpty) {
          setState(() {
            _urlController.text = value.first.path;
          });
        }
      },
      onError: (err) {
        debugPrint("Error receiving shared media: $err");
      },
    );

    // Get shared content when app is opened from share sheet
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value.first.path.isNotEmpty) {
        setState(() {
          _urlController.text = value.first.path;
        });
      }
    });
  }

  Future<void> _analyzeLink() async {
    if (_urlController.text.trim().isEmpty) {
      _showSnackBar('Please enter a URL to analyze');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _currentResult = null;
    });

    try {
      final result = await _geminiService.analyzeUrl(_urlController.text.trim());
      
      // Save to history
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _historyService.saveFactCheck(user.uid, result);
      }

      setState(() {
        _currentResult = result;
      });
    } catch (e) {
      _showSnackBar('Error analyzing link: ${e.toString()}');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Color _getVerdictColor(FactCheckVerdict verdict) {
    switch (verdict) {
      case FactCheckVerdict.accurate:
        return Colors.green;
      case FactCheckVerdict.misleading:
        return Colors.orange;
      case FactCheckVerdict.false_:
        return Colors.red;
      case FactCheckVerdict.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verity.ai'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildNewCheckTab(),
          const HistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'New Check',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildNewCheckTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // URL Input Field
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'Enter URL to verify',
              hintText: 'https://example.com/article',
              prefixIcon: const Icon(Icons.link),
              border: const OutlineInputBorder(),
              suffixIcon: _urlController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _urlController.clear();
                          _currentResult = null;
                        });
                      },
                    )
                  : null,
            ),
            keyboardType: TextInputType.url,
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          // Analyze Button
          FilledButton.icon(
            onPressed: _isAnalyzing ? null : _analyzeLink,
            icon: _isAnalyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Link'),
          ),
          const SizedBox(height: 24),

          // Mission/SDG Panel
          Card(
            child: ExpansionTile(
              title: const Text('Our Mission & SDG Alignment'),
              subtitle: const Text('Learn about our commitment'),
              leading: const Icon(Icons.flag),
              initiallyExpanded: _isMissionExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _isMissionExpanded = expanded;
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Our Mission',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Verity.ai empowers users to combat misinformation through AI-powered fact-checking, promoting informed decision-making and digital literacy.',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'UN Sustainable Development Goals',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• SDG 16: Peace, Justice, and Strong Institutions\n'
                        '• SDG 4: Quality Education\n'
                        '• SDG 9: Industry, Innovation, and Infrastructure',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Results Display
          if (_currentResult != null) _buildResultCard(_currentResult!),
        ],
      ),
    );
  }

  Widget _buildResultCard(FactCheckResult result) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verdict Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getVerdictColor(result.verdict).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  result.verdict == FactCheckVerdict.accurate
                      ? Icons.check_circle
                      : result.verdict == FactCheckVerdict.false_
                          ? Icons.cancel
                          : Icons.warning,
                  color: _getVerdictColor(result.verdict),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verdict',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        result.verdict.toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: _getVerdictColor(result.verdict),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Summary
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(result.summary),
                const SizedBox(height: 16),

                // Sources
                if (result.sources.isNotEmpty) ...[
                  Text(
                    'Sources',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...result.sources.map((source) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            // TODO: Open URL in browser
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.link, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  source.title,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
