// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';
import 'language_selection_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color kGreen700 = Color(0xFF2D6A4F);
  static const Color kGreen500 = Color(0xFF40916C);
  static const Color kParrotGreen = Color(0xFF8CC63F);
  static const Color kGreen100 = Color(0xFFD8F3DC);
  static const Color kBg = Color(0xFFE8F5E9);
  static const Color kCard = Colors.white;
  static const Color kTextPrimary = Color(0xFF1B262C);

  @override
  Widget build(BuildContext context) {
    final farmer = AuthService().currentUser;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          context.l10n('farmer_profile'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          farmer == null
              ? Center(
                child: Text(
                  context.l10n('not_provided'),
                  style: const TextStyle(color: kTextPrimary),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Circular Profile Photo with Border
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kParrotGreen, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: kGreen700.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            farmer.profilePhotoPath != null
                                ? (kIsWeb
                                    ? NetworkImage(farmer.profilePhotoPath!)
                                    : FileImage(File(farmer.profilePhotoPath!))
                                        as ImageProvider)
                                : null,
                        child:
                            farmer.profilePhotoPath == null
                                ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.lightGreenAccent,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      farmer.name,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n('farmer_label'),
                      style: const TextStyle(
                        color: kGreen500,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            Icons.email_outlined,
                            context.l10n('email'),
                            farmer.email ?? context.l10n('not_provided'),
                          ),
                          const Divider(color: Color(0xFFEEEEEE), height: 32),
                          _buildDetailRow(
                            Icons.phone_android_outlined,
                            context.l10n('mobile'),
                            farmer.mobile ?? context.l10n('not_provided'),
                          ),
                          const Divider(color: Color(0xFFEEEEEE), height: 32),
                          _buildDetailRow(
                            Icons.location_on_outlined,
                            context.l10n('location'),
                            farmer.location,
                          ),
                          const Divider(color: Color(0xFFEEEEEE), height: 32),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const LanguageSelectionScreen(),
                                ),
                              );
                            },
                            child: _buildDetailRow(
                              Icons.translate_rounded,
                              context.l10n('language'),
                              context.l10n('change_language'),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          AuthService().logout();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(
                          Icons.logout,
                          color: Color(0xFFE63946),
                        ),
                        label: Text(
                          context.l10n('logout'),
                          style: const TextStyle(color: Color(0xFFE63946)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE63946)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kParrotGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kParrotGreen, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
