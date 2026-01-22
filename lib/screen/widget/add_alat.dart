import 'package:flutter/material.dart';
import '../utils/models.dart';

class AddAlatDialog extends StatefulWidget {
  final Alat? alat;

  const AddAlatDialog({super.key, this.alat});

  @override
  State<AddAlatDialog> createState() => _AddAlatDialogState();
}

class _AddAlatDialogState extends State<AddAlatDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController categoryController;
  late TextEditingController descriptionController;
  late TextEditingController imageController;
  late String status;

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: widget.alat?.name ?? "");
    categoryController =
        TextEditingController(text: widget.alat?.category ?? "");
    descriptionController =
        TextEditingController(text: widget.alat?.description ?? "");
    imageController =
        TextEditingController(text: widget.alat?.image ?? "");
    status = widget.alat?.status ?? "Tersedia";
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    imageController.dispose();
    super.dispose();
  }

  void submit() {
    if (_formKey.currentState!.validate()) {
      final newAlat = Alat(
        id: widget.alat?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        category: categoryController.text.trim(),
        description: descriptionController.text.trim(),
        image: imageController.text.trim(),
        status: status,
      );

      Navigator.pop(context, newAlat);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.alat == null ? "Tambah Alat" : "Edit Alat"),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nama Alat"),
                validator: (value) =>
                    value!.isEmpty ? "Nama alat wajib diisi" : null,
              ),
              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: "Kategori"),
                validator: (value) =>
                    value!.isEmpty ? "Kategori wajib diisi" : null,
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Deskripsi"),
                validator: (value) =>
                    value!.isEmpty ? "Deskripsi wajib diisi" : null,
              ),
              TextFormField(
                controller: imageController,
                decoration: const InputDecoration(labelText: "URL Foto"),
                validator: (value) =>
                    value!.isEmpty ? "URL foto wajib diisi" : null,
              ),
              DropdownButtonFormField<String>(
                value: status,
                items: const [
                  DropdownMenuItem(
                      value: "Tersedia", child: Text("Tersedia")),
                  DropdownMenuItem(
                      value: "Dipinjam", child: Text("Dipinjam")),
                  DropdownMenuItem(
                      value: "Rusak", child: Text("Rusak")),
                ],
                onChanged: (value) => setState(() => status = value!),
                decoration: const InputDecoration(labelText: "Status"),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: submit,
          child: Text(widget.alat == null ? "Tambah" : "Simpan"),
        ),
      ],
    );
  }
}
