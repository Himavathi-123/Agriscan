// lib/screens/detection_details_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/detection_record.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import 'chatbot_screen.dart';

class DetectionDetailsScreen extends StatelessWidget {
  final DetectionRecord record;

  const DetectionDetailsScreen({super.key, required this.record});

  static const Color kGreen700 = Color(0xFF2D6A4F);
  static const Color kGreen500 = Color(0xFF40916C);
  static const Color kBg = Color(0xFFE8F5E9); // Light Green Background
  static const Color kCard = Colors.white;
  static const Color kTextPrimary = Color(0xFF102A43); // Cool Dark Slate Text
  static const Color kTextSecondary = Color(0xFF334E68); // Cool Slate Text
  static const Color kRed = Color(0xFFE63946);
  static const Color kAmber = Color(0xFFFFB703);

  Color _getSeverityColor() {
    if (record.damagePercentage < 10) return kGreen500;
    if (record.damagePercentage < 30) return kAmber;
    return kRed;
  }

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    } else if (url.isNotEmpty && File(url).existsSync()) {
      return FileImage(File(url));
    } else {
      return const NetworkImage(
        'https://upload.wikimedia.org/wikipedia/commons/3/38/Leaf.jpg',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          context.l10n('analysis_results'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: _getImageProvider(record.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.primaryDiagnosis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      ).format(record.timestamp),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Severity Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: _getSeverityColor().withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: _getSeverityColor()),
                  const SizedBox(width: 12),
                  Text(
                    '${context.l10n('severity')}: ${context.l10n(record.severity.toLowerCase())} (${record.damagePercentage}%)',
                    style: TextStyle(
                      color: _getSeverityColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    context.l10n('damage_percentage'),
                    style: const TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),

            // 10 Parameters Grid
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n('detailed_analysis'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildParamTile(
                    Icons.bug_report_outlined,
                    'Presence of pest (insect)',
                    record.pestPresence,
                  ),
                  _buildParamTile(
                    Icons.health_and_safety_outlined,
                    'Leaf damage',
                    record.leafDamage,
                  ),
                  _buildParamTile(
                    Icons.color_lens_outlined,
                    'Leaf color change',
                    record.colorChange,
                  ),
                  _buildParamTile(
                    Icons.location_on_outlined,
                    'Pest location on leaf',
                    record.pestLocation,
                  ),
                  _buildParamTile(
                    Icons.format_shapes_outlined,
                    'Pest shape and size',
                    record.pestShapeSize,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChatbotScreen(
                                  initialContext: {
                                    'crop': 'Rice / Agriculture',
                                    'display_name': record.primaryDiagnosis,
                                    'status':
                                        'Damage: ${record.damagePercentage}%',
                                  },
                                ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Ask AI Assistant About This Result",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4332),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildParamTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kGreen700.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kGreen700, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
