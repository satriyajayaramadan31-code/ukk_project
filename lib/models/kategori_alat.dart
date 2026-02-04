class KategoriAlat {
  final String id;
  final String name;
  final int totalItems;

  KategoriAlat({
    required this.id,
    required this.name,
    this.totalItems = 0,
  });
}
