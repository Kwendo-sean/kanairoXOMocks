import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const SplashScreen({super.key, required this.onComplete});
  
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textFadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    // Start animation
    _controller.forward();
    
    // Complete after 7 seconds (adjust as needed)
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with fade and scale animation
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/kanairoxo_logo.png', // Your logo path
                width: 180, // Adjust based on your logo size
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if logo not found
                  return Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryRed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryRed.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 80,
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Tagline with fade animation
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _textFadeAnimation.value,
                  child: child,
                );
              },
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Meet, Connect , Experience',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      color: AppConstants.secondaryGray,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 80),
            
            // Loading indicator (optional - remove if not in mockup)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _textFadeAnimation.value,
                  child: child,
                );
              },
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppConstants.primaryRed,
                  strokeWidth: 2,
                  backgroundColor: AppConstants.primaryRed.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}