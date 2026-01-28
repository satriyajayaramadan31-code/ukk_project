import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/theme.dart';
import 'package:engine_rent_app/service/supabase_service.dart' as sbs;

class AddAlatDialog extends StatefulWidget {
  final List<sbs.Category> categories;

  const AddAlatDialog({super.key, required this.categories});

  @override
  State<AddAlatDialog> createState() => _AddAlatDialogState();
}

class _AddAlatDialogState extends State<AddAlatDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dendaController = TextEditingController();
  final TextEditingController perbaikanController = TextEditingController();

  String? selectedCategoryId;
  String status = "Tersedia";

  File? imageFile;
  Uint8List? imageBytes;

  bool nameError = false;
  bool categoryError = false;
  bool dendaError = false;
  bool perbaikanError = false;
  bool imageError = false;

  bool _isSubmitting = false; // ✅ prevent double submit

  final _radius = BorderRadius.circular(8);

  OutlineInputBorder get _border => OutlineInputBorder(
        borderRadius: _radius,
        borderSide: const BorderSide(color: Color(0xFF6B7280), width: 1.5),
      );

  // ================= PICK IMAGE =================
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        if (kIsWeb) {
          imageBytes = bytes;
          imageFile = null;
        } else {
          imageFile = File(picked.path);
          imageBytes = bytes;
        }
        imageError = false;
      });
    }
  }

  // ================= SUCCESS POPUP =================
  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
                "Alat Berhasil Ditambahkan",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    });
  }

  // ================= SUBMIT =================
  void _submit() async {
    if (_isSubmitting) return; // ✅ prevent double submit
    _isSubmitting = true;

    setState(() {
      nameError = nameController.text.trim().isEmpty;
      categoryError = selectedCategoryId == null;
      dendaError = dendaController.text.trim().isEmpty ||
          int.tryParse(dendaController.text.trim()) == null;
      perbaikanError = perbaikanController.text.trim().isEmpty ||
          int.tryParse(perbaikanController.text.trim()) == null;
      imageError = (imageFile == null && imageBytes == null);
    });

    if (nameError || categoryError || dendaError || perbaikanError || imageError) {
      _isSubmitting = false;
      return;
    }

    final selectedCategory =
        widget.categories.firstWhere((c) => c.id == selectedCategoryId);

    // ================= CEK NAMA ALAT SUDAH ADA =================
    final allAlat = await sbs.SupabaseService().getAlat();
    if (allAlat.any((a) => a.namaAlat.toLowerCase() == nameController.text.trim().toLowerCase())) {
      setState(() {
        nameError = true;
      });
      _isSubmitting = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama alat sudah ada! Gunakan nama lain.")),
      );
      return;
    }

    // ================= UPLOAD FOTO =================
    String imageUrl = '';
    if (imageBytes != null) {
      try {
        imageUrl = await sbs.SupabaseService.uploadFoto(
            imageBytes!, nameController.text.trim());
      } catch (e) {
        debugPrint('❌ Upload foto gagal: $e');
        _isSubmitting = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal upload foto")),
        );
        return;
      }
    }

    // pastikan foto_url tidak null
    if (imageUrl.isEmpty) imageUrl = '';

    // ================= INSERT ALAT =================
    try {
      final alat = await sbs.SupabaseService().addAlat(
        namaAlat: nameController.text.trim(),
        status: status,
        kategoriId: selectedCategory.id,
        denda: int.parse(dendaController.text.trim()),
        perbaikan: int.parse(perbaikanController.text.trim()),
        fotoUrl: imageUrl,
      );

      if (!mounted) return;
      Navigator.pop(context, alat);
      _showSuccessPopup();
    } catch (e) {
      debugPrint('❌ Gagal tambah alat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal tambah alat")),
      );
    } finally {
      _isSubmitting = false;
    }
  }

  // ================= BUILD WIDGET =================
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
              Center(child: Text("Tambah Alat", style: theme.textTheme.headlineSmall)),
              const SizedBox(height: 16),

              _label("Nama Alat"),
              _textField(nameController),
              if (nameError) _error("Nama alat wajib diisi atau sudah ada"),
              const SizedBox(height: 12),

              _label("Kategori"),
              _categoryDropdown(),
              if (categoryError) _error("Kategori harus dipilih"),
              const SizedBox(height: 12),

              _label("Foto Alat"),
              _uploadButton(),
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
                onChanged: (v) => setState(() => status = v ?? 'Tersedia'),
              ),
              const SizedBox(height: 12),

              _label("Biaya Denda"),
              _textField(dendaController, isNumber: true),
              if (dendaError) _error("Denda wajib diisi dan berupa angka"),
              const SizedBox(height: 12),

              _label("Biaya Perbaikan"),
              _textField(perbaikanController, isNumber: true),
              if (perbaikanError) _error("Perbaikan wajib diisi dan berupa angka"),
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
                      child: const Text("Tambah"),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text),
      );

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
          .map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: (v) => setState(() {
        selectedCategoryId = v;
        categoryError = false;
      }),
    );
  }

  Widget _uploadButton() {
    return ElevatedButton.icon(
      onPressed: _pickImage,
      icon: const Icon(Icons.photo),
      label: Text((imageFile != null || imageBytes != null) ? "Ganti Foto" : "Upload Foto"),
    );
  }

  Widget _error(String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(text, style: const TextStyle(color: Colors.red, fontSize: 11)),
      );
}
