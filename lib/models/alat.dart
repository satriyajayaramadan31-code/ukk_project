import 'dart:typed_data';

class Alat {
  final String id;
  final String namaAlat;
  final String fotoUrl;
  final String status;
  final String kategoriId;
  final String kategoriNama;
  final int denda;
  final int perbaikan;
  final bool? rusak;

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
    this.rusak,
    this.bytes,
  });

  static bool? _parseBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is int) return v == 1;
    final s = v.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'ya' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'tidak' || s == 'no') return false;
    return null;
  }

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
      rusak: _parseBool(json['rusak']) ?? false,
    );
  }
}
