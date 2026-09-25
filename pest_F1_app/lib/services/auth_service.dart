// lib/services/auth_service.dart
import '../models/farmer.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Farmer? _currentUser;
  final List<Farmer> _registeredFarmers = [];

  Farmer? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  String? register(Farmer farmer) {
    // Check if identifier already exists
    if (_registeredFarmers.any(
      (f) =>
          (f.email != null && f.email == farmer.email) ||
          (f.mobile != null && f.mobile == farmer.mobile),
    )) {
      return "User already exists with this email or mobile number.";
    }

    _registeredFarmers.add(farmer);
    _currentUser = farmer;
    return null; // Success
  }

  String? login(String identifier, String password) {
    try {
      final farmer = _registeredFarmers.firstWhere(
        (f) =>
            (f.email == identifier || f.mobile == identifier) &&
            f.password == password,
      );
      _currentUser = farmer;
      return null; // Success
    } catch (_) {
      return "Invalid email/mobile or password.";
    }
  }

  void logout() {
    _currentUser = null;
  }
}
