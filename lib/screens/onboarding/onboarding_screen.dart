import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingScreen({super.key, required this.onComplete});
  
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Meaningful Connections',
      'description': 'Discover people who share your interests and values, not just profiles.',
      'icon': Icons.people_outline,
    },
    {
      'title': 'Curated Experiences',
      'description': 'Join events and gatherings designed for authentic interactions.',
      'icon': Icons.calendar_today_outlined,
    },
    {
      'title': 'Your Mood Matters',
      'description': 'Our AI matches you with experiences based on how you\'re feeling.',
      'icon': Icons.favorite_border_outlined,
    },
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onComplete,
                child: Text('Skip', style: AppTypography.labelMedium),
              ),
            ),
            
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGlass,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page['icon'], size: 80, color: AppColors.primary),
                        ),
                        const SizedBox(height: 48),
                        Text(page['title'], style: AppTypography.displayLarge, textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        Text(page['description'], style: AppTypography.bodyLarge, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppColors.primary : AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: LiquidGlassButton(
                size: LiquidButtonSize.xl,
                width: double.infinity,
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  } else {
                    widget.onComplete();
                  }
                },
                child: Text(_currentPage < _pages.length - 1 ? 'Next' : 'Get Started', style: AppTypography.buttonText),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
