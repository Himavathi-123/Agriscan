// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import 'home.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Re-using colors for consistency
  static const Color kGreen700 = Color(0xFF2D6A4F);
  static const Color kGreen500 = Color(0xFF40916C);
  static const Color kBg = Color(0xFFE8F5E9);
  static const Color kCard = Colors.white;
  static const Color kRed = Color(0xFFE63946);
  static const Color kTextPrimary = Color(0xFF1B262C);
  static const Color kTextSecondary = Color(0xFF5A666D);

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final error = AuthService().login(
        _identifierController.text,
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (error == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        String msg = context.l10n('invalid_credentials');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: kRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.eco_rounded, color: kGreen700, size: 80),
                const SizedBox(height: 24),
                Text(
                  context.l10n('login'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),

                TextFormField(
                  controller: _identifierController,
                  style: const TextStyle(color: kTextPrimary),
                  decoration: InputDecoration(
                    labelText: context.l10n(
                      'email_or_mobile',
                    ), // Changed labelText
                    labelStyle: const TextStyle(color: kTextSecondary),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: kGreen700,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ),
                  validator:
                      (v) =>
                          v!.isEmpty
                              ? context.l10n('enter_email_or_mobile')
                              : null, // Changed validator message
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: kTextPrimary),
                  decoration: InputDecoration(
                    labelText: context.l10n('password'),
                    labelStyle: const TextStyle(color: kTextSecondary),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: kGreen700,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ),
                  validator:
                      (v) => v!.isEmpty ? context.l10n('enter_password') : null,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            context.l10n('login'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed:
                      () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      ),
                  child: Text(
                    context.l10n('new_farmer'),
                    style: const TextStyle(color: kGreen700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
