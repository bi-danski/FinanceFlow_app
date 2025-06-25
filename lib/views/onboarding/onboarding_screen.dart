import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../themes/app_theme.dart';
import '../auth/sign_in_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page view for onboarding screens
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              _buildOnboardingPage(
                image: 'assets/images/onboarding1.png',
                title: 'Seamlessly manage your Finances',
                description: 'Discover the revolutionary semi automated financial management experience.',
                backgroundColor: const Color(0xFFE8F5E9),
                buttonText: 'Get Started',
                showButton: false,
              ),
              _buildOnboardingPage(
                image: 'assets/images/onboarding2.png',
                title: 'Your Personal Finance Manager',
                description: 'Track Income, Manage Expenses & Generate Detailed Reports.',
                backgroundColor: Colors.white,
                buttonText: 'Continue',
                showButton: false,
              ),
              _buildOnboardingPage(
                image: 'assets/images/onboarding3.png',
                title: 'Welcome to FinanceFlow',
                description: 'Your complete financial management solution',
                backgroundColor: const Color(0xFFFF5252),
                buttonText: 'Get Started',
                showButton: true,
              ),
            ],
          ),
          
          // Bottom navigation (dots and button)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Page indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_numPages, (index) => _buildDot(index)),
                ),
                
                const SizedBox(height: 30),
                
                // Navigation button
                if (_currentPage < _numPages - 1)
                  _buildButton(
                    text: _currentPage == 0 ? 'Get Started' : 'Continue',
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.ease,
                      );
                    },
                  )
                else
                  _buildButton(
                    text: 'Get Started',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignInScreen()),
                      );
                    },
                  ),
              ],
            ),
          ),
          
          // Skip button
          if (_currentPage < _numPages - 1)
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInScreen()),
                  );
                },
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String image,
    required String title,
    required String description,
    required Color backgroundColor,
    required String buttonText,
    required bool showButton,
  }) {
    return Container(
      color: backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Center(
              child: _buildImageWithFallback(image)
              .animate()
              .fadeIn(duration: 600.ms)
              .moveY(begin: 30, end: 0),
            ),
          ),
          
          // Title and description
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 600.ms),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 600.ms),
                  
                  if (showButton) const SizedBox(height: 32),
                  
                  if (showButton)
                    _buildButton(
                      text: buttonText,
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const SignInScreen()),
                        );
                      },
                    )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 600.ms),
                ],
              ),
            ),
          ),
          
          // Space for bottom navigation
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppTheme.accentColor : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildImageWithFallback(String imagePath) {
    return Builder(
      builder: (context) {
        // Try to load the image, but provide a fallback if it fails
        return Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Determine which fallback to show based on image path
            if (imagePath.contains('onboarding1')) {
              // First onboarding screen - green with person
              return Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person, size: 100, color: AppTheme.accentColor),
                    const SizedBox(height: 20),
                    Icon(Icons.show_chart, size: 80, color: AppTheme.accentColor),
                  ],
                ),
              );
            } else if (imagePath.contains('onboarding2')) {
              // Second onboarding screen - finance manager
              return Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet, size: 80, color: AppTheme.accentColor),
                    const SizedBox(height: 20),
                    Icon(Icons.pie_chart, size: 60, color: AppTheme.primaryColor),
                    const SizedBox(height: 20),
                    Icon(Icons.attach_money, size: 60, color: Colors.amber),
                  ],
                ),
              );
            } else {
              // Third onboarding screen - piggy bank
              return Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.savings,
                  size: 120,
                  color: Color(0xFFFF5252),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward),
        ],
      ),
    );
  }
}
