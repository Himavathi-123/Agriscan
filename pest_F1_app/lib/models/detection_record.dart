import 'dart:convert';

class DetectionRecord {
  final String id;
  final DateTime timestamp;
  final String imageUrl;
  final String primaryDiagnosis;
  final double damagePercentage;

  // 5 Detailed Parameters
  final String pestPresence; // 1. Presence of pest
  final String leafDamage; // 2. Leaf damage
  final String colorChange; // 3. Leaf color change
  final String pestLocation; // 4. Pest location on leaf
  final String pestShapeSize; // 5. Pest shape and size

  DetectionRecord({
    required this.id,
    required this.timestamp,
    required this.imageUrl,
    required this.primaryDiagnosis,
    required this.damagePercentage,
    required this.pestPresence,
    required this.leafDamage,
    required this.colorChange,
    required this.pestLocation,
    required this.pestShapeSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
      'primaryDiagnosis': primaryDiagnosis,
      'damagePercentage': damagePercentage,
      'pestPresence': pestPresence,
      'leafDamage': leafDamage,
      'colorChange': colorChange,
      'pestLocation': pestLocation,
      'pestShapeSize': pestShapeSize,
    };
  }

  factory DetectionRecord.fromMap(Map<String, dynamic> map) {
    // Attempt to extract from the first detection in detectionsJson if available
    Map<String, dynamic>? firstDetection;
    if (map['detectionsJson'] != null) {
      try {
        final List<dynamic> detections = jsonDecode(map['detectionsJson']);
        if (detections.isNotEmpty) {
          firstDetection = detections.first as Map<String, dynamic>;
        }
      } catch (_) {}
    }

    return DetectionRecord(
      id: map['id']?.toString() ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      imageUrl: map['imageUrl'] ?? map['localImagePath'] ?? '',
      primaryDiagnosis: map['primaryDiagnosis'] ?? map['message'] ?? '',
      damagePercentage:
          (map['damagePercentage'] as num?)?.toDouble() ??
          (map['totalCount'] as num?)?.toDouble() ??
          0.0,
      pestPresence:
          map['pestPresence'] ??
          firstDetection?['presence'] ??
          map['pest_name'] ??
          'None',
      leafDamage:
          map['leafDamage'] ?? firstDetection?['leaf_damage'] ?? 'Normal',
      colorChange:
          map['colorChange'] ?? firstDetection?['color_change'] ?? 'Normal',
      pestLocation:
          map['pestLocation'] ?? firstDetection?['pest_location'] ?? 'Unknown',
      pestShapeSize:
          map['pestShapeSize'] ??
          firstDetection?['pest_shape_size'] ??
          'Unknown',
    );
  }

  String get severity {
    if (damagePercentage < 10) return "Mild";
    if (damagePercentage < 30) return "Moderate";
    return "Severe";
  }
}
