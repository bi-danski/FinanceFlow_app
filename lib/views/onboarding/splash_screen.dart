import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to onboarding screen after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFF5252), // Red background color
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Expanded space
              const Expanded(flex: 1, child: SizedBox()),
              
              // Piggy bank icon
              Builder(
                builder: (context) {
                  return Image.asset(
                    'assets/images/piggy_bank.png',
                    width: 100,
                    height: 100,
                    color: Colors.white,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to an icon if image loading fails
                      return const Icon(
                        Icons.savings,
                        size: 100,
                        color: Colors.white,
                      );
                    },
                  );
                },
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .scaleXY(delay: 300.ms, duration: 600.ms),
              
              // Expanded space
              const Expanded(flex: 1, child: SizedBox()),
              
              // Company logo at bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'FinanceFlow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
