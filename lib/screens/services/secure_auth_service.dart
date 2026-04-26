import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecureAuthService {
  static final _storage = const FlutterSecureStorage();
  static final _auth = LocalAuthentication();

  /// Save login credentials (email + password)
  static Future<void> saveLoginCredentials(String identifier, String password) async {
    await _storage.write(key: 'identifier', value: identifier);
    await _storage.write(key: 'password', value: password);
    print(identifier);
    print(password);
  }

  /// Retrieve login credentials (only after biometric check)
  static Future<Map<String, String>?> getLoginCredentials() async {
    final isAuthenticated = await _authenticateUser("Authenticate to login");
    if (!isAuthenticated) return null;

    final identifier = await _storage.read(key: 'identifier');
    final password = await _storage.read(key: 'password');
    if (identifier == null || password == null) return null;
    print(identifier);

    return {"identifier": identifier, "password": password};
  }

  static Future<Map<String, String>?> getStoredLoginCredentials() async {
    final identifier = await _storage.read(key: 'identifier');
    final password = await _storage.read(key: 'password');
    if (identifier == null || password == null) return null;

    return {"identifier": identifier, "password": password};
  }

  /// Save transaction PIN
  static Future<void> saveTransactionPin(String pin) async {
    await _storage.write(key: 'transaction_pin', value: pin);
  }

  /// Retrieve transaction PIN (after biometric check)
  static Future<String?> getTransactionPin() async {
    return await _storage.read(key: 'transaction_pin');
  }

  /// Clear all stored data (for logout/reset)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Biometric authentication
  static Future<bool> _authenticateUser(String reason) async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      print("Biometric error: $e");
      return false;
    }
  }
}
