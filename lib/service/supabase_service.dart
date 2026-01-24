import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const _tokenKey = 'auth_token';

  // ================= TOKEN HANDLER =================

  static Future<void> _writeToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token.trim());
      debugPrint('✅ TOKEN DISIMPAN (WEB)');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/token.txt');
      await file.writeAsString(token.trim(), flush: true);
      debugPrint('✅ TOKEN DISIMPAN (FILE)');
    }
  }

  static Future<String?> _readToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      debugPrint('🔍 TOKEN WEB: $token');
      return token;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/token.txt');
      if (!await file.exists()) return null;

      final token = await file.readAsString();
      final result = token.trim().isEmpty ? null : token.trim();
      debugPrint('🔍 TOKEN FILE: $result');
      return result;
    }
  }

  static Future<void> _deleteToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      debugPrint('🗑️ TOKEN WEB DIHAPUS');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/token.txt');
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ TOKEN FILE DIHAPUS');
      }
    }
  }

  // ================= LOGIN =================

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      debugPrint('🟡 LOGIN: $username');

      final user = await _client
          .from('user')
          .select('id, password, role, token, username')
          .eq('username', username)
          .maybeSingle();

      debugPrint('🟢 DB RESULT: $user');

      if (user == null) {
        return {'success': false, 'message': 'Username salah'};
      }

      if (user['password'] != password) {
        return {'success': false, 'message': 'Password salah'};
      }

      await _deleteToken();
      await _writeToken(user['token']);

      debugPrint('✅ LOGIN BERHASIL');

      return {
        'success': true,
        'message': 'Login berhasil',
        'role': user['role'],
        'username': user['username'],
      };
    } on PostgrestException catch (e) {
      debugPrint('❌ SUPABASE ERROR: ${e.message}');
      return {'success': false, 'message': e.message};
    } catch (e, stack) {
      debugPrint('❌ LOGIN ERROR: $e');
      debugPrint(stack.toString());
      return {
        'success': false,
        'message': 'Terjadi kesalahan (lihat terminal)',
      };
    }
  }

  // ================= AUTH CHECK =================

  static Future<bool> isLoggedIn() async {
    try {
      final token = await _readToken();
      if (token == null) return false;

      final user = await _client
          .from('user')
          .select('id')
          .eq('token', token)
          .maybeSingle();

      debugPrint('🔍 AUTH CHECK: $user');
      return user != null;
    } catch (e) {
      debugPrint('❌ AUTH CHECK ERROR: $e');
      return false;
    }
  }

  static Future<String?> getRole() async {
    try {
      final token = await _readToken();
      if (token == null) return null;

      final user = await _client
          .from('user')
          .select('role')
          .eq('token', token)
          .maybeSingle();

      return user?['role'];
    } catch (e) {
      debugPrint('❌ GET ROLE ERROR: $e');
      return null;
    }
  }

  // ================= GET USERNAME =================

  static Future<String?> getUsername() async {
    try {
      final token = await _readToken();
      if (token == null) return null;

      final user = await _client
          .from('user')
          .select('username')
          .eq('token', token)
          .maybeSingle();

      return user?['username'];
    } catch (e) {
      debugPrint('❌ GET USERNAME ERROR: $e');
      return null;
    }
  }

  // ================= LOGOUT =================

  static Future<void> logout() async {
    await _deleteToken();
    debugPrint('👋 LOGOUT');
  }
}
