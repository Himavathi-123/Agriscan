// lib/screens/register_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../models/farmer.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'home.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();

  File? _profileImage;
  String? _webImagePath; // Store blob URL for web
  bool _isLoading = false;

  // Re-using colors for consistency
  static const Color kGreen700 = Color(0xFF2D6A4F);
  static const Color kGreen500 = Color(0xFF40916C);
  static const Color kGreen100 = Color(0xFFD8F3DC);
  static const Color kBg = Color(0xFFE8F5E9);
  static const Color kCard = Colors.white;
  static const Color kRed = Color(0xFFE63946);
  static const Color kTextPrimary = Color(0xFF1B262C);

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _webImagePath = pickedFile.path;
        } else {
          _profileImage = File(pickedFile.path);
        }
      });
    }
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final farmer = Farmer(
        name: _nameController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        mobile: _mobileController.text.isEmpty ? null : _mobileController.text,
        location: _locationController.text,
        profilePhotoPath: kIsWeb ? _webImagePath : _profileImage?.path,
        password: _passwordController.text,
      );

      final error = AuthService().register(farmer);

      setState(() => _isLoading = false);

      if (error == null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n('user_exists')),
            backgroundColor: kRed,
          ),
        );
      }
    } else if (_emailController.text.isEmpty &&
        _mobileController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n('email_mobile_required')),
          backgroundColor: kRed,
        ),
      );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.eco_rounded, color: kGreen700, size: 64),
                const SizedBox(height: 16),
                Text(
                  context.l10n('register'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Circular Profile Image Picker
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: kGreen700, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                kIsWeb
                                    ? (_webImagePath != null
                                        ? NetworkImage(_webImagePath!)
                                        : null)
                                    : (_profileImage != null
                                        ? FileImage(_profileImage!)
                                        : null),
                            child:
                                (kIsWeb
                                        ? _webImagePath == null
                                        : _profileImage == null)
                                    ? const Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 40,
                                      color: kGreen700,
                                    )
                                    : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: kGreen700,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                _buildTextField(
                  controller: _nameController,
                  label: context.l10n('full_name'),
                  icon: Icons.person_outline,
                  validator:
                      (v) => v!.isEmpty ? context.l10n('enter_name') : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: context.l10n('email'),
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _mobileController,
                  label: context.l10n('mobile'),
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: context.l10n('location'),
                  icon: Icons.location_on_outlined,
                  validator:
                      (v) => v!.isEmpty ? context.l10n('enter_location') : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: context.l10n('password'),
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator:
                      (v) =>
                          v!.length < 6 ? context.l10n('password_short') : null,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen500,
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
                            context.l10n('register'),
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
                          builder: (context) => const LoginScreen(),
                        ),
                      ),
                  child: Text(
                    context.l10n('already_account'),
                    style: const TextStyle(color: kGreen300),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: kTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kTextSecondary),
        prefixIcon: Icon(icon, color: kGreen700),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kGreen700, width: 2),
        ),
      ),
    );
  }
}
