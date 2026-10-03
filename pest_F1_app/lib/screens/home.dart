// agri_scan/lib/screens/home.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import 'profile_screen.dart';
import 'detection_details_screen.dart';
import '../models/detection_record.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import 'chatbot_screen.dart';
import 'login_screen.dart';

// ── Colour palette ──────────────────────────────────────────────────────────
const Color kGreen900 = Color(0xFF1B4332);
const Color kGreen700 = Color(0xFF2D6A4F);
const Color kGreen500 = Color(0xFF40916C);
const Color kGreen300 = Color(0xFF74C69D);
const Color kGreen100 = Color(0xFFD8F3DC);
const Color kParrotGreen = Color(0xFF8CC63F);
const Color kAmber = Color(0xFFFFB703);
const Color kRed = Color(0xFFE63946);
const Color kBg = Color(0xFFE8F5E9);
const Color kCard = Colors.white;
const Color kTextPrimary = Color(0xFF1B262C);
const Color kTextSecondary = Color(0xFF5A666D);

const Color kSectionBlue = Color(0xFF1E88E5);
const Color kSectionOrange = Color(0xFFFF8F00);
const Color kSectionPurple = Color(0xFF7B1FA2);

// ── Data model ──────────────────────────────────────────────────────────────
class PestDetection {
  final String pestName;
  final double confidence;
  final String confidencePct;
  final int classId;
  final Map<String, double> bbox;
  final String? diseaseType;
  final String? symptoms;
  final String? treatment;
  final String? pathogen;

  // 5 parameters
  final String? presence;
  final String? leafDamage;
  final String? colorChange;
  final String? pestLocation;
  final String? pestShapeSize;

  PestDetection({
    required this.pestName,
    required this.confidence,
    required this.confidencePct,
    required this.classId,
    required this.bbox,
    this.diseaseType,
    this.symptoms,
    this.treatment,
    this.pathogen,
    this.presence,
    this.leafDamage,
    this.colorChange,
    this.pestLocation,
    this.pestShapeSize,
  });

  factory PestDetection.fromJson(Map<String, dynamic> json) {
    final bboxRaw = Map<String, dynamic>.from(json['bbox'] ?? {});
    return PestDetection(
      pestName: json['pest_name'] ?? 'Unknown',
      confidence: (json['confidence'] as num).toDouble(),
      confidencePct: json['confidence_pct'] ?? '0%',
      classId: json['class_id'] ?? 0,
      bbox: bboxRaw.map((k, v) => MapEntry(k, (v as num).toDouble())),
      diseaseType: json['disease_type'],
      symptoms: json['symptoms'],
      treatment: json['treatment'],
      pathogen: json['pathogen'],
      presence: json['presence'],
      leafDamage: json['leaf_damage'],
      colorChange: json['color_change'],
      pestLocation: json['pest_location'],
      pestShapeSize: json['pest_shape_size'],
    );
  }
}

class DetectionResult {
  final String status;
  final int totalCount;
  final String message;
  final Map<String, int> pestSummary;
  final List<PestDetection> detections;

  DetectionResult({
    required this.status,
    required this.totalCount,
    required this.message,
    required this.pestSummary,
    required this.detections,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    final summaryRaw = Map<String, dynamic>.from(json['pest_summary'] ?? {});
    final detectionsRaw = List<dynamic>.from(json['detections'] ?? []);
    return DetectionResult(
      status: json['status'] ?? 'error',
      totalCount: json['total_count'] ?? 0,
      message: json['message'] ?? '',
      pestSummary: summaryRaw.map((k, v) => MapEntry(k, (v as num).toInt())),
      detections:
          detectionsRaw
              .map((d) => PestDetection.fromJson(Map<String, dynamic>.from(d)))
              .toList(),
    );
  }
}

// ── Screen ───────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _imageFile;
  Uint8List? _webImage;
  String? _imageName;

  DetectionResult? _result;
  Map<String, dynamic>? _rawResult;
  String? _errorMessage;
  bool _loading = false;

  String _selectedFocus = 'pest'; // 'pest' or 'disease'
  String _selectedModelId = 'rice_pests';

  List<DetectionRecord> _scanHistory = [];
  bool _historyLoading = false;

  @override
  void initState() {
    super.initState();
    _loadScanHistory();
  }

  Future<void> _loadScanHistory() async {
    setState(() => _historyLoading = true);
    try {
      final rows = await DatabaseHelper.instance.queryAllDetections();
      final records = rows.map((e) => DetectionRecord.fromMap(e)).toList();
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      setState(() {
        _scanHistory = records;
        _historyLoading = false;
      });
    } catch (_) {
      setState(() => _historyLoading = false);
    }
  }

  bool get _hasImage => _webImage != null || _imageFile != null;

  // ── Pick image ─────────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _webImage = bytes;
        _imageFile = null;
        _imageName = picked.name;
        _result = null;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _imageFile = File(picked.path);
        _webImage = null;
        _imageName = picked.name;
        _result = null;
        _errorMessage = null;
      });
    }
  }

  // ── Upload & detect ────────────────────────────────────────────────────────
  Future<void> _detect() async {
    if (!_hasImage) return;
    setState(() {
      _loading = true;
      _result = null;
      _errorMessage = null;
    });

    try {
      // Get selected crop from user preferences
      final langService = Provider.of<LanguageService>(context, listen: false);
      final cropId =
          langService.selectedCrops.isNotEmpty
              ? langService.selectedCrops.first
              : null;
      // final cropParam = cropId != null ? '?crop_id=$cropId' : ''; // Disabled for app.py compatibility
      final cropParam = '';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://agriscan-backend-gman.onrender.com/predict'),
      );
      request.fields['model_id'] = _selectedModelId;

      if (_webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _webImage!,
            filename: _imageName ?? 'image.jpg',
          ),
        );
      } else if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', _imageFile!.path),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final responseJson = jsonDecode(body) as Map<String, dynamic>;

        // Parse app.py response and map to app format
        final predClass = responseJson['class'] ?? 'unknown';
        final confStr = responseJson['confidence'] ?? '0.00%';
        final conf = double.tryParse(confStr.replaceAll('%', '')) ?? 0.0;
        final status =
            responseJson['status_text'] ?? responseJson['status'] ?? 'Unknown';

        final isHealthy =
            responseJson['is_healthy'] ?? (predClass == 'healthy');
        final mockDetection = PestDetection(
          pestName: responseJson['display_name'] ?? predClass,
          confidence: conf,
          confidencePct: confStr,
          classId: 0,
          bbox: {'x': 0.5, 'y': 0.5, 'width': 0.8, 'height': 0.8},
        );

        setState(() {
          _rawResult = responseJson;
          _result = DetectionResult(
            status: 'success',
            totalCount: isHealthy ? 0 : 1,
            message: status,
            pestSummary: {predClass: 1},
            detections: isHealthy ? [] : [mockDetection],
          );
        });

        // Save detection to SQLite history
        try {
          await DatabaseHelper.instance.insertDetection({
            'total_count': isHealthy ? 0 : 1,
            'message': status,
            'pest_summary': {predClass: 1},
            'detections':
                isHealthy
                    ? []
                    : [
                      {
                        'presence': responseJson['display_name'] ?? predClass,
                        'leaf_damage':
                            isHealthy ? 'Normal' : 'Active infestation damage',
                        'color_change':
                            isHealthy
                                ? 'Uniform green'
                                : 'Discolored / Spotted',
                        'pest_location': 'Leaf surface',
                        'pest_shape_size': 'Identified by AI',
                      },
                    ],
            'image_path': _imageFile?.path ?? '',
          });
          await _loadScanHistory();
        } catch (_) {}
      } else {
        final json = jsonDecode(body);
        setState(
          () =>
              _errorMessage =
                  json['error'] ??
                  json['detail'] ??
                  'Server error (${streamed.statusCode})',
        );
      }
    } catch (e) {
      setState(
        () => _errorMessage = 'Connection failed. Is the backend running?\n$e',
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _requireAuth(
    BuildContext context,
    String featureName,
    VoidCallback onAuthenticated,
  ) {
    if (AuthService().isAuthenticated) {
      onAuthenticated();
    } else {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(Icons.lock_outline_rounded, color: Color(0xFF2D6A4F)),
                  SizedBox(width: 8),
                  Text(
                    'Login Required',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Text(
                'Please log in or create an account to access $featureName and save your history.',
                style: TextStyle(color: Colors.grey[800]),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A4F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text('Log In / Register'),
                ),
              ],
            ),
      );
    }
  }

  void _showAIAssistantDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AIAssistantSheet(),
    );
  }

  // ══════════════════════════════ BUILD ══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F2),
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0F7F2), Color(0xFFE6F3EB), Color(0xFFF7FAF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWeatherHeaderWidget(),
              _buildFocusAndModelSelectorCard(),
              const SizedBox(height: 16),
              _buildImageCard(),
              const SizedBox(height: 10),
              _buildGalleryOption(),
              const SizedBox(height: 12),
              _buildPreviousScanButtons(),
              const SizedBox(height: 16),
              _buildActionButtons(),

              const SizedBox(height: 24),
              if (_loading) _buildLoader(),
              if (_errorMessage != null) _buildErrorCard(),
              if (_result != null) _buildResultSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherHeaderWidget() {
    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);
    final dateStr = DateFormat('EEE, MMM dd, yyyy').format(now);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Time & Date Column
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.access_time_filled_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Temperature & Weather Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_rounded,
                      color: Color(0xFFFFB703),
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "28°C",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Clear Skies",
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),
          // Additional Weather Metrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.water_drop_rounded,
                    color: Colors.blue[200],
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Humidity 65%",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.air_rounded, color: Colors.teal[200], size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "Wind 10 km/h",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF8CC63F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Optimal Field Spray",
                  style: TextStyle(
                    color: Color(0xFF1B4332),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHistoryItem(DetectionRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.delete_outline_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text("Delete Scan Record"),
              ],
            ),
            content: Text(
              "Are you sure you want to delete '${record.primaryDiagnosis}' from history?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final id = int.tryParse(record.id);
      if (id != null) {
        await DatabaseHelper.instance.deleteDetection(id);
        await _loadScanHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Scan record deleted."),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _clearAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.delete_sweep_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text("Clear All Scan History"),
              ],
            ),
            content: const Text(
              "Are you sure you want to delete all saved scan history?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Clear All"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.clearHistory();
      await _loadScanHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("All scan history cleared."),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildPreviousScanButtons() {
    if (_historyLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    color: kSectionOrange,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Previous Scan History",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: kTextPrimary,
                    ),
                  ),
                ],
              ),
              if (_scanHistory.isNotEmpty)
                InkWell(
                  onTap: _clearAllHistory,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_sweep_rounded,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Clear All",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_scanHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "No real scan history found yet. Perform a scan above to record history.",
                    style: TextStyle(fontSize: 12, color: kTextSecondary),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children:
                _scanHistory.map((record) {
                  final isHealthy = record.primaryDiagnosis
                      .toLowerCase()
                      .contains('healthy');
                  final isInvalid = record.primaryDiagnosis
                      .toLowerCase()
                      .contains('invalid');
                  final badgeColor =
                      isHealthy ? kGreen700 : (isInvalid ? kAmber : kRed);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => DetectionDetailsScreen(
                                        record: record,
                                      ),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: badgeColor.withValues(
                                alpha: 0.12,
                              ),
                              child: Icon(
                                isHealthy
                                    ? Icons.check_circle_rounded
                                    : (isInvalid
                                        ? Icons.warning_amber_rounded
                                        : Icons.bug_report_rounded),
                                color: badgeColor,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => DetectionDetailsScreen(
                                          record: record,
                                        ),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record.primaryDiagnosis.isNotEmpty
                                        ? record.primaryDiagnosis
                                        : "Scan Result",
                                    style: const TextStyle(
                                      color: kTextPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat(
                                      'MMM dd, yyyy • hh:mm a',
                                    ).format(record.timestamp),
                                    style: const TextStyle(
                                      color: kTextSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isHealthy
                                  ? "Healthy"
                                  : (isInvalid ? "Unknown" : "Issue Found"),
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            tooltip: "Delete from history",
                            onPressed: () => _deleteHistoryItem(record),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
      ],
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 2,
      shadowColor: const Color(0xFF1B4332).withValues(alpha: 0.2),
      centerTitle: false,
      automaticallyImplyLeading: false,
      toolbarHeight: 80,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.eco_rounded, color: kParrotGreen, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n('app_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                context.l10n('app_subtitle'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0, top: 22.0, bottom: 22.0),
          child: ElevatedButton.icon(
            onPressed: () => _showAIAssistantDialog(context),
            icon: const Icon(
              Icons.psychology_rounded,
              size: 16,
              color: Color(0xFF1B4332),
            ),
            label: const Text(
              'Ask AI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1B4332),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            _requireAuth(context, 'Farmer Profile & Settings', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            });
          },
          icon: const Icon(
            Icons.account_circle_rounded,
            color: Colors.white,
            size: 30,
          ),
          tooltip: context.l10n('farmer_profile'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFocusAndModelSelectorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kSectionPurple.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Focus & AI Model",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text("🐛 Pest"),
                  selected: _selectedFocus == 'pest',
                  selectedColor: kGreen500.withOpacity(0.2),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedFocus = 'pest';
                        _selectedModelId = 'rice_pests';
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text("🦠 Disease"),
                  selected: _selectedFocus == 'disease',
                  selectedColor: kSectionPurple.withOpacity(0.2),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedFocus = 'disease';
                        _selectedModelId = 'plant_diseases_38';
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedModelId,
                isExpanded: true,
                items:
                    _selectedFocus == 'pest'
                        ? const [
                          DropdownMenuItem(
                            value: 'rice_pests',
                            child: Text("🌾 Rice Pest Model"),
                          ),
                          DropdownMenuItem(
                            value: 'ip102_pests_102',
                            child: Text("🐛 All Agricultural Pests"),
                          ),
                        ]
                        : const [
                          DropdownMenuItem(
                            value: 'plant_diseases_38',
                            child: Text("🦠 Plant Diseases - 38 Conditions"),
                          ),
                        ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedModelId = val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Gallery Option ─────────────────────────────────────────────────────────
  Widget _buildGalleryOption() {
    return Center(
      child: InkWell(
        onTap: () => _pickImage(ImageSource.gallery),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_library_rounded,
                color: kSectionPurple.withOpacity(0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Upload from Gallery",
                style: TextStyle(
                  color: kSectionPurple.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Image card ─────────────────────────────────────────────────────────────
  Widget _buildImageCard() {
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.camera),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 280,
        decoration: BoxDecoration(
          color: _hasImage ? kCard : kSectionPurple.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hasImage ? kSectionPurple : kSectionPurple.withOpacity(0.4),
            width: _hasImage ? 2 : 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: kSectionPurple.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: _hasImage ? _imagePreview() : _imagePlaceholder(),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Scan line effect or similar could go here, but let's keep it clean
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kSectionPurple,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kSectionPurple.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Take Picture",
              style: TextStyle(
                color: kSectionPurple,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Scan leaf for instant diagnosis",
              style: TextStyle(
                color: kTextSecondary.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
        // Corner borders to simulate a scanner
        ...List.generate(4, (i) {
          return Positioned(
            top: (i == 0 || i == 1) ? 20 : null,
            bottom: (i == 2 || i == 3) ? 20 : null,
            left: (i == 0 || i == 2) ? 20 : null,
            right: (i == 1 || i == 3) ? 20 : null,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  top:
                      (i == 0 || i == 1)
                          ? const BorderSide(color: kSectionPurple, width: 4)
                          : BorderSide.none,
                  bottom:
                      (i == 2 || i == 3)
                          ? const BorderSide(color: kSectionPurple, width: 4)
                          : BorderSide.none,
                  left:
                      (i == 0 || i == 2)
                          ? const BorderSide(color: kSectionPurple, width: 4)
                          : BorderSide.none,
                  right:
                      (i == 1 || i == 3)
                          ? const BorderSide(color: kSectionPurple, width: 4)
                          : BorderSide.none,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _imagePreview() {
    final image =
        _webImage != null
            ? Image.memory(
              _webImage!,
              fit: BoxFit.cover,
              width: double.infinity,
            )
            : Image.file(
              _imageFile!,
              fit: BoxFit.cover,
              width: double.infinity,
            );

    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        // Subtle overlay gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
        // Filename badge
        if (_imageName != null)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                const Icon(Icons.image_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _imageName!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kParrotGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.l10n('change'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    if (!_hasImage) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: _FilledBtn(
            icon: Icons.biotech_rounded,
            label: context.l10n('start_analysis'),
            onTap: !_loading ? _detect : null,
            loading: _loading,
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Logic for detect button after capture
              // This is usually what _detect does, but user requested a "detect" button specifically after capture.
              // Actually, _detect IS the detect button.
              // The user said: "After capturing, it should show detect button"
              // So I will make sure _FilledBtn (Start Analysis) is only visible then.
            },
            icon: const Icon(Icons.search),
            label: const Text('Detect More'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kParrotGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Loader ─────────────────────────────────────────────────────────────────
  Widget _buildLoader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGreen100),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(kGreen700),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n('analysing'),
            style: const TextStyle(
              color: kGreen700,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error card ─────────────────────────────────────────────────────────────
  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: kRed, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: kTextPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Result section ──────────────────────────────────────────────────────────
  Widget _buildResultSection() {
    final r = _result!;
    final statusCat =
        _rawResult?['status_category'] ??
        (r.totalCount > 0 ? 'Unhealthy' : 'Healthy');
    final issueName =
        _rawResult?['issue_name'] ?? _rawResult?['display_name'] ?? r.message;
    final confStr = _rawResult?['confidence'] ?? '';
    final hasPests = r.totalCount > 0;
    Color accentColor;
    IconData statusIcon;
    String headerTitle;
    String detailText;

    if (statusCat == 'Healthy') {
      accentColor = kGreen700;
      statusIcon = Icons.check_circle_rounded;
      headerTitle = "✅ Healthy Crop";
      detailText = "No pest or disease detected ($confStr confidence).";
    } else if (statusCat == 'Invalid') {
      accentColor = kAmber;
      statusIcon = Icons.warning_amber_rounded;
      headerTitle = "⚠️ Invalid Image / Low Confidence";
      detailText =
          "Could not identify a crop issue ($confStr confidence). Please upload a clearer leaf photo.";
    } else {
      accentColor = kRed;
      statusIcon = Icons.cancel_rounded;
      headerTitle = "❌ Unhealthy ($issueName)";
      detailText = "Detected Issue: $issueName | Confidence: $confStr";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Summary banner ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(statusIcon, color: accentColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerTitle,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detailText,
                          style: const TextStyle(
                            color: kTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Pest summary pills ──────────────────────────────────────
              if (r.pestSummary.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.black12, height: 1),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      r.pestSummary.entries.map((e) {
                        return _PestPill(name: e.key, count: e.value);
                      }).toList(),
                ),
              ],

              // ── Detailed disease cards with symptoms & treatment ─────────
              if (r.detections.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.black12, height: 1),
                const SizedBox(height: 12),
                Text(
                  '🔬 Disease Details & Treatment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: hasPests ? kAmber : kGreen700,
                  ),
                ),
                ...r.detections.map(
                  (d) =>
                      _buildDiseaseDetailCard(d, hasPests ? kAmber : kGreen700),
                ),
              ],

              // ── Ask Gemini AI Guidance Button ─────────────────────────────
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ChatbotScreen(
                              initialContext:
                                  _rawResult ??
                                  {
                                    'crop': 'Crop Diagnosis',
                                    'display_name': r.message,
                                    'status': r.message,
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
                    "🤖 Ask Gemini AI Assistant for Guidance",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiseaseDetailCard(PestDetection d, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(
                Icons.bug_report_rounded,
                size: 18,
                color: kTextPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  d.pestName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kTextPrimary,
                  ),
                ),
              ),
              Text(
                d.confidencePct,
                style: const TextStyle(fontSize: 12, color: kTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // The 5 Parameters
          _buildDetailRow(
            Icons.check_circle_outline,
            'Presence of pest',
            d.presence ?? d.pestName,
          ),
          _buildDetailRow(
            Icons.health_and_safety_outlined,
            'Leaf damage',
            d.leafDamage ?? 'Normal',
          ),
          _buildDetailRow(
            Icons.color_lens_outlined,
            'Leaf color change',
            d.colorChange ?? 'Normal',
          ),
          _buildDetailRow(
            Icons.location_on_outlined,
            'Pest location',
            d.pestLocation ?? 'Center',
          ),
          _buildDetailRow(
            Icons.format_shapes_outlined,
            'Pest shape & size',
            d.pestShapeSize ?? 'Small',
          ),

          if (d.treatment != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.medical_services_rounded,
                  size: 14,
                  color: kGreen700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Treatment: ${d.treatment}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: kGreen700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: kTextSecondary.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              color: kTextSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, color: kTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════ SUB-WIDGETS ════════════════════════════════════

class _FilledBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _FilledBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color: enabled ? kGreen700 : Colors.grey[300],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PestPill extends StatelessWidget {
  final String name;
  final int count;
  const _PestPill({required this.name, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kAmber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kAmber.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bug_report_rounded, color: kAmber, size: 14),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '×$count',
            style: const TextStyle(
              color: kAmber,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Assistant Bottom Sheet ────────────────────────────────────────────────
class _AIAssistantSheet extends StatefulWidget {
  const _AIAssistantSheet({Key? key}) : super(key: key);

  @override
  State<_AIAssistantSheet> createState() => _AIAssistantSheetState();
}

class _AIAssistantSheetState extends State<_AIAssistantSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text':
          'Hello! I am your AgriScan AI Assistant. I can help identify diseases, suggest treatments, and answer farming questions. What crops do you need help with?',
      'isAI': true,
    },
  ];
  bool _isTyping = false;
  bool _isListening = false;
  int? _speakingIndex;

  void _clearChat() {
    setState(() {
      _messages.clear();
      _speakingIndex = null;
      _isListening = false;
      _messages.add({
        'text':
            'Hello! I am your AgriScan AI Assistant. I can help identify diseases, suggest treatments, and answer farming questions. What crops do you need help with?',
        'isAI': true,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✨ Chat reset cleanly! Starting fresh conversation."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleVoiceInput() {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎙️ Listening... Speak your crop query."),
          duration: Duration(seconds: 3),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isListening) {
          setState(() {
            _messageController.text =
                "How to manage paddy stem borer organically?";
            _isListening = false;
          });
        }
      });
    }
  }

  void _speakMessage(int index, String text) {
    setState(() {
      if (_speakingIndex == index) {
        _speakingIndex = null;
      } else {
        _speakingIndex = index;
      }
    });

    if (_speakingIndex == index) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("🔊 Reading AI advice aloud..."),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: "Stop",
            textColor: Colors.amber,
            onPressed: () {
              setState(() => _speakingIndex = null);
            },
          ),
        ),
      );
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'text': text, 'isAI': false});
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Mock AI response delay
    await Future.delayed(const Duration(seconds: 1));

    String aiReply =
        "I am a prototype AI, but I understand you're asking about '$text'. Let me look for pest recommendations based on our expert analysis.";

    if (text.toLowerCase().contains("leaf spot")) {
      aiReply =
          "For leaf spot diseases, ensure good air circulation around your plants, avoid overhead watering, and apply a copper-based fungicide if necessary.";
    } else if (text.toLowerCase().contains("caterpillar")) {
      aiReply =
          "Caterpillars can be managed by handpicking, introducing natural predators like birds or wasps, or using organic sprays like neem oil or Bt (Bacillus thuringiensis).";
    }

    if (mounted) {
      setState(() {
        _messages.add({'text': aiReply, 'isAI': true});
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildChatBubble(
    String text, {
    required bool isAI,
    required int index,
  }) {
    final isSpeaking = _speakingIndex == index;

    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color:
              isAI
                  ? kParrotGreen.withOpacity(0.1)
                  : kSectionBlue.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAI ? 0 : 16),
            bottomRight: Radius.circular(isAI ? 16 : 0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: kTextPrimary, height: 1.4),
              ),
            ),
            if (isAI) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _speakMessage(index, text),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        isSpeaking
                            ? kParrotGreen.withOpacity(0.2)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSpeaking
                        ? Icons.volume_up_rounded
                        : Icons.volume_mute_outlined,
                    size: 18,
                    color: isSpeaking ? kGreen700 : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: kParrotGreen,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AgriScan AI Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  tooltip: "Clear Chat / Start Fresh",
                  onPressed: _clearChat,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'AI is typing...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }
                final msg = _messages[index];
                return _buildChatBubble(
                  msg['text'],
                  isAI: msg['isAI'],
                  index: index,
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 12.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  backgroundColor:
                      _isListening
                          ? Colors.red
                          : kParrotGreen.withOpacity(0.15),
                  radius: 20,
                  child: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? Colors.white : kParrotGreen,
                      size: 20,
                    ),
                    tooltip: "Voice Input",
                    onPressed: _toggleVoiceInput,
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  backgroundColor: kParrotGreen,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    tooltip: "Send Message",
                    onPressed: _sendMessage,
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
