import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

class EditAlatDialog extends StatefulWidget {
  final Alat alat;
  final List<Category> categories; // pakai objek Category supaya bisa id & name

  const EditAlatDialog({
    super.key,
    required this.alat,
    required this.categories,
  });

  @override
  State<EditAlatDialog> createState() => _EditAlatDialogState();
}

class _EditAlatDialogState extends State<EditAlatDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dendaController = TextEditingController();
  final TextEditingController perbaikanController = TextEditingController();

  String? selectedCategoryId;
  String status = "Tersedia";
  String? imagePath;
  String? oldImagePath;

  bool nameError = false;
  bool categoryError = false;
  bool dendaError = false;
  bool perbaikanError = false;
  bool imageError = false;

  final _radius = BorderRadius.circular(8);

  OutlineInputBorder get _border => OutlineInputBorder(
        borderRadius: _radius,
        borderSide: const BorderSide(
          color: Color(0xFF6B7280),
          width: 1.5,
        ),
      );

  @override
  void initState() {
    super.initState();

    // pre-fill data
    nameController.text = widget.alat.namaAlat;
    dendaController.text = widget.alat.denda.toString();
    perbaikanController.text = widget.alat.perbaikan.toString();
    selectedCategoryId = widget.alat.kategoriId;
    status = widget.alat.status;
    imagePath = widget.alat.fotoUrl;
    oldImagePath = widget.alat.fotoUrl;
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.check_circle, size: 72, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  "Alat Berhasil Diperbarui",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  void _submit() {
    setState(() {
      nameError = nameController.text.trim().isEmpty;
      categoryError = selectedCategoryId == null;
      dendaError = dendaController.text.trim().isEmpty || int.tryParse(dendaController.text.trim()) == null;
      perbaikanError = perbaikanController.text.trim().isEmpty || int.tryParse(perbaikanController.text.trim()) == null;
      imageError = imagePath == null || imagePath!.isEmpty;
    });

    if (nameError || categoryError || dendaError || perbaikanError || imageError) return;

    final result = Alat(
      id: widget.alat.id,
      namaAlat: nameController.text.trim(),
      kategoriId: selectedCategoryId!,
      kategoriNama: widget.categories.firstWhere((c) => c.id == selectedCategoryId!).name,
      fotoUrl: imagePath!,
      status: status,
      denda: int.parse(dendaController.text.trim()),
      perbaikan: int.parse(perbaikanController.text.trim()),
    );

    Navigator.pop(context, result);

    Future.microtask(() {
      if (mounted) _showSuccessPopup();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: AppTheme.background,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Text("Edit Alat", style: theme.textTheme.headlineSmall)),
              const SizedBox(height: 16),

              _label("Nama Alat"),
              _textField(nameController),
              if (nameError) _error("Nama alat wajib diisi"),
              const SizedBox(height: 12),

              _label("Kategori"),
              _categoryDropdown(),
              if (categoryError) _error("Kategori harus dipilih"),
              const SizedBox(height: 12),

              _label("Foto Alat"),
              _uploadButton(),
              if (imageError) _error("Foto alat wajib diupload"),
              const SizedBox(height: 12),

              _label("Status"),
              DropdownButtonFormField<String>(
                value: status,
                decoration: InputDecoration(
                  border: _border,
                  enabledBorder: _border,
                  focusedBorder: _border,
                ),
                items: const [
                  DropdownMenuItem(value: "Tersedia", child: Text("Tersedia")),
                  DropdownMenuItem(value: "Dipinjam", child: Text("Dipinjam")),
                  DropdownMenuItem(value: "Rusak", child: Text("Rusak")),
                ],
                onChanged: (v) => setState(() => status = v!),
              ),
              const SizedBox(height: 12),

              _label("Biaya Denda"),
              _textField(dendaController, isNumber: true),
              if (dendaError) _error("Denda wajib diisi & angka"),
              const SizedBox(height: 12),

              _label("Biaya Perbaikan"),
              _textField(perbaikanController, isNumber: true),
              if (perbaikanError) _error("Perbaikan wajib diisi & angka"),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Simpan"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text));

  Widget _textField(TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        border: _border,
        enabledBorder: _border,
        focusedBorder: _border,
      ),
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCategoryId,
      hint: const Text("Pilih kategori"),
      decoration: InputDecoration(
        border: _border,
        enabledBorder: _border,
        focusedBorder: _border,
      ),
      items: widget.categories
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: (v) => setState(() {
        selectedCategoryId = v;
        categoryError = false;
      }),
    );
  }

  Widget _uploadButton() {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          // ganti foto lama dengan yang baru (dummy placeholder)
          imagePath = "uploaded_image_placeholder.jpg";
          imageError = false;
        });
      },
      icon: const Icon(Icons.photo),
      label: Text(imagePath == null ? "Upload Foto" : "Ganti Foto"),
    );
  }

  Widget _error(String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(text, style: const TextStyle(color: Colors.red, fontSize: 11)),
      );
}
