import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static SupabaseClient get _db => Supabase.instance.client;

  static const _keyId = 'user_id';
  static const _keyRole = 'user_role';
  static const _keyName = 'user_name';
  static const _keyEmail = 'user_email';

  static String _hashPassword(String email, String password) {
    final bytes = utf8.encode('${email.toLowerCase()}$password');
    return sha256.convert(bytes).toString();
  }

  // ── Session helpers ────────────────────────────────────────────────────────

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyId) != null;
  }

  static Future<String?> currentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  static Future<String?> currentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyId);
  }

  static Future<String?> currentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<void> _saveSession(Map<String, dynamic> account) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyId, account['id'] as String);
    await prefs.setString(_keyRole, account['role'] as String);
    await prefs.setString(_keyName, (account['full_name'] as String?) ?? '');
    await prefs.setString(_keyEmail, (account['email'] as String?) ?? '');
  }

  static Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyId);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
  }

  // ── Passenger ──────────────────────────────────────────────────────────────

  static Future<void> signUpPassenger({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    String address = '',
    String dateOfBirth = '',
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Check for duplicate email
    final existing = await _db
        .from('accounts')
        .select('id')
        .eq('email', normalizedEmail)
        .maybeSingle();
    if (existing != null) {
      throw Exception('An account with this email already exists.');
    }

    final hash = _hashPassword(normalizedEmail, password);
    final fullName = '${firstName.trim()} ${lastName.trim()}';

    final row = await _db
        .from('accounts')
        .insert({
          'full_name': fullName,
          'email': normalizedEmail,
          'password_hash': hash,
          'phone': phone.trim(),
          'address': address.trim(),
          'date_of_birth': dateOfBirth.isEmpty ? null : dateOfBirth,
          'role': 'passenger',
        })
        .select()
        .single();

    await _saveSession(row);
  }

  static Future<void> signInPassenger({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final hash = _hashPassword(normalizedEmail, password);

    final row = await _db
        .from('accounts')
        .select()
        .eq('email', normalizedEmail)
        .eq('password_hash', hash)
        .maybeSingle();

    if (row == null) throw Exception('Invalid email or password.');
    if (row['role'] != 'passenger') {
      throw Exception('This is a driver account. Please use the driver login.');
    }

    await _saveSession(row);
  }

  // ── Driver ─────────────────────────────────────────────────────────────────

  static Future<void> signUpDriver({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final existing = await _db
        .from('accounts')
        .select('id')
        .eq('email', normalizedEmail)
        .maybeSingle();
    if (existing != null) {
      throw Exception('An account with this email already exists.');
    }

    final hash = _hashPassword(normalizedEmail, password);
    final fullName = '${firstName.trim()} ${lastName.trim()}';

    final row = await _db
        .from('accounts')
        .insert({
          'full_name': fullName,
          'email': normalizedEmail,
          'password_hash': hash,
          'phone': phone.trim(),
          'role': 'driver',
        })
        .select()
        .single();

    // Create driver_details row
    await _db.from('driver_details').insert({'id': row['id']});

    await _saveSession(row);
  }

  static Future<void> signInDriver({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final hash = _hashPassword(normalizedEmail, password);

    final row = await _db
        .from('accounts')
        .select()
        .eq('email', normalizedEmail)
        .eq('password_hash', hash)
        .maybeSingle();

    if (row == null) throw Exception('Invalid email or password.');
    if (row['role'] != 'driver') {
      throw Exception(
        'This is a passenger account. Please use the passenger login.',
      );
    }

    await _saveSession(row);
  }

  // ── Common ─────────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    await _clearSession();
  }
}
