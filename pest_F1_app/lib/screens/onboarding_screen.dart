import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import 'login_screen.dart';
import 'home.dart';

class OnboardingScreen extends StatefulWidget {
  final String languageCode;
  const OnboardingScreen({super.key, required this.languageCode});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // In a real app, you'd apply the language immediately.
    // We'll update LanguageService in the 'Get Started' button or Skip.
  }

  List<Map<String, String>> getPages(AppLocalizations l10n) {
    return [
      {
        'title': l10n.translate('welcome_title'),
        'desc': l10n.translate('welcome_desc'),
        'icon': 'eco_rounded',
      },
      {
        'title': l10n.translate('feature1_title'),
        'desc': l10n.translate('feature1_desc'),
        'icon': 'camera_alt_rounded',
      },
      {
        'title': l10n.translate('feature2_title'),
        'desc': l10n.translate('feature2_desc'),
        'icon': 'psychology_rounded',
      },
      {
        'title': l10n.translate('feature3_title'),
        'desc': l10n.translate('feature3_desc'),
        'icon': 'history_rounded',
      },
    ];
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'eco_rounded':
        return Icons.eco_rounded;
      case 'camera_alt_rounded':
        return Icons.camera_alt_rounded;
      case 'psychology_rounded':
        return Icons.psychology_rounded;
      case 'history_rounded':
        return Icons.history_rounded;
      default:
        return Icons.help_outline;
    }
  }

  void _finishOnboarding() async {
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    await languageService.setFirstRunComplete();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use a temporary AppLocalizations if the global one isn't set yet.
    final l10n = AppLocalizations(Locale(widget.languageCode));

    final pages = getPages(l10n);

    Color bgColor;
    switch (_currentPage) {
      case 0:
        bgColor = const Color(0xFF2D6A4F); // Welcome - Original Green
        break;
      case 1:
        bgColor = const Color(
          0xFF1A1A1A,
        ); // Instant Detection - Camera Black/Dark Gray
        break;
      case 2:
        bgColor = const Color(0xFF03A9F4); // Expert Advice - Light Blue
        break;
      case 3:
        bgColor = const Color(0xFF455A64); // History Tracking - Time/Blue Gray
        break;
      default:
        bgColor = const Color(0xFF2D6A4F);
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _finishOnboarding,
            child: Text(
              l10n.translate('skip'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final page = pages[index];
                Color iconColor = Colors.white;
                if (index == 1)
                  iconColor = Colors.redAccent; // Camera record dot feel

                return Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getIcon(page['icon']!),
                        size: 150,
                        color: iconColor,
                      ),
                      const SizedBox(height: 48),
                      Text(
                        page['title']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        page['desc']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Row(
                  children: List.generate(
                    pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          _currentPage == index ? 1.0 : 0.4,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                // Next/Get Started Button
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == pages.length - 1) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _currentPage == pages.length - 1
                            ? Colors.blueAccent
                            : Colors.white,
                    foregroundColor:
                        _currentPage == pages.length - 1
                            ? Colors.white
                            : const Color(0xFF2D6A4F),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == pages.length - 1
                        ? l10n.translate('get_started')
                        : l10n.translate('next'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
