import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();
  
  late AnimationController _animationController;
  late AnimationController _entryAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _entryFadeAnimation;
  late Animation<Offset> _entrySlideAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isDialogShowing = false;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void initState() {
    super.initState();
    
    // Form field animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
    
    // Entry animation controller
    _entryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _entryFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _entrySlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryAnimationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _entryAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _entryAnimationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    // Show splash screen
    if (mounted) {
      _isDialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _AuthLoadingDialog(
          message: _isLogin ? 'Logging you in...' : 'Creating your account...',
        ),
      );
    }

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Create user account
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        // Store additional user information in Firestore
        final firstName = _firstNameController.text.trim();
        final lastName = _lastNameController.text.trim();
        final fullName = '$firstName $lastName';
        
        // Save to Firestore and update display name in background
        _firestore.collection('users').doc(userCredential.user!.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'fullName': fullName,
          'email': _emailController.text.trim(),
          'age': int.parse(_ageController.text.trim()),
          'createdAt': FieldValue.serverTimestamp(),
        }).catchError((e) => debugPrint('Error saving user data: $e'));
        
        userCredential.user!.updateDisplayName(fullName)
            .catchError((e) => debugPrint('Error updating display name: $e'));
      }
      
      // Close splash screen immediately after successful auth
      if (mounted && _isDialogShowing) {
        _isDialogShowing = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      // Small delay to ensure smooth transition
      await Future.delayed(const Duration(milliseconds: 100));
      
    } on FirebaseAuthException catch (e) {
      // Close splash screen
      if (mounted && _isDialogShowing) {
        _isDialogShowing = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      setState(() {
        _emailError = null;
        _passwordError = null;
        _generalError = null;
        
        switch (e.code) {
          case 'user-not-found':
            _generalError = 'This user does not exist. Please check your email or sign up.';
            break;
          case 'wrong-password':
            _generalError = 'Incorrect password. Please try again.';
            break;
          case 'invalid-credential':
            _generalError = 'Invalid email or password. Please check your credentials.';
            break;
          case 'email-already-in-use':
            _emailError = 'An account already exists with this email';
            break;
          case 'weak-password':
            _passwordError = 'Password should be at least 6 characters';
            break;
          case 'invalid-email':
            _emailError = 'Invalid email address';
            break;
          case 'too-many-requests':
            _generalError = 'Too many failed attempts. Please try again later.';
            break;
          default:
            _generalError = 'Invalid email or password. Please try again.';
        }
      });
    } catch (e) {
      // Close splash screen
      if (mounted && _isDialogShowing) {
        _isDialogShowing = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      setState(() {
        _generalError = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const _AuthLoadingDialog(message: 'Signing in with Google...'),
        );
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Add delay to ensure auth state changes
      await Future.delayed(const Duration(milliseconds: 300));

      // Save user data to Firestore (if new user)
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final user = userCredential.user;
        if (user != null) {
          final nameParts = user.displayName?.split(' ') ?? ['User', ''];
          final firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
          final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          
          _firestore.collection('users').doc(user.uid).set({
            'firstName': firstName,
            'lastName': lastName,
            'fullName': user.displayName ?? 'User',
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
          }).catchError((error) {
            debugPrint('Error saving user data: $error');
          });
        }
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } on FirebaseAuthException catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      setState(() {
        _generalError = 'Google sign-in failed: ${e.message}';
      });
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      setState(() {
        _generalError = 'An error occurred during Google sign-in';
      });
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
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
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();
              
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email address'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              try {
                await _auth.sendPasswordResetEmail(email: email);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset email sent to $email'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                String message = 'Failed to send reset email';
                if (e.code == 'user-not-found') {
                  message = 'No account found with this email';
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _entryFadeAnimation,
              child: SlideTransition(
                position: _entrySlideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App Logo/Title with scale animation
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Icon(
                          Icons.verified_user,
                          size: 80,
                          color: const Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // App name with animated blue gradient
                      const _AnimatedGradientText(
                        text: 'VerifAI',
                        fontSize: 42,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI-Powered Fact Checking',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Login/Register Label
                      Text(
                        _isLogin ? 'Login' : 'Register',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 24),
                  
                  // Animated Name and Age Fields
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Column(
                      children: [
                        // First Name and Last Name Fields (only for sign up)
                        if (!_isLogin) ...[
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: TextFormField(
                                controller: _firstNameController,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'First Name',
                                  prefixIcon: const Icon(Icons.person_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your first name';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'First name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: TextFormField(
                                controller: _lastNameController,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Last Name',
                                  prefixIcon: const Icon(Icons.person_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your last name';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Last name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  
                  // Email error message
                  if (_emailError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _emailError!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  
                  // Password error message
                  if (_passwordError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _passwordError!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Forgot Password Link (only for login)
                  if (_isLogin) ...[
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  // Animated Age Field
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Column(
                      children: [
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Age',
                                  prefixIcon: const Icon(Icons.cake_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your age';
                                  }
                                  final age = int.tryParse(value.trim());
                                  if (age == null) {
                                    return 'Please enter a valid number';
                                  }
                                  if (age < 13) {
                                    return 'You must be at least 13 years old';
                                  }
                                  if (age > 120) {
                                    return 'Please enter a valid age';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // General Error Message (for non-field-specific errors)
                  if (_generalError != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _generalError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Submit Button with gradient
                  SizedBox(
                    height: 50,
                    child: _AuthGradientButton(
                      onPressed: _isLoading ? null : _submitForm,
                      isLoading: _isLoading,
                      label: _isLogin ? 'Sign In' : 'Sign Up',
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Divider with "Or" text
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _isLogin ? 'Or sign in with' : 'Or sign up with',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Google Sign-In Button
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: Image.asset(
                        'assets/images/google_logo.png',
                        height: 24,
                        width: 24,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to icon if image not found
                          return const Icon(
                            Icons.g_mobiledata,
                            size: 32,
                            color: Color(0xFF4285F4),
                          );
                        },
                      ),
                      label: Text(
                        _isLogin ? 'Continue with Google' : 'Sign up with Google',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Toggle Sign In/Sign Up
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _emailError = null;
                        _passwordError = null;
                        _generalError = null;
                        
                        // Reset and restart animations
                        _animationController.reset();
                        _animationController.forward();
                      });
                    },
                    child: Text(
                      _isLogin
                          ? 'Don\'t have an account? Sign Up'
                          : 'Already have an account? Sign In',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )));
  }
}

// Auth loading splash screen
class _AuthLoadingDialog extends StatelessWidget {
  final String message;
  
  const _AuthLoadingDialog({required this.message});

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
                message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Gradient button for auth screen
class _AuthGradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _AuthGradientButton({
    required this.onPressed,
    this.isLoading = false,
    required this.label,
  });

  @override
  State<_AuthGradientButton> createState() => _AuthGradientButtonState();
}

class _AuthGradientButtonState extends State<_AuthGradientButton>
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.onPressed == null
                  ? [Colors.grey.shade400, Colors.grey.shade400]
                  : const [
                      Color(0xFF1976D2),
                      Color(0xFF64B5F6),
                      Color(0xFF1976D2),
                      Color(0xFF64B5F6),
                      Color(0xFF1976D2),
                    ],
              stops: widget.onPressed == null
                  ? null
                  : [
                      (_gradientAnimation.value - 0.5).clamp(0.0, 1.0),
                      (_gradientAnimation.value - 0.25).clamp(0.0, 1.0),
                      _gradientAnimation.value.clamp(0.0, 1.0),
                      (_gradientAnimation.value + 0.25).clamp(0.0, 1.0),
                      (_gradientAnimation.value + 0.5).clamp(0.0, 1.0),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.onPressed != null
                    ? const Color(0xFF1976D2).withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: widget.onPressed != null ? 8 : 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: widget.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
