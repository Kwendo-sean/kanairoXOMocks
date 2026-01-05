import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';

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
      'icon': PhosphorIcons.users(),
      'color': AppConstants.primaryRed,
      'image': 'assets/images/kanairoxo_logo.png',
    },
    {
      'title': 'Curated Experiences',
      'description': 'Join events and gatherings designed for authentic interactions.',
      'icon': PhosphorIcons.calendarStar(),
      'color': AppConstants.secondaryGray,
      'image': 'assets/images/kanairoxo_logo.png',
    },
    {
      'title': 'Your Mood Matters',
      'description': 'Our AI matches you with experiences based on how you\'re feeling.',
      'icon': PhosphorIcons.heart(),
      'color': AppConstants.primaryRed,
      'image': 'assets/images/kanairoxo_logo.png',
    },
    {
      'title': 'Safe & Private',
      'description': 'Your privacy is our priority. Disappearing messages and secure connections.',
      'icon': PhosphorIcons.shieldCheck(),
      'color': AppConstants.successGreen,
      'image': 'assets/images/kanairoxo_logo.png',
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
      backgroundColor: AppConstants.primaryBeige,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: widget.onComplete,
                    child: Text(
                      'Skip',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConstants.secondaryGray,
                      ),
                    ),
                  ),
                ),
                
                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                    },
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Image/Icon
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: page['color'].withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  page['icon'],
                                  size: 80,
                                  color: page['color'],
                                ),
                              ),
                              const SizedBox(height: 48),
                              
                              // Title
                              Text(
                                page['title'],
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontSize: 28,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              
                              // Description
                              Text(
                                page['description'],
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppConstants.secondaryGray,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Page indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _currentPage == index 
                            ? AppConstants.primaryRed 
                            : AppConstants.lightGray,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
                
                // Next/Get Started button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          widget.onComplete();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryRed,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                        ),
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}