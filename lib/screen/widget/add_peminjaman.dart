import 'package:flutter/material.dart';
import '../models/loan.dart';
import 'package:intl/intl.dart';

class AddPeminjamanDialog extends StatefulWidget {
  final Function(Loan) onAdd;
  final BuildContext parentContext; // 🔥 PENTING

  const AddPeminjamanDialog({
    super.key,
    required this.onAdd,
    required this.parentContext,
  });

  @override
  State<AddPeminjamanDialog> createState() => _AddPeminjamanDialogState();
}

class _AddPeminjamanDialogState extends State<AddPeminjamanDialog> {
  final userController = TextEditingController();
  final equipmentController = TextEditingController();
  final borrowController = TextEditingController();
  final returnController = TextEditingController();
  final descriptionController = TextEditingController();
  final dueController = TextEditingController();

  LoanStatus status = LoanStatus.menunggu;

  bool userError = false;
  bool equipmentError = false;
  bool borrowError = false;
  bool descriptionError = false;
  bool returnError = false;

  final _radius = BorderRadius.circular(8);

  OutlineInputBorder _border(BuildContext context) => OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          width: 1.5,
        ),
      );

  String statusText(LoanStatus s) => s.toString().split('.').last;

  // ================= DATE PICKER =================
  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // ================= SUCCESS POPUP =================
  void _showSuccessPopup() {
    showDialog(
      context: widget.parentContext, // ✅ PARENT CONTEXT
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      Navigator.of(widget.parentContext).pop(),
                ),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.check_circle,
                  size: 72, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                "Peminjaman Berhasil Ditambahkan",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= SUBMIT =================
  void _submit() {
    setState(() {
      userError = userController.text.trim().isEmpty;
      equipmentError = equipmentController.text.trim().isEmpty;
      borrowError = borrowController.text.trim().isEmpty;
      returnError = returnController.text.trim().isEmpty;
      descriptionError = descriptionController.text.trim().isEmpty;
    });

    if (userError || equipmentError || borrowError || returnError || descriptionError) return;

    final loan = Loan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: userController.text.trim(),
      equipmentName: equipmentController.text.trim(),
      borrowDate: borrowController.text,
      returnDate: returnController.text,
      dueDate: returnController.text,
      description: returnController.text,
      status: status,
    );

    widget.onAdd(loan);

    // ✅ Tutup dialog form
    Navigator.of(context).pop();

    // ✅ Tampilkan popup success (AMAN)
    Future.microtask(_showSuccessPopup);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text("Tambah Peminjaman",
                    style: theme.textTheme.headlineSmall),
              ),
              const SizedBox(height: 16),

              _label("Nama Peminjam", theme),
              _textField(userController),
              if (userError) _error("Nama peminjam wajib diisi", theme),

              const SizedBox(height: 12),

              _label("Nama Alat", theme),
              _textField(equipmentController),
              if (equipmentError) _error("Nama alat wajib diisi", theme),

              const SizedBox(height: 12),

              _label("Tanggal Pinjam", theme),
              _dateField(borrowController, "Pilih tanggal pinjam"),
              if (borrowError) _error("Tanggal pinjam wajib diisi", theme),

              const SizedBox(height: 12),

              _label("Tanggal Kembali", theme),
              _dateField(returnController, "Pilih tanggal kembali"),
              if (returnError) _error("Tanggal kembali wajib diisi", theme),

              const SizedBox(height: 12),

              _label("Dikembalikan", theme),
              _dateField(dueController, "Tanggal kembali"),

              const SizedBox(height: 12),

              _label("Deskripsi", theme),
              _textField(descriptionController),
              if (descriptionError) _error("Deskripsi wajib diisi", theme),

              const SizedBox(height: 12),

              _label("Status", theme),
              _statusDropdown(context),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text("Tambah"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
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

  // ================= COMPONENTS =================
  Widget _label(String text, ThemeData theme) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: theme.textTheme.bodyLarge),
      );

  Widget _textField(TextEditingController c) => TextField(
        controller: c,
        decoration: InputDecoration(
          border: _border(context),
          enabledBorder: _border(context),
          focusedBorder: _border(context),
        ),
      );

  Widget _dateField(TextEditingController c, String hint) => TextField(
        controller: c,
        readOnly: true,
        onTap: () => _pickDate(c),
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: const Icon(Icons.calendar_month),
          border: _border(context),
          enabledBorder: _border(context),
          focusedBorder: _border(context),
        ),
      );

  Widget _statusDropdown(BuildContext context) =>
      DropdownButtonFormField<LoanStatus>(
        initialValue: status,
        decoration: InputDecoration(
          border: _border(context),
          enabledBorder: _border(context),
          focusedBorder: _border(context),
        ),
        items: LoanStatus.values
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(statusText(s)),
                ))
            .toList(),
        onChanged: (v) => setState(() => status = v!),
      );

  Widget _error(String text, ThemeData theme) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style: theme.textTheme.bodySmall!
              .copyWith(color: Colors.red, fontSize: 11),
        ),
      );
}
