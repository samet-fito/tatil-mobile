import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AdminService {
  static final _supabase = Supabase.instance.client;

  // ============================================================
  // ADMIN KONTROLÜ
  // ============================================================
  static Future<bool> isAdmin() async {
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    // Direkt email kontrolü (hardcoded admin listesi)
    const adminEmails = [
      'smtozkoparann@gmail.com',
    ];

    if (adminEmails.contains(user.email)) {
      debugPrint('Admin check: email match - admin!');
      return true;
    }

    return false;
  } catch (e) {
    debugPrint('Admin check error: $e');
    return false;
  }
}

  // ============================================================
  // OTEL YÖNETİMİ
  // ============================================================
  static Future<List<Map<String, dynamic>>> getHotels() async {
    try {
      final result = await _supabase
          .from('local_hotels')
          .select('*')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      return [];
    }
  }

static Future<bool> addHotel(Map<String, dynamic> hotel) async {
  try {
    await _supabase.from('local_hotels').insert(hotel);
    return true;
  } catch (e) {
    debugPrint('Add hotel error: $e');
    return false;
  }
}

  static Future<bool> updateHotel(String id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('local_hotels').update(data).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Update hotel error: $e');
      return false;
    }
  }

  static Future<bool> deleteHotel(String id) async {
    try {
      await _supabase
          .from('local_hotels')
          .update({'is_active': false})
          .eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // TRANSFER YÖNETİMİ
  // ============================================================
  static Future<List<Map<String, dynamic>>> getTransfers() async {
    try {
      final result = await _supabase
          .from('local_transfers')
          .select('*')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addTransfer(Map<String, dynamic> transfer) async {
    try {
      await _supabase.from('local_transfers').insert(transfer);
      return true;
    } catch (e) {
      debugPrint('Add transfer error: $e');
      return false;
    }
  }

  static Future<bool> updateTransfer(
      String id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('local_transfers').update(data).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Update transfer error: $e');
      return false;
    }
  }

  static Future<bool> deleteTransfer(String id) async {
    try {
      await _supabase
          .from('local_transfers')
          .update({'is_active': false})
          .eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // İSTATİSTİKLER
  // ============================================================
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final hotels = await _supabase
          .from('local_hotels')
          .select('id')
          .eq('is_active', true);

      final transfers = await _supabase
          .from('local_transfers')
          .select('id')
          .eq('is_active', true);

      final searches = await _supabase
          .from('searches')
          .select('id')
          .gte('created_at',
              DateTime.now()
                  .subtract(const Duration(days: 7))
                  .toIso8601String());

      return {
        'total_hotels': hotels.length,
        'total_transfers': transfers.length,
        'weekly_searches': searches.length,
      };
    } catch (e) {
      return {
        'total_hotels': 0,
        'total_transfers': 0,
        'weekly_searches': 0,
      };
    }
  }
}