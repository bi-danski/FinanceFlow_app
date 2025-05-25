import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_auth_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/enhanced_animations.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      final authService = FirebaseAuthService.instance;
      
      try {
        // Show loading state
        setState(() => _isLoading = true);
        
        // Attempt to register with Firebase
        await authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
        
        if (mounted) {
          // Navigate to dashboard on success
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } on FirebaseAuthException catch (e) {
        // Handle specific Firebase Auth errors with user-friendly messages
        String errorMessage = 'An error occurred during registration';
        
        if (e.code == 'email-already-in-use') {
          errorMessage = 'This email is already in use';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Password is too weak. Use at least 6 characters';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Invalid email format';
        } else if (e.code == 'network-request-failed') {
          errorMessage = 'Network error. Check your connection';
        }
        
        if (mounted) {
          // Show animated error message
          final snackBar = SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          );
          
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } catch (e) {
        // Handle generic errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        // Reset loading state if widget is still mounted
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else if (!_agreeToTerms && mounted) {
      // Show error if terms not agreed to
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms and Conditions'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService.instance;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppTheme.secondaryColor.withValues(alpha: 0.9),
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          
          // Background pattern
          Opacity(
            opacity: 0.05,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/pattern.png'),
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and title
                      _buildHeader(),
                      
                      const SizedBox(height: 32),
                      
                      // Form
                      _buildForm(authService),
                      
                      const SizedBox(height: 24),
                      
                      // Sign in link
                      _buildSignInLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App logo
        Image.asset(
          'assets/images/logo.png',
          height: 70,
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -20, end: 0, curve: Curves.easeOutQuad),
        
        const SizedBox(height: 16),
        
        // Welcome text
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms),
        
        const SizedBox(height: 8),
        
        Text(
          'Sign up to start managing your finances',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        )
        .animate()
        .fadeIn(delay: 500.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildForm(FirebaseAuthService authService) {
    return Form(
      key: _formKey,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              )
              .animate()
              .fadeIn(delay: 600.ms, duration: 600.ms)
              .moveX(begin: -20, end: 0),
              
              const SizedBox(height: 16),
              
              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              )
              .animate()
              .fadeIn(delay: 800.ms, duration: 600.ms)
              .moveX(begin: 20, end: 0),
              
              const SizedBox(height: 16),
              
              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              )
              .animate()
              .fadeIn(delay: 1000.ms, duration: 600.ms)
              .moveX(begin: -20, end: 0),
              
              const SizedBox(height: 16),
              
              // Confirm password field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              )
              .animate()
              .fadeIn(delay: 1200.ms, duration: 600.ms)
              .moveX(begin: 20, end: 0),
              
              const SizedBox(height: 16),
              
              // Terms and conditions
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreeToTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'I agree to the Terms and Conditions and Privacy Policy',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 1400.ms, duration: 600.ms),
              
              const SizedBox(height: 24),
              
              // Sign up button
              EnhancedAnimations.modernHoverEffect(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Text(
                          'CREATE ACCOUNT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              )
              .animate()
              .fadeIn(delay: 1600.ms, duration: 600.ms)
              .moveY(begin: 20, end: 0),
              
              const SizedBox(height: 24),
              
              // Social sign up
              _buildSocialSignUp(),
            ],
          ),
        ),
      )
      .animate()
      .fadeIn(delay: 400.ms, duration: 800.ms)
      .scaleXY(begin: 0.9, end: 1.0),
    );
  }

  Widget _buildSocialSignUp() {
    return Column(
      children: [
        Text(
          'Or sign up with',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google
            _socialButton(
              icon: 'assets/icons/google.png',
              onTap: () {
                // Implement Google sign up
              },
            ),
            
            const SizedBox(width: 16),
            
            // Apple
            _socialButton(
              icon: 'assets/icons/apple.png',
              onTap: () {
                // Implement Apple sign up
              },
            ),
            
            const SizedBox(width: 16),
            
            // Facebook
            _socialButton(
              icon: 'assets/icons/facebook.png',
              onTap: () {
                // Implement Facebook sign up
              },
            ),
          ],
        ),
      ],
    )
    .animate()
    .fadeIn(delay: 1800.ms, duration: 600.ms);
  }

  Widget _socialButton({required String icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            icon,
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(color: Colors.white),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'Sign In',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    )
    .animate()
    .fadeIn(delay: 2000.ms, duration: 600.ms);
  }
}
