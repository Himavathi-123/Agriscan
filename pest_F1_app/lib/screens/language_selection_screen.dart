import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import 'onboarding_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selectedCode;

  final languages = [
    {'code': 'te', 'name': 'తెలుగు'},
    {'code': 'hi', 'name': 'हिन्दी'},
    {'code': 'en', 'name': 'English'},
    {'code': 'bn', 'name': 'বাংলা'},
    {'code': 'ta', 'name': 'தமிழ்'},
    {'code': 'mr', 'name': 'మరాठी'},
    {'code': 'ur', 'name': 'اردو'},
    {'code': 'gu', 'name': 'ગુજરાતી'},
    {'code': 'kn', 'name': 'ಕನ್ನಡ'},
    {'code': 'ml', 'name': 'മലയാളം'},
    {'code': 'pa', 'name': 'ਪੰਜਾਬੀ'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80, // Increased header height
        backgroundColor: Colors.lightBlue[50], // Light blue header background
        title: const Text(
          'Select language to continue',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];
          final isSelected = _selectedCode == lang['code'];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              onTap: () async {
                setState(() {
                  _selectedCode = lang['code']!;
                });

                // Short delay to show the green selection color before navigating
                await Future.delayed(const Duration(milliseconds: 200));

                if (!mounted) return;

                final languageService = Provider.of<LanguageService>(
                  context,
                  listen: false,
                );
                await languageService.setLocale(lang['code']!);

                if (mounted) {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                OnboardingScreen(languageCode: lang['code']!),
                      ),
                    );
                  }
                }
              },
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? Colors.green : Colors.deepPurple,
                      // Removed shadow as requested
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      lang['name']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
