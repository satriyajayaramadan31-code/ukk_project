import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Category {
  final String id;
  final String name;
  final int totalItems;

  Category({required this.id, required this.name, this.totalItems = 0});
}

class Alat {
  final String id;
  final String namaAlat;
  final String fotoUrl;
  final String status;
  final String kategoriId;
  final String kategoriNama;
  final int denda;
  final int perbaikan;

  final Uint8List? bytes;

  Alat({
    required this.id,
    required this.namaAlat,
    required this.fotoUrl,
    required this.status,
    required this.kategoriId,
    required this.kategoriNama,
    required this.denda,
    required this.perbaikan,
    this.bytes,
  });

  factory Alat.fromMap(Map<String, dynamic> json) {
    return Alat(
      id: json['id'].toString(),
      namaAlat: json['nama_alat'] ?? '',
      fotoUrl: json['foto_url'] ?? '',
      status: json['status'] ?? 'Tersedia',
      kategoriId: json['kategori'].toString(),
      kategoriNama: json['kategori_alat'] != null
          ? json['kategori_alat']['kategori'] ?? ''
          : '',
      denda: json['denda'] ?? 0,
      perbaikan: json['perbaikan'] ?? 0,
    );
  }
}

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

  // ================= AUTH HELPERS =================
  static Future<int?> getUserId() async {
    try {
      final token = await _readToken();
      if (token == null) return null;

      final user =
          await _client.from('user').select('id').eq('token', token).maybeSingle();

      final id = user?['id'];
      if (id == null) return null;

      return (id is int) ? id : int.tryParse(id.toString());
    } catch (e) {
      debugPrint('❌ GET USER ID ERROR: $e');
      return null;
    }
  }

  static Future<String?> getRole() async {
    try {
      final token = await _readToken();
      if (token == null) return null;

      final user =
          await _client.from('user').select('role').eq('token', token).maybeSingle();

      return user?['role'];
    } catch (e) {
      debugPrint('❌ GET ROLE ERROR: $e');
      return null;
    }
  }

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

  // ================= LOG AKTIVITAS =================

  /// Insert log otomatis pakai userId dari token (user yang login).
  static Future<void> insertLog({
    required String description,
    int? userId,
  }) async {
    try {
      final uid = userId ?? await getUserId();
      if (uid == null) {
        debugPrint('⚠️ insertLog dibatalkan: userId null (belum login?)');
        return;
      }

      await _client.from('log_aktivitas').insert({
        'name': uid, // FK user.id
        'aksi': '$description',
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

      await _deleteToken();
      await _writeToken((user['token'] ?? '').toString());

      // ✅ log login
      final uid = (user['id'] is int) ? user['id'] : int.tryParse(user['id'].toString());
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
      final token = await _readToken();
      if (token == null) return false;

      final user =
          await _client.from('user').select('id').eq('token', token).maybeSingle();

      debugPrint('🔍 AUTH CHECK: $user');
      return user != null;
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
      PostgrestFilterBuilder q =
          _client.from('peminjaman').select('id').eq('status', status);

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
      PostgrestFilterBuilder q =
          _client.from('peminjaman').select('id').neq('terlambat', 0);

      if (role == 'Peminjam' && userId != null) q = q.eq('user', userId);

      final res = await q;
      return (res as List).length;
    } catch (e) {
      debugPrint('❌ COUNT OVERDUE ERROR (terlambat column): $e');
      return 0;
    }
  }

  static Future<Map<String, int>> getDashboardStats({required String role}) async {
    try {
      final userId = await getUserId();

      final totalEquipmentRes = await _client.from('alat').select('id');
      final totalEquipment = (totalEquipmentRes as List).length;

      final activeLoans = await _countLoansByStatus(
          status: 'dipinjam', role: role, userId: userId);
      final pendingApprovals = await _countLoansByStatus(
          status: 'menunggu', role: role, userId: userId);
      final overdueReturns = await _countOverdueByColumn(role: role, userId: userId);

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
        'overdueReturns': 0
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getDashboardActivities(
      {required String role, int limit = 5}) async {
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

      if (role == 'Peminjam' && userId != null) baseQuery = baseQuery.eq('user', userId);

      final data = await baseQuery.order('created_at', ascending: false).limit(limit);
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

      // ✅ log
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
      // ambil username lama untuk log biar sesuai permintaan: "Mengedit $user"
      final before = await _client
          .from('user')
          .select('username')
          .eq('id', id)
          .maybeSingle();

      final oldUsername = before?['username']?.toString() ?? username;

      await _client.from('user').update({
        'username': username,
        'password': password,
        'role': role,
      }).eq('id', id);

      // ✅ log
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
      // ambil username untuk log
      final before = await _client
          .from('user')
          .select('username')
          .eq('id', id)
          .maybeSingle();
      final uname = before?['username']?.toString() ?? 'User#$id';

      await _client.from('user').delete().eq('id', id);

      // ✅ log
      await insertLog(description: 'Menghapus User $uname');

      debugPrint('✅ DELETE USER SUCCESS');
      return true;
    } catch (e) {
      debugPrint('❌ DELETE USER ERROR: $e');
      return false;
    }
  }

  // ================= CATEGORY MANAGEMENT =================
  Future<List<Category>> getCategories() async {
    final response =
        await _client.from('kategori_alat').select().order('id', ascending: true);

    final data = response as List<dynamic>;
    return data.map((e) {
      return Category(
        id: e['id'].toString(),
        name: e['kategori'] ?? '',
      );
    }).toList();
  }

  Future<Category> addCategory(String name) async {
    final response = await _client
        .from('kategori_alat')
        .insert({'kategori': name})
        .select()
        .single();

    // ✅ log
    await SupabaseService.insertLog(description: 'Menambah kategori $name');

    return Category(
      id: response['id'].toString(),
      name: response['kategori'],
    );
  }

  Future<Category> editCategory(String id, String name) async {
    // ambil nama lama untuk log
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

    // ✅ log
    await SupabaseService.insertLog(description: 'Mengedit kategori $oldName');

    return Category(
      id: response['id'].toString(),
      name: response['kategori'],
    );
  }

  Future<void> deleteCategory(String id) async {
    // ambil nama kategori untuk log
    final before = await _client
        .from('kategori_alat')
        .select('kategori')
        .eq('id', id)
        .maybeSingle();
    final name = before?['kategori']?.toString() ?? 'Kategori#$id';

    await _client.from('kategori_alat').delete().eq('id', id);

    // ✅ log
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
      await _client.storage.from('Image').uploadBinary(
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
      await _client.storage.from('Image').remove(['$fileName']);
    } catch (e) {
      debugPrint('❌ Gagal hapus foto: $e');
      throw e;
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
    final res = await _client.from('alat').insert({
      'nama_alat': namaAlat,
      'status': status,
      'kategori': kategoriId,
      'denda': denda,
      'perbaikan': perbaikan,
      'foto_url': fotoUrl,
    }).select().single();

    // ✅ log
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
    // ambil nama lama untuk log
    final before = await _client
        .from('alat')
        .select('nama_alat')
        .eq('id', id)
        .maybeSingle();
    final oldName = before?['nama_alat']?.toString() ?? namaAlat;

    final res = await _client.from('alat').update({
      'nama_alat': namaAlat,
      'status': status,
      'kategori': kategoriId,
      'foto_url': image,
      'denda': denda,
      'perbaikan': perbaikan,
    }).eq('id', id).select().single();

    // ✅ log
    await SupabaseService.insertLog(description: 'Mengedit Alat $oldName');

    return Alat.fromMap(res);
  }

  Future<void> deleteAlat(String id, {String? fotoUrl}) async {
    try {
      // ambil nama alat untuk log
      final before = await _client
          .from('alat')
          .select('nama_alat')
          .eq('id', id)
          .maybeSingle();
      final name = before?['nama_alat']?.toString() ?? 'Alat#$id';

      // 1) hapus foto
      if (fotoUrl != null && fotoUrl.isNotEmpty) {
        await deleteFoto(fotoUrl);
      }

      // 2) hapus record
      await _client.from('alat').delete().eq('id', id);

      // ✅ log
      await SupabaseService.insertLog(description: 'Menghapus Alat $name');

      debugPrint('✅ Alat $id berhasil dihapus');
    } catch (e) {
      debugPrint('❌ Gagal hapus alat $id: $e');
      throw e;
    }
  }

  // ================= PEMINJAMAN =================

  static Future<List<Map<String, dynamic>>> getPeminjaman({
    required String role,
  }) async {
    try {
      final userId = await getUserId();

      final selectQuery = _client.from('peminjaman').select('''
        id,
        status,
        tanggal_pinjam,
        tanggal_kembali,
        tanggal_pengembalian,
        alasan,
        terlambat,
        rusak,
        denda,
        user:user ( id, username ),
        alat:alat ( id, nama_alat )
      ''');

      final res = (role == 'Peminjam' && userId != null)
          ? await selectQuery.eq('user', userId).order('created_at', ascending: false)
          : await selectQuery.order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(res);

      return list.map((e) {
        return {
          'id': e['id'],
          'status': e['status'],
          'tanggal_pinjam': e['tanggal_pinjam'],
          'tanggal_kembali': e['tanggal_kembali'],
          'tanggal_pengembalian': e['tanggal_pengembalian'],
          'alasan': e['alasan'],
          'terlambat': e['terlambat'] ?? 0,
          'rusak': e['rusak'] ?? false,
          'denda': e['denda'] ?? 0,
          'user_id': e['user']?['id'],
          'username': e['user']?['username'],
          'alat_id': e['alat']?['id'],
          'nama_alat': e['alat']?['nama_alat'],
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
      return (res['id'] is int) ? res['id'] : int.tryParse(res['id'].toString());
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
      return (res['id'] is int) ? res['id'] : int.tryParse(res['id'].toString());
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
  }) async {
    final inserted = await _client.from('peminjaman').insert({
      'user': userId,
      'alat': alatId,
      'tanggal_pinjam': tanggalPinjam,
      'tanggal_kembali': tanggalKembali,
      'tanggal_pengembalian': tanggalPengembalian,
      'alasan': alasan,
      'status': status,
    }).select('''
      id,
      status,
      tanggal_pinjam,
      tanggal_kembali,
      tanggal_pengembalian,
      alasan,
      user:user ( id, username ),
      alat:alat ( id, nama_alat )
    ''').single();

    final namaAlat = inserted['alat']?['nama_alat']?.toString() ?? 'Alat#$alatId';
    final namaPeminjam = inserted['user']?['username']?.toString() ?? 'User#$userId';

    // ✅ log
    await insertLog(description: 'Menambah peminjaman $namaAlat milik $namaPeminjam');

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
  }) async {
    final updated = await _client.from('peminjaman').update({
      'user': userId,
      'alat': alatId,
      'tanggal_pinjam': tanggalPinjam,
      'tanggal_kembali': tanggalKembali,
      'tanggal_pengembalian': tanggalPengembalian,
      'alasan': alasan,
      'status': status,
    }).eq('id', id).select('''
      id,
      status,
      tanggal_pinjam,
      tanggal_kembali,
      tanggal_pengembalian,
      alasan,
      user:user ( id, username ),
      alat:alat ( id, nama_alat )
    ''').single();

    final namaAlat = updated['alat']?['nama_alat']?.toString() ?? 'Alat#$alatId';
    final namaPeminjam = updated['user']?['username']?.toString() ?? 'User#$userId';

    // ✅ log
    await insertLog(description: 'Mengedit peminjaman $namaAlat milik $namaPeminjam');

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
      final before = await _client.from('peminjaman').select('''
        id,
        user:user ( username ),
        alat:alat ( nama_alat )
      ''').eq('id', id).maybeSingle();

      final namaAlat = before?['alat']?['nama_alat']?.toString() ?? 'Alat';
      final namaPeminjam = before?['user']?['username']?.toString() ?? 'User';

      await _client.from('peminjaman').delete().eq('id', id);

      // ✅ log
      await insertLog(description: 'Menghapus peminjaman $namaAlat milik $namaPeminjam');
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

  // ================= LOGOUT =================
  static Future<void> logout() async {
    await _deleteToken();
    await insertLog(description: 'Logout');
    debugPrint('👋 LOGOUT');
  }
}
