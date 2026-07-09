import 'package:flutter/material.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Pages count — data fetched in build from l10n
  static const int _pageCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<_OnboardingData> pages = [
      _OnboardingData(
        title: l10n.onboardingTitle1,
        titleSpan: l10n.onboardingTitleSpan1,
        description: l10n.onboardingDesc1,
        image: 'assets/images/fuel.png',
        color: const Color(0xFFFFF0E6),
      ),
      _OnboardingData(
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDesc2,
        image: 'assets/images/map.png',
        color: const Color(0xFFE8F1FF),
      ),
      _OnboardingData(
        title: l10n.onboardingTitle3,
        description: l10n.onboardingDesc3,
        image: 'assets/images/tick.png',
        color: const Color(0xFFE6F7ED),
      ),
      _OnboardingData(
        title: l10n.onboardingTitle4,
        description: l10n.onboardingDesc4,
        image: 'assets/images/money.png',
        color: const Color(0xFFFEF9E7),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _goToLogin,
                    child: Text(
                      l10n.onboardingSkip,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final data = pages[index];
                  return Column(
                    children: [
                      const Spacer(flex: 1),
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            color: data.color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Image.asset(
                              data.image,
                              width: 120,
                              height: 120,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (data.titleSpan != null)
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                              fontFamily: 'Inter',
                            ),
                            children: [
                              TextSpan(text: data.title),
                              TextSpan(
                                text: data.titleSpan,
                                style: const TextStyle(color: Color(0xFFFF6600)),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          data.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  );
                },
              ),
            ),

            // Pagination Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (index) {
                bool isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 8),
                  width: isActive ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFFF6600) : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6600),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == pages.length - 1
                        ? l10n.onboardingGetStarted
                        : l10n.onboardingNext,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String? titleSpan;
  final String description;
  final String image;
  final Color color;

  _OnboardingData({
    required this.title,
    this.titleSpan,
    required this.description,
    required this.image,
    required this.color,
  });
}
