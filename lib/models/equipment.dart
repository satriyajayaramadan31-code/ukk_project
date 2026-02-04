import 'package:engine_rent_app/models/alat.dart';

class Equipment {
  final String id;
  final String name;
  final String category;
  final String image;
  final String status;

  Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.status,
  });

  factory Equipment.fromAlat(Alat a) {
    return Equipment(
      id: a.id,
      name: a.namaAlat,
      category: a.kategoriNama,
      image: a.fotoUrl,
      status: a.status,
    );
  }
}