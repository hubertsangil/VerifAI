import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import '../services/gemini_service.dart'; // Direct API call (works without Cloud Functions)
// import '../services/cloud_function_service.dart'; // Requires Blaze plan
import '../services/history_service.dart';
import '../models/fact_check_model.dart';
import '../config/app_config.dart';
import '../widgets/share_tutorial_dialog.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlController = TextEditingController();
  final _geminiService = GeminiService(); // Direct API call (works without Cloud Functions)
  // final _cloudFunctionService = CloudFunctionService(); // Requires Blaze plan
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
    // Listen for shared content (URLs from Facebook, TikTok, etc.) while app is running
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          final sharedContent = value.first.path;
          debugPrint('Received shared content: $sharedContent');
          setState(() {
            _urlController.text = sharedContent;
          });
          // Auto-analyze when content is shared
          _showAnalyzeConfirmation(sharedContent);
        }
      },
      onError: (err) {
        debugPrint("Error receiving shared content: $err");
      },
    );

    // Get shared content when app is opened from share sheet
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        final sharedContent = value.first.path;
        debugPrint('Initial shared content: $sharedContent');
        setState(() {
          _urlController.text = sharedContent;
        });
        _showAnalyzeConfirmation(sharedContent);
      }
      // Clear the shared data so it doesn't persist
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _showAnalyzeConfirmation(String url) {
    // Show a dialog to confirm auto-analysis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.fact_check, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Expanded(child: Text('Fact-Check This?')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VerifAI will analyze this content for accuracy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  url.length > 100 ? '${url.substring(0, 100)}...' : url,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _analyzeLink();
              },
              icon: const Icon(Icons.search),
              label: const Text('Analyze'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _analyzeLink() async {
    if (_urlController.text.trim().isEmpty) {
      _showSnackBar('Please enter a URL to analyze');
      return;
    }

    // Check if API is configured
    if (!AppConfig.isConfigured) {
      _showSnackBar('⚠️ ${AppConfig.configurationStatus}\nPlease add your Gemini API key in lib/config/app_config.dart');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _currentResult = null;
    });

    try {
      debugPrint('Starting analysis for URL: ${_urlController.text.trim()}');
      
      // Direct API call (works without Cloud Functions, but less secure for production)
      final result = await _geminiService.analyzeUrl(_urlController.text.trim());
      
      debugPrint('Analysis complete. Verdict: ${result.verdict}');
      debugPrint('Summary: ${result.summary}');
      
      // Check if the result indicates an error
      if (result.verdict == FactCheckVerdict.unknown && 
          result.summary.contains('Error analyzing URL')) {
        _showSnackBar('Failed to analyze URL. Please check:\n1. Your internet connection\n2. The URL is valid\n3. Your Gemini API key is correct');
      }
      
      // Save to history
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('Saving to history for user: ${user.uid}');
        await _historyService.saveFactCheck(user.uid, result);
      }

      setState(() {
        _currentResult = result;
      });
      
      debugPrint('Result displayed successfully');
    } catch (e, stackTrace) {
      debugPrint('Error analyzing link: $e');
      debugPrint('Stack trace: $stackTrace');
      _showSnackBar('Error analyzing link: ${e.toString()}');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: message.contains('API key') 
          ? SnackBarAction(
              label: 'Help',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Setup Required'),
                    content: const SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('To use VerifAI fact-checking, you need a Gemini API key:\n'),
                          Text('1. Visit: https://makersuite.google.com/app/apikey', 
                               style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('2. Sign in with your Google account'),
                          SizedBox(height: 8),
                          Text('3. Click "Create API Key"'),
                          SizedBox(height: 8),
                          Text('4. Copy the key'),
                          SizedBox(height: 8),
                          Text('5. Open lib/config/app_config.dart'),
                          SizedBox(height: 8),
                          Text('6. Replace YOUR_GEMINI_API_KEY_HERE with your key'),
                          SizedBox(height: 16),
                          Text('Note: The Gemini API has a free tier for testing!', 
                               style: TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                );
              },
            )
          : null,
      ),
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
        return Colors.blue; // Changed from grey to blue for better visibility
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('VerifAI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Show signing out splash screen
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const _SigningOutDialog(),
              );
              
              // Wait a moment for visual feedback
              await Future.delayed(const Duration(milliseconds: 800));
              
              // Close the dialog
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              
              // Sign out
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
          const SizedBox(height: 40),
          
          // Call-to-Action Header with animated blue gradient
          const _AnimatedGradientText(
            text: 'Verify the Truth',
            fontSize: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Paste a link below to check its credibility',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 40),
          
          // Centered URL Input Field with Google styling
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: TextField(
                controller: _urlController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Enter URL to verify',
                  hintText: 'https://example.com/article',
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: const BorderSide(width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: const BorderSide(
                      color: Color(0xFF4285F4),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
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
            ),
          ),
          const SizedBox(height: 24),

          // Large Analyze Button with Google-style gradient
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _GradientButton(
                onPressed: _isAnalyzing ? null : _analyzeLink,
                isLoading: _isAnalyzing,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Results Display
          if (_currentResult != null) ...[
            _buildResultCard(_currentResult!),
            const SizedBox(height: 32),
          ],

          // Mission/SDG Panel (moved to bottom)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ExpansionTile(
              title: const Text('Our Mission & SDG Alignment'),
              subtitle: const Text('Learn about our commitment'),
              leading: const Icon(Icons.flag, color: Color(0xFF1976D2)),
              initiallyExpanded: _isMissionExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _isMissionExpanded = expanded;
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mission Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline,
                              color: Color(0xFF1976D2),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Our Mission',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1976D2),
                                      ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'VerifAI empowers users to combat misinformation through AI-powered fact-checking, promoting informed decision-making and digital literacy.',
                                  style: TextStyle(height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // SDG Section Header
                      Text(
                        'UN Sustainable Development Goals',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1976D2),
                            ),
                      ),
                      const SizedBox(height: 16),
                      
                      // SDG 16
                      _buildSDGItem(
                        context,
                        number: '16',
                        color: const Color(0xFF00689D),
                        title: 'Peace, Justice and Strong Institutions',
                        description: 'Promoting access to truthful information and accountability',
                      ),
                      const SizedBox(height: 12),
                      
                      // SDG 4
                      _buildSDGItem(
                        context,
                        number: '4',
                        color: const Color(0xFFC5192D),
                        title: 'Quality Education',
                        description: 'Enhancing digital literacy and critical thinking skills',
                      ),
                      const SizedBox(height: 12),
                      
                      // SDG 9
                      _buildSDGItem(
                        context,
                        number: '9',
                        color: const Color(0xFFFF7F00),
                        title: 'Industry, Innovation and Infrastructure',
                        description: 'Leveraging AI technology for social good',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Share Feature Info Card
          Card(
            elevation: 0,
            color: const Color(0xFF1976D2).withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: const Color(0xFF1976D2).withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share from Any App',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1976D2),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share posts from Facebook, TikTok, or any app directly to VerifAI for instant fact-checking!',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black87,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Color(0xFF1976D2)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const ShareTutorialDialog(),
                      );
                    },
                    tooltip: 'How to use',
                  ),
                ],
              ),
            ),
          ),
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
                          : result.verdict == FactCheckVerdict.unknown
                              ? Icons.info_outline
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
                        result.verdict == FactCheckVerdict.unknown 
                            ? 'Authentication Required'
                            : 'Verdict',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        result.verdict == FactCheckVerdict.unknown
                            ? 'CANNOT VERIFY'
                            : result.verdict.toString(),
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

  // Helper method to build SDG items with icon badges
  Widget _buildSDGItem(
    BuildContext context, {
    required String number,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SDG Number Badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Signing out splash screen
class _SigningOutDialog extends StatelessWidget {
  const _SigningOutDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Signing you out...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Google-style gradient button with hover effect
class _GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GradientButton({
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _gradientAnimation = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientAnimation,
      builder: (context, child) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [
                Color(0xFF1976D2),
                Color(0xFF64B5F6),
                Color(0xFF1976D2),
                Color(0xFF64B5F6),
                Color(0xFF1976D2),
              ],
              stops: [
                (_gradientAnimation.value - 0.5).clamp(0.0, 1.0),
                (_gradientAnimation.value - 0.25).clamp(0.0, 1.0),
                _gradientAnimation.value.clamp(0.0, 1.0),
                (_gradientAnimation.value + 0.25).clamp(0.0, 1.0),
                (_gradientAnimation.value + 0.5).clamp(0.0, 1.0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1976D2).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(50),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search,
                            size: 28,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.isLoading ? 'Analyzing...' : 'Analyze Link',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Animated gradient text widget
class _AnimatedGradientText extends StatefulWidget {
  final String text;
  final double fontSize;

  const _AnimatedGradientText({
    required this.text,
    required this.fontSize,
  });

  @override
  State<_AnimatedGradientText> createState() => _AnimatedGradientTextState();
}

class _AnimatedGradientTextState extends State<_AnimatedGradientText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _animation = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: const [
              Color(0xFF1976D2),
              Color(0xFF64B5F6),
              Color(0xFF1976D2),
              Color(0xFF64B5F6),
              Color(0xFF1976D2),
            ],
            stops: [
              (_animation.value - 0.5).clamp(0.0, 1.0),
              (_animation.value - 0.25).clamp(0.0, 1.0),
              _animation.value.clamp(0.0, 1.0),
              (_animation.value + 0.25).clamp(0.0, 1.0),
              (_animation.value + 0.5).clamp(0.0, 1.0),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: widget.fontSize,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
