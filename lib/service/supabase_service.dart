import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kategori_alat.dart';
import '../models/alat.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const _tokenKey = 'auth_token';

  // ================= SESSION CACHE (ANTI DELAY) =================
  static int? _cachedUserId;
  static String? _cachedUsername;
  static String? _cachedRole;

  static void setSessionCache({
    required int userId,
    required String username,
    required String role,
  }) {
    _cachedUserId = userId;
    _cachedUsername = username;
    _cachedRole = role;
    debugPrint("⚡ SESSION CACHE SET: $username ($role) id=$userId");
  }

  static void clearSessionCache() {
    _cachedUserId = null;
    _cachedUsername = null;
    _cachedRole = null;
    debugPrint("🧹 SESSION CACHE CLEARED");
  }

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

  // ================= AUTH HELPERS =================
  static Future<int?> getUserId({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedUserId != null) return _cachedUserId;

      final token = await _readToken();
      if (token == null) return null;

      final user = await _client
          .from('user')
          .select('id')
          .eq('token', token)
          .maybeSingle();

      final id = user?['id'];
      if (id == null) return null;

      final parsed = (id is int) ? id : int.tryParse(id.toString());
      _cachedUserId = parsed;
      return parsed;
    } catch (e) {
      debugPrint('❌ GET USER ID ERROR: $e');
      return null;
    }
  }

  static Future<String?> getRole({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedRole != null) return _cachedRole;

      final token = await _readToken();
      if (token == null) return null;

      final user = await _client
          .from('user')
          .select('role')
          .eq('token', token)
          .maybeSingle();

      final role = user?['role']?.toString();
      _cachedRole = role;
      return role;
    } catch (e) {
      debugPrint('❌ GET ROLE ERROR: $e');
      return null;
    }
  }

  static Future<String?> getUsername({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedUsername != null) return _cachedUsername;

      final token = await _readToken();
      if (token == null) return null;

      final user = await _client
          .from('user')
          .select('username')
          .eq('token', token)
          .maybeSingle();

      final uname = user?['username']?.toString();
      _cachedUsername = uname;
      return uname;
    } catch (e) {
      debugPrint('❌ GET USERNAME ERROR: $e');
      return null;
    }
  }

  // ================= LOG AKTIVITAS =================

  /// Insert log otomatis pakai userId dari token (user yang login).
  static Future<void> insertLog({
    required String description,
    int? userId,
  }) async {
    try {
      final uid = userId ?? await getUserId(); // sudah pakai cache
      if (uid == null) {
        debugPrint('⚠️ insertLog dibatalkan: userId null (belum login?)');
        return;
      }

      await _client.from('log_aktivitas').insert({
        'name': uid, // FK user.id
        'aksi': description,
      });

      debugPrint('✅ Log ditambahkan: ($uid) $description');
    } catch (e) {
      debugPrint('❌ Gagal menambahkan log: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getLogs() async {
    try {
      final res = await _client
          .from('v_log_aktivitas')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('❌ GET LOGS ERROR: $e');
      return [];
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

      if (user == null) return {'success': false, 'message': 'Username salah'};

      if ((user['password'] ?? '').toString() != password) {
        return {'success': false, 'message': 'Password salah'};
      }

      // reset token lama
      await _deleteToken();
      await _writeToken((user['token'] ?? '').toString());

      // ================= CACHE SESSION (FIX DELAY) =================
      final uid = (user['id'] is int)
          ? user['id'] as int
          : int.tryParse(user['id'].toString());

      final uname = (user['username'] ?? '').toString();
      final r = (user['role'] ?? '').toString();

      if (uid != null) {
        setSessionCache(userId: uid, username: uname, role: r);
      }

      // log login
      if (uid != null) {
        await insertLog(description: 'Login', userId: uid);
      }

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
      // kalau cache ada -> langsung true (no delay)
      if (_cachedUserId != null && _cachedRole != null) return true;

      final token = await _readToken();
      if (token == null) return false;

      final user = await _client
          .from('user')
          .select('id, username, role')
          .eq('token', token)
          .maybeSingle();

      debugPrint('🔍 AUTH CHECK: $user');

      if (user == null) return false;

      // set cache biar berikutnya ga delay
      final uid = (user['id'] is int)
          ? user['id'] as int
          : int.tryParse(user['id'].toString());

      if (uid != null) {
        setSessionCache(
          userId: uid,
          username: (user['username'] ?? '').toString(),
          role: (user['role'] ?? '').toString(),
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ AUTH CHECK ERROR: $e');
      return false;
    }
  }

  // ================= DASHBOARD =================
  static Future<int> _countLoansByStatus({
    required String status,
    required String role,
    required int? userId,
  }) async {
    try {
      PostgrestFilterBuilder q = _client
          .from('peminjaman')
          .select('id')
          .eq('status', status);

      if (role == 'Peminjam' && userId != null) q = q.eq('user', userId);

      final res = await q;
      return (res as List).length;
    } catch (e) {
      debugPrint('❌ COUNT LOANS ERROR ($status): $e');
      return 0;
    }
  }

  static Future<int> _countOverdueByColumn({
    required String role,
    required int? userId,
  }) async {
    try {
      PostgrestFilterBuilder q = _client
          .from('peminjaman')
          .select('id')
          .neq('terlambat', 0);

      if (role == 'Peminjam' && userId != null) q = q.eq('user', userId);

      final res = await q;
      return (res as List).length;
    } catch (e) {
      debugPrint('❌ COUNT OVERDUE ERROR (terlambat column): $e');
      return 0;
    }
  }

  static Future<Map<String, int>> getDashboardStats({
    required String role,
  }) async {
    try {
      final userId = await getUserId();

      final totalEquipmentRes = await _client.from('alat').select('id');
      final totalEquipment = (totalEquipmentRes as List).length;

      final activeLoans = await _countLoansByStatus(
        status: 'dipinjam',
        role: role,
        userId: userId,
      );
      final pendingApprovals = await _countLoansByStatus(
        status: 'menunggu',
        role: role,
        userId: userId,
      );
      final overdueReturns = await _countOverdueByColumn(
        role: role,
        userId: userId,
      );

      return {
        'totalEquipment': totalEquipment,
        'activeLoans': activeLoans,
        'pendingApprovals': pendingApprovals,
        'overdueReturns': overdueReturns,
      };
    } catch (e) {
      debugPrint('❌ DASHBOARD STATS ERROR: $e');
      return {
        'totalEquipment': 0,
        'activeLoans': 0,
        'pendingApprovals': 0,
        'overdueReturns': 0,
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getDashboardActivities({
    required String role,
    int limit = 5,
  }) async {
    try {
      final userId = await getUserId();

      PostgrestFilterBuilder baseQuery = _client.from('peminjaman').select('''
        id,
        status,
        created_at,
        tanggal_pinjam,
        tanggal_kembali,
        tanggal_pengembalian,
        alasan,
        terlambat,
        alat ( nama_alat ),
        user:user ( username )
      ''');

      if (role == 'Peminjam' && userId != null) {
        baseQuery = baseQuery.eq('user', userId);
      }

      final data = await baseQuery
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('❌ DASHBOARD ACTIVITIES ERROR: $e');
      return [];
    }
  }

  static String timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  // ================= USER MANAGEMENT =================
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final res = await _client.from('user').select('*').order('username');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('❌ GET USERS ERROR: $e');
      return [];
    }
  }

  static Future<bool> addUser({
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      await _client.from('user').insert({
        'username': username,
        'password': password,
        'role': role,
      });

      await insertLog(description: 'Membuat User $username');

      debugPrint('✅ ADD USER SUCCESS');
      return true;
    } catch (e) {
      debugPrint('❌ ADD USER ERROR: $e');
      return false;
    }
  }

  static Future<bool> editUser({
    required int id,
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      final before = await _client
          .from('user')
          .select('username')
          .eq('id', id)
          .maybeSingle();

      final oldUsername = before?['username']?.toString() ?? username;

      await _client
          .from('user')
          .update({'username': username, 'password': password, 'role': role})
          .eq('id', id);

      await insertLog(description: 'Mengedit User $oldUsername');

      debugPrint('✅ EDIT USER SUCCESS');
      return true;
    } catch (e) {
      debugPrint('❌ EDIT USER ERROR: $e');
      return false;
    }
  }

  static Future<bool> deleteUser({required int id}) async {
    try {
      final before = await _client
          .from('user')
          .select('username')
          .eq('id', id)
          .maybeSingle();
      final uname = before?['username']?.toString() ?? 'User#$id';

      await _client.from('user').delete().eq('id', id);

      await insertLog(description: 'Menghapus User $uname');

      debugPrint('✅ DELETE USER SUCCESS');
      return true;
    } catch (e) {
      debugPrint('❌ DELETE USER ERROR: $e');
      return false;
    }
  }

  // ================= CATEGORY MANAGEMENT =================
  Future<List<KategoriAlat>> getCategories() async {
    final response = await _client
        .from('kategori_alat')
        .select()
        .order('id', ascending: true);

    final data = response as List<dynamic>;
    return data.map((e) {
      return KategoriAlat(id: e['id'].toString(), name: e['kategori'] ?? '');
    }).toList();
  }

  Future<KategoriAlat> addCategory(String name) async {
    final response = await _client
        .from('kategori_alat')
        .insert({'kategori': name})
        .select()
        .single();

    await SupabaseService.insertLog(description: 'Menambah kategori $name');

    return KategoriAlat(
      id: response['id'].toString(),
      name: response['kategori'],
    );
  }

  Future<KategoriAlat> editCategory(String id, String name) async {
    final before = await _client
        .from('kategori_alat')
        .select('kategori')
        .eq('id', id)
        .maybeSingle();
    final oldName = before?['kategori']?.toString() ?? name;

    final response = await _client
        .from('kategori_alat')
        .update({'kategori': name})
        .eq('id', id)
        .select()
        .single();

    await SupabaseService.insertLog(description: 'Mengedit kategori $oldName');

    return KategoriAlat(
      id: response['id'].toString(),
      name: response['kategori'],
    );
  }

  Future<void> deleteCategory(String id) async {
    final before = await _client
        .from('kategori_alat')
        .select('kategori')
        .eq('id', id)
        .maybeSingle();
    final name = before?['kategori']?.toString() ?? 'Kategori#$id';

    await _client.from('kategori_alat').delete().eq('id', id);

    await SupabaseService.insertLog(description: 'Menghapus kategori $name');
  }

  Future<int> countItemsInCategory(String categoryId) async {
    final response = await _client
        .from('alat')
        .select('id')
        .eq('kategori', categoryId)
        .limit(1000);

    final data = response as List<dynamic>? ?? [];
    return data.length;
  }

  // ================= ALAT =================
  static Future<String> uploadFoto(Uint8List bytes, String fileName) async {
    final safeName = fileName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '');

    final filePath = '$safeName.jpg';

    try {
      await _client.storage
          .from('Image')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from('Image').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('❌ Upload foto gagal: $e');
      rethrow;
    }
  }

  Future<void> deleteFoto(String url) async {
    final parts = url.split('/');
    final fileName = parts.last;
    try {
      await _client.storage.from('Image').remove([fileName]);
    } catch (e) {
      debugPrint('❌ Gagal hapus foto: $e');
      rethrow;
    }
  }

  Future<List<Alat>> getAlat() async {
    try {
      final res = await _client
          .from('alat')
          .select('*, kategori_alat(*)')
          .order('id', ascending: true);

      final data = res as List<dynamic>;
      return data.map((e) => Alat.fromMap(e)).toList();
    } catch (e) {
      debugPrint('❌ GET ALAT ERROR: $e');
      return [];
    }
  }

  Future<Alat> addAlat({
    required String namaAlat,
    required String status,
    required String kategoriId,
    required int denda,
    required int perbaikan,
    String fotoUrl = '',
  }) async {
    final res = await _client
        .from('alat')
        .insert({
          'nama_alat': namaAlat,
          'status': status,
          'kategori': kategoriId,
          'denda': denda,
          'perbaikan': perbaikan,
          'foto_url': fotoUrl,
        })
        .select()
        .single();

    await SupabaseService.insertLog(description: 'Menambah Alat $namaAlat');

    return Alat.fromMap(res);
  }

  Future<Alat> editAlat({
    required String id,
    required String namaAlat,
    required String status,
    required String kategoriId,
    required String image,
    required int denda,
    required int perbaikan,
  }) async {
    final before = await _client
        .from('alat')
        .select('nama_alat')
        .eq('id', id)
        .maybeSingle();
    final oldName = before?['nama_alat']?.toString() ?? namaAlat;

    final res = await _client
        .from('alat')
        .update({
          'nama_alat': namaAlat,
          'status': status,
          'kategori': kategoriId,
          'foto_url': image,
          'denda': denda,
          'perbaikan': perbaikan,
        })
        .eq('id', id)
        .select()
        .single();

    await SupabaseService.insertLog(description: 'Mengedit Alat $oldName');

    return Alat.fromMap(res);
  }

  Future<void> deleteAlat(String id, {String? fotoUrl}) async {
    try {
      final before = await _client
          .from('alat')
          .select('nama_alat')
          .eq('id', id)
          .maybeSingle();
      final name = before?['nama_alat']?.toString() ?? 'Alat#$id';

      if (fotoUrl != null && fotoUrl.isNotEmpty) {
        await deleteFoto(fotoUrl);
      }

      await _client.from('alat').delete().eq('id', id);

      await SupabaseService.insertLog(description: 'Menghapus Alat $name');

      debugPrint('✅ Alat $id berhasil dihapus');
    } catch (e) {
      debugPrint('❌ Gagal hapus alat $id: $e');
      rethrow;
    }
  }

  // ================= PEMINJAMAN =================
  static Future<List<Map<String, dynamic>>> getPeminjaman({
    required String role,
  }) async {
    try {
      final normalizedRole = role.trim().toLowerCase();
      final userId = await getUserId();

      // base query
      PostgrestFilterBuilder q = _client.from('peminjaman').select('''
        id,
        status,
        tanggal_pinjam,
        tanggal_kembali,
        tanggal_pengembalian,
        alasan,
        terlambat,
        rusak,
        denda,
        created_at,
        user:user ( id, username ),
        alat:alat ( id, nama_alat, denda, perbaikan )
      ''');

      // ✅ filter hanya jika role peminjam
      if (normalizedRole == 'peminjam') {
        if (userId == null) return [];
        q = q.eq('user', userId);
      }

      final res = await q.order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(res);

      return list.map((e) {
        final alat = e['alat'] as Map<String, dynamic>?;
        final user = e['user'] as Map<String, dynamic>?;

        return {
          'id': e['id'],
          'status': e['status'],
          'tanggal_pinjam': e['tanggal_pinjam'],
          'tanggal_kembali': e['tanggal_kembali'],
          'tanggal_pengembalian': e['tanggal_pengembalian'],
          'alasan': e['alasan'],
          'terlambat': e['terlambat'] ?? 0,
          'rusak': e['rusak'] ?? false,

          // denda tersimpan di peminjaman (kalau ada)
          'denda': e['denda'] ?? 0,

          'user_id': user?['id'],
          'username': user?['username'],

          'alat_id': alat?['id'],
          'nama_alat': alat?['nama_alat'],

          // buat hitung denda UI
          'denda_alat': alat?['denda'] ?? 0,
          'perbaikan_alat': alat?['perbaikan'] ?? 0,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ GET PEMINJAMAN ERROR: $e');
      return [];
    }
  }

  static Future<int?> findUserIdByUsername(String username) async {
    try {
      final res = await _client
          .from('user')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      if (res == null) return null;
      return (res['id'] is int)
          ? res['id']
          : int.tryParse(res['id'].toString());
    } catch (e) {
      debugPrint('❌ findUserIdByUsername ERROR: $e');
      return null;
    }
  }

  static Future<int?> findAlatIdByNama(String namaAlat) async {
    try {
      final res = await _client
          .from('alat')
          .select('id')
          .eq('nama_alat', namaAlat)
          .maybeSingle();
      if (res == null) return null;
      return (res['id'] is int)
          ? res['id']
          : int.tryParse(res['id'].toString());
    } catch (e) {
      debugPrint('❌ findAlatIdByNama ERROR: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> addPeminjaman({
    required int userId,
    required int alatId,
    required String tanggalPinjam,
    required String tanggalKembali,
    String? tanggalPengembalian,
    required String alasan,
    required String status,
    String? role,
  }) async {
    final inserted = await _client
        .from('peminjaman')
        .insert({
          'user': userId,
          'alat': alatId,
          'tanggal_pinjam': tanggalPinjam,
          'tanggal_kembali': tanggalKembali,
          'tanggal_pengembalian': tanggalPengembalian,
          'alasan': alasan,
          'status': status,
        })
        .select('''
      id,
      status,
      tanggal_pinjam,
      tanggal_kembali,
      tanggal_pengembalian,
      alasan,
      user:user ( id, username ),
      alat:alat ( id, nama_alat )
    ''')
        .single();

    final namaAlat =
        inserted['alat']?['nama_alat']?.toString() ?? 'Alat#$alatId';
    final namaPeminjam =
        inserted['user']?['username']?.toString() ?? 'User#$userId';

    // ✅ log
    final normalizedRole = (role ?? '').toLowerCase().trim();
    if (normalizedRole == 'admin') {
      await insertLog(
        description: 'Menambah peminjaman $namaAlat milik $namaPeminjam',
      );
    } else {
      await insertLog(
        description: '$namaPeminjam mengajukan peminjaman alat $namaAlat',
      );
    }

    return {
      'id': inserted['id'],
      'status': inserted['status'],
      'tanggal_pinjam': inserted['tanggal_pinjam'],
      'tanggal_kembali': inserted['tanggal_kembali'],
      'tanggal_pengembalian': inserted['tanggal_pengembalian'],
      'alasan': inserted['alasan'],
      'user_id': inserted['user']?['id'],
      'username': inserted['user']?['username'],
      'alat_id': inserted['alat']?['id'],
      'nama_alat': inserted['alat']?['nama_alat'],
    };
  }

  static Future<Map<String, dynamic>> editPeminjaman({
    required dynamic id,
    required int userId,
    required int alatId,
    required String tanggalPinjam,
    required String tanggalKembali,
    String? tanggalPengembalian,
    required String alasan,
    required String status,
    bool? rusak,
    String? role,
  }) async {
    // ==========================
    // 1) Ambil status lama
    // ==========================
    final oldRow = await _client
        .from('peminjaman')
        .select('status')
        .eq('id', id)
        .single();

    final oldStatus = (oldRow['status'] ?? '').toString().toLowerCase().trim();

    // ==========================
    // 2) Update
    // ==========================
    final updated = await _client
        .from('peminjaman')
        .update({
          'user': userId,
          'alat': alatId,
          'tanggal_pinjam': tanggalPinjam,
          'tanggal_kembali': tanggalKembali,
          'tanggal_pengembalian': tanggalPengembalian,
          'alasan': alasan,
          'status': status,
          'rusak': rusak ?? false,
        })
        .eq('id', id)
        .select('''
          id,
          status,
          tanggal_pinjam,
          tanggal_kembali,
          tanggal_pengembalian,
          alasan,
          user:user ( id, username ),
          alat:alat ( id, nama_alat )
        ''')
        .single();

    // ==========================
    // 3) Normalisasi data
    // ==========================
    final namaAlat =
        updated['alat']?['nama_alat']?.toString() ?? 'Alat#$alatId';
    final namaPeminjam =
        updated['user']?['username']?.toString() ?? 'User#$userId';

    final newStatus = (updated['status'] ?? '').toString().toLowerCase().trim();
    final normalizedRole = (role ?? '').toLowerCase().trim();

    // ==========================
    // 4) LOG berdasarkan transisi status
    // ==========================

    // Admin edit biasa
    if (normalizedRole == 'admin') {
      await insertLog(
        description: 'Mengedit peminjaman $namaAlat milik $namaPeminjam',
      );
    }

    // Menunggu -> Dipinjam (Menyetujui peminjaman)
    if (oldStatus == 'menunggu' && newStatus == 'dipinjam') {
      await insertLog(
        description: 'Menyetujui peminjaman $namaAlat untuk $namaPeminjam',
      );
    }

    // Diproses -> Dikembalikan (Menyetujui pengembalian)
    if (oldStatus == 'diproses' && newStatus == 'dikembalikan') {
      await insertLog(
        description: 'Menyetujui pengembalian $namaAlat dari $namaPeminjam',
      );
    }

    // Diproses -> Dipinjam (Menolak pengembalian)
    if (oldStatus == 'diproses' && newStatus == 'dipinjam') {
      await insertLog(
        description: 'Menolak pengembalian $namaAlat dari $namaPeminjam',
      );
    }

    return {
      'id': updated['id'],
      'status': updated['status'],
      'tanggal_pinjam': updated['tanggal_pinjam'],
      'tanggal_kembali': updated['tanggal_kembali'],
      'tanggal_pengembalian': updated['tanggal_pengembalian'],
      'alasan': updated['alasan'],
      'user_id': updated['user']?['id'],
      'username': updated['user']?['username'],
      'alat_id': updated['alat']?['id'],
      'nama_alat': updated['alat']?['nama_alat'],
    };
  }

  static Future<void> deletePeminjaman({required dynamic id}) async {
    // ambil data sebelum dihapus biar log lengkap
    try {
      final before = await _client
          .from('peminjaman')
          .select('''
        id,
        user:user ( username ),
        alat:alat ( nama_alat )
      ''')
          .eq('id', id)
          .maybeSingle();

      final namaAlat = before?['alat']?['nama_alat']?.toString() ?? 'Alat';
      final namaPeminjam = before?['user']?['username']?.toString() ?? 'User';

      await _client.from('peminjaman').delete().eq('id', id);

      // ✅ log
      await insertLog(
        description: 'Menghapus peminjaman $namaAlat milik $namaPeminjam',
      );
    } catch (e) {
      // fallback: tetap hapus
      await _client.from('peminjaman').delete().eq('id', id);
      await insertLog(description: 'Menghapus peminjaman id=$id');
    }
  }

  static Future<List<Map<String, dynamic>>> getAlatList() async {
    final res = await _client
        .from('alat')
        .select('id, nama_alat')
        .order('nama_alat', ascending: true);

    return List<Map<String, dynamic>>.from(res);
  }

  // ================= LAPORAN =================
  static DateTime _startDateFromPeriod(String timePeriod) {
    final now = DateTime.now();
    DateTime start;

    switch (timePeriod) {
      case 'week':
        start = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        start = DateTime(now.year, now.month, 1);
    }
    return DateTime(start.year, start.month, start.day);
  }

  static Future<List<Map<String, dynamic>>> getLaporanRaw({
    required String timePeriod,
  }) async {
    try {
      final start = _startDateFromPeriod(timePeriod);
      final role = await getRole();
      final userId = await getUserId();

      PostgrestFilterBuilder q = _client.from('peminjaman').select('''
      id,
      status,
      tanggal_pinjam,
      tanggal_kembali,
      tanggal_pengembalian,
      terlambat,
      denda,
      user:user ( id, username ),
      alat:alat ( id, nama_alat, kategori, kategori_alat ( id, kategori ) ),
      created_at
    ''');

      q = q.gte('created_at', start.toIso8601String());

      if ((role ?? '').toLowerCase() == 'peminjam' && userId != null) {
        q = q.eq('user', userId);
      }

      final res = await q.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('❌ GET LAPORAN RAW ERROR: $e');
      return [];
    }
  }

  // ================= PENGEMBALIAN =================
  static Future<void> kembalikanPeminjaman({
    required int peminjamanId,
    required int alatId,
    required String tanggalKembali, // dari DB (tanggal_kembali)
    required bool rusak,
  }) async {
    try {
      final now = DateTime.now();

      // ambil nama alat untuk log
      final alat = await _client
          .from('alat')
          .select('nama_alat')
          .eq('id', alatId)
          .maybeSingle();

      final namaAlat = alat?['nama_alat']?.toString() ?? 'Alat#$alatId';

      // update peminjaman
      await _client
          .from('peminjaman')
          .update({
            'status': 'dikembalikan',
            'tanggal_pengembalian': now.toIso8601String(),
            'rusak': rusak,
          })
          .eq('id', peminjamanId);

      // update alat -> tersedia lagi
      await _client
          .from('alat')
          .update({'status': 'Tersedia'})
          .eq('id', alatId);

      // log (pakai nama alat)
      await insertLog(description: 'Mengembalikan alat $namaAlat');

      debugPrint('✅ Pengembalian berhasil id=$peminjamanId');
    } catch (e) {
      debugPrint('❌ kembalikanPeminjaman ERROR: $e');
      rethrow;
    }
  }

  static Future<void> updatePengembalianUI({
    required int peminjamanId,
    required bool rusak,
    required int terlambat,
    required int denda,
  }) async {
    final supabase = Supabase.instance.client;

    await supabase
        .from('peminjaman')
        .update({
          'status': 'diproses',
          'rusak': rusak,
          'terlambat': terlambat,
          'denda': denda,
          'tanggal_pengembalian': DateTime.now().toIso8601String(),
        })
        .eq('id', peminjamanId);
  }

  // =============== Pemanjangan ==============

  static Future<List<Map<String, dynamic>>> fetchPemanjanganLoans() async {
    final role = await getRole();
    final userId = await getUserId();

    if (role == null || userId == null) return [];
    if (role.toLowerCase().trim() != 'peminjam') return [];

    final res = await _client
        .from('peminjaman')
        .select('''
        id,
        status,
        tanggal_pinjam,
        tanggal_kembali,
        tanggal_pengembalian,
        tambah,
        pengulangan,
        minta,
        created_at,
        alat:alat ( id, nama_alat )
      ''')
        .eq('user', userId)
        .inFilter('status', ['dipinjam', 'menunggu', 'diproses'])
        .order('created_at', ascending: false);

    final list = List<Map<String, dynamic>>.from(res);

    final filtered = list.where((e) {
      final status = (e['status'] ?? '').toString().toLowerCase().trim();
      final minta = (e['minta'] ?? false) == true;
      return status == 'dipinjam' || minta;
    }).toList();

    filtered.sort((a, b) {
      final am = (a['minta'] ?? false) == true;
      final bm = (b['minta'] ?? false) == true;
      if (am == bm) return 0;
      return am ? -1 : 1;
    });

    return filtered;
  }

  // request perpanjangan
  static Future<void> requestExtension({
    required dynamic peminjamanId,
    required int tambahHari,
  }) async {
    await _client
        .from('peminjaman')
        .update({'tambah': tambahHari, 'minta': true})
        .eq('id', peminjamanId);
  }

  static Future<List<Map<String, dynamic>>>
  fetchPemanjanganRequestsAdmin() async {
    try {
      final role = await getRole();
      if (role == null || role.toLowerCase().trim() != 'petugas') return [];

      final res = await _client
          .from('peminjaman')
          .select('''
        id,
        status,
        tanggal_pinjam,
        tanggal_kembali,
        tanggal_pengembalian,
        tambah,
        pengulangan,
        minta,
        created_at,
        user:user ( id, username ),
        alat:alat ( id, nama_alat )
      ''')
          .eq('minta', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('❌ fetchPemanjanganRequests ERROR: $e');
      return [];
    }
  }

  /// ADMIN: terima permintaan pemanjangan
  /// - tanggal_kembali = tanggal_kembali + tambah hari
  /// - pengulangan + 1
  /// - minta = false
  /// - tambah = 0
  static Future<void> approveExtension({required dynamic peminjamanId}) async {
    try {
      // ambil data dulu
      final row = await _client
          .from('peminjaman')
          .select('''
        id,
        tanggal_kembali,
        tambah,
        pengulangan,
        user:user ( username ),
        alat:alat ( nama_alat )
      ''')
          .eq('id', peminjamanId)
          .single();

      final String tanggalKembaliStr = (row['tanggal_kembali'] ?? '')
          .toString();
      final int tambahHari = (row['tambah'] ?? 0) is int
          ? (row['tambah'] ?? 0)
          : int.tryParse(row['tambah'].toString()) ?? 0;

      final int pengulangan = (row['pengulangan'] ?? 0) is int
          ? (row['pengulangan'] ?? 0)
          : int.tryParse(row['pengulangan'].toString()) ?? 0;

      final namaAlat = row['alat']?['nama_alat']?.toString() ?? 'Alat';
      final namaPeminjam = row['user']?['username']?.toString() ?? 'User';

      if (tanggalKembaliStr.isEmpty) {
        throw Exception('tanggal_kembali kosong');
      }

      final oldDate = DateTime.parse(tanggalKembaliStr);
      final newDate = oldDate.add(Duration(days: tambahHari));

      await _client
          .from('peminjaman')
          .update({
            'tanggal_kembali': newDate.toIso8601String(),
            'pengulangan': pengulangan + 1,
            'minta': false,
            'tambah': 0,
          })
          .eq('id', peminjamanId);

      // log
      await insertLog(
        description:
            'Menerima pemanjangan $namaAlat milik $namaPeminjam (+$tambahHari hari)',
      );

      debugPrint('✅ approveExtension sukses id=$peminjamanId');
    } catch (e) {
      debugPrint('❌ approveExtension ERROR: $e');
      rethrow;
    }
  }

  /// ADMIN: tolak permintaan pemanjangan
  /// - minta = false
  /// - tambah = 0
  static Future<void> rejectExtension({required dynamic peminjamanId}) async {
    try {
      final before = await _client
          .from('peminjaman')
          .select('''
        id,
        user:user ( username ),
        alat:alat ( nama_alat ),
        tambah
      ''')
          .eq('id', peminjamanId)
          .maybeSingle();

      final namaAlat = before?['alat']?['nama_alat']?.toString() ?? 'Alat';
      final namaPeminjam = before?['user']?['username']?.toString() ?? 'User';
      final tambahHari = before?['tambah'] ?? 0;

      await _client
          .from('peminjaman')
          .update({'minta': false, 'tambah': 0})
          .eq('id', peminjamanId);

      await insertLog(
        description:
            'Menolak pemanjangan $namaAlat milik $namaPeminjam (+$tambahHari hari)',
      );

      debugPrint('✅ rejectExtension sukses id=$peminjamanId');
    } catch (e) {
      debugPrint('❌ rejectExtension ERROR: $e');
      rethrow;
    }
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    // FIX: reset cache supaya login berikutnya tidak nyangkut
    clearSessionCache();

    await _deleteToken();
    await insertLog(description: 'Logout');
    debugPrint('👋 LOGOUT');
  }
}
