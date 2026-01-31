import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/theme.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

class EditAlatDialog extends StatefulWidget {
  final Alat alat;
  final List<Category> categories;

  const EditAlatDialog({
    super.key,
    required this.alat,
    required this.categories,
  });

  @override
  State<EditAlatDialog> createState() => _EditAlatDialogState();
}

class _EditAlatDialogState extends State<EditAlatDialog> {
  final SupabaseService _service = SupabaseService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController dendaController = TextEditingController();
  final TextEditingController perbaikanController = TextEditingController();

  String? selectedCategoryId;
  String status = "Tersedia";

  late String _oldFotoUrl;
  Uint8List? _newImageBytes;

  bool nameError = false;
  bool categoryError = false;
  bool dendaError = false;
  bool perbaikanError = false;
  bool imageError = false;

  bool _submitting = false;

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

    nameController.text = widget.alat.namaAlat;
    dendaController.text = widget.alat.denda.toString();
    perbaikanController.text = widget.alat.perbaikan.toString();
    selectedCategoryId = widget.alat.kategoriId;
    status = widget.alat.status;

    _oldFotoUrl = widget.alat.fotoUrl;
  }

  @override
  void dispose() {
    nameController.dispose();
    dendaController.dispose();
    perbaikanController.dispose();
    super.dispose();
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.background,
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

  void _validate() {
    setState(() {
      nameError = nameController.text.trim().isEmpty;
      categoryError = selectedCategoryId == null;

      dendaError = dendaController.text.trim().isEmpty ||
          int.tryParse(dendaController.text.trim()) == null;

      perbaikanError = perbaikanController.text.trim().isEmpty ||
          int.tryParse(perbaikanController.text.trim()) == null;

      // foto wajib: kalau tidak ada foto lama, harus pilih foto baru
      final hasOld = _oldFotoUrl.isNotEmpty;
      final hasNew = _newImageBytes != null;
      imageError = !(hasOld || hasNew);
    });
  }

  Future<void> _pickNewPhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      setState(() {
        _newImageBytes = bytes;
        imageError = false;
      });
    } catch (e) {
      debugPrint("❌ Gagal pilih foto: $e");
    }
  }

  // bikin nama file unik biar tidak ketimpa/hilang
  String _buildUniqueFileName() {
    final safeName = nameController.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '');

    // unik per alat
    return '${safeName}_${widget.alat.id}';
  }

  Future<void> _submit() async {
    if (_submitting) return;

    _validate();
    if (nameError || categoryError || dendaError || perbaikanError || imageError) {
      return;
    }

    setState(() => _submitting = true);

    try {
      String finalFotoUrl = _oldFotoUrl;

      // kalau user pilih foto baru -> HAPUS DULU lalu UPLOAD baru
      if (_newImageBytes != null) {
        // 1) hapus foto lama dulu
        if (_oldFotoUrl.isNotEmpty) {
          await _service.deleteFoto(_oldFotoUrl);
        }

        // 2) upload foto baru (file name unik)
        final uploadedUrl = await SupabaseService.uploadFoto(
          _newImageBytes!,
          _buildUniqueFileName(),
        );

        // 3) pakai url baru
        finalFotoUrl = uploadedUrl;
      }

      // 4) update tabel alat (ganti url baru)
      final updated = await _service.editAlat(
        id: widget.alat.id,
        namaAlat: nameController.text.trim(),
        status: status,
        kategoriId: selectedCategoryId!,
        image: finalFotoUrl,
        denda: int.parse(dendaController.text.trim()),
        perbaikan: int.parse(perbaikanController.text.trim()),
      );

      if (!mounted) return;

      Navigator.pop(context, updated);

      Future.microtask(() {
        if (mounted) _showSuccessPopup();
      });
    } catch (e) {
      debugPrint("❌ Edit alat gagal: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memperbarui alat: $e")),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
                initialValue: status,
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
                onChanged: _submitting ? null : (v) => setState(() => status = v!),
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
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_submitting ? "Menyimpan..." : "Simpan"),
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
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Batal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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

  Widget _label(String text) =>
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text));

  Widget _textField(TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      enabled: !_submitting,
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
      initialValue: selectedCategoryId,
      hint: const Text("Pilih kategori"),
      decoration: InputDecoration(
        border: _border,
        enabledBorder: _border,
        focusedBorder: _border,
      ),
      items: widget.categories
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: _submitting
          ? null
          : (v) => setState(() {
                selectedCategoryId = v;
                categoryError = false;
              }),
    );
  }

  Widget _uploadButton() {
    final hasNew = _newImageBytes != null;

    return ElevatedButton.icon(
      onPressed: _submitting ? null : _pickNewPhoto,
      icon: const Icon(Icons.photo),
      label: Text(hasNew ? "Foto Baru Dipilih" : "Ganti Foto"),
    );
  }

  Widget _error(String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(text, style: const TextStyle(color: Colors.red, fontSize: 11)),
      );
}
