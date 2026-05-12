import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_model.dart';
import '../models/landmark_model.dart';
import 'auth_service.dart';

class SupabaseService {
  static SupabaseClient get _db => Supabase.instance.client;

  static Future<List<RouteModel>> fetchRoutes() async {
    final data = await _db
        .from('routes')
        .select(
          'id, name, color, vehicle_type, description, hours, frequency, stops',
        )
        .or('status.eq.approved,status.is.null')
        .order('created_at', ascending: true);
    return (data as List)
        .map((json) => RouteModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<LandmarkModel>> fetchLandmarks() async {
    final data = await _db
        .from('landmarks')
        .select('id, name, lat, lng, category, address');
    return (data as List)
        .map((json) => LandmarkModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Fetch route by ID
  static Future<RouteModel?> fetchRouteById(String routeId) async {
    try {
      final data = await _db
          .from('routes')
          .select(
            'id, name, color, vehicle_type, description, hours, frequency, stops',
          )
          .eq('id', routeId)
          .or('status.eq.approved,status.is.null')
          .single();
      return RouteModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchProfile() async {
    final uid = await AuthService.currentUserId();
    if (uid == null) return null;
    try {
      return await _db.from('accounts').select().eq('id', uid).single();
    } catch (_) {
      return null;
    }
  }

  static Future<void> submitFeedbackForm({
    required String category,
    String name = '',
    required String description,
  }) async {
    await _db.from('feedback').insert({
      'category': category,
      'name': name.isEmpty ? null : name,
      'description': description,
    });
  }

  static Future<void> updateBenefitType(String benefitType) async {
    final uid = await AuthService.currentUserId();
    if (uid == null) return;
    await _db
        .from('accounts')
        .update({'benefit_type': benefitType})
        .eq('id', uid);
  }

  static Future<void> submitFeedback({
    required int rating,
    String comment = '',
  }) async {
    await _db.from('ratings').insert({
      'score': rating,
      'comments': comment.isEmpty ? null : comment,
      'source': 'mobile',
      'rated_at': DateTime.now().toIso8601String(),
    });
  }

  // Fetch route by QR token (from jeepney_qr_tokens table)
  static Future<Map<String, dynamic>?> fetchRouteByQRToken(String token) async {
    try {
      final qrData = await _db
          .from('jeepney_qr_tokens')
          .select('jeepney_id, version, active, metadata')
          .eq('token', token)
          .eq('active', true)
          .single();
      return qrData;
    } catch (e) {
      return null;
    }
  }
}
