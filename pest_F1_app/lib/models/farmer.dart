// lib/models/farmer.dart

class Farmer {
  final String name;
  final String? email;
  final String? mobile;
  final String location;
  final String? profilePhotoPath;
  final String password;

  Farmer({
    required this.name,
    this.email,
    this.mobile,
    required this.location,
    this.profilePhotoPath,
    required this.password,
  });

  String get identifier => email ?? mobile ?? '';
}
