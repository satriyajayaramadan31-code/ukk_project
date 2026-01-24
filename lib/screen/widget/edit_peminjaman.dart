import 'package:flutter/material.dart';
import '../models/loan.dart';
import 'package:intl/intl.dart';

class EditPeminjamanDialog extends StatefulWidget {
  final Loan loan;
  final Function(Loan) onEdit;

  const EditPeminjamanDialog({
    super.key,
    required this.loan,
    required this.onEdit,
  });

  @override
  State<EditPeminjamanDialog> createState() => _EditPeminjamanDialogState();
}

class _EditPeminjamanDialogState extends State<EditPeminjamanDialog> {
  late TextEditingController userController;
  late TextEditingController equipmentController;
  late TextEditingController borrowController;
  late TextEditingController returnController;
  late TextEditingController dueController;
  late TextEditingController descriptionController;
  late LoanStatus status;

  bool userError = false;
  bool equipmentError = false;
  bool borrowError = false;
  bool descriptionError = false;

  final _radius = BorderRadius.circular(8);

  @override
  void initState() {
    super.initState();
    userController = TextEditingController(text: widget.loan.userName);
    equipmentController = TextEditingController(text: widget.loan.equipmentName);
    borrowController = TextEditingController(text: widget.loan.borrowDate);
    returnController = TextEditingController(text: widget.loan.returnDate);
    dueController = TextEditingController(text: widget.loan.dueDate);
    descriptionController = TextEditingController(text: widget.loan.description);
    status = widget.loan.status;
  }

  @override
  void dispose() {
    userController.dispose();
    equipmentController.dispose();
    borrowController.dispose();
    returnController.dispose();
    dueController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(BuildContext context) => OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          width: 1.5,
        ),
      );

  String statusText(LoanStatus status) => status.toString().split('.').last;

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.text.isEmpty
          ? now
          : DateTime.tryParse(controller.text) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  void _showPopup({
    required IconData icon,
    required String text,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final size = MediaQuery.of(context).size;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          child: SizedBox(
            width: size.width * 0.8,
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
                  const SizedBox(height: 12),
                  Icon(
                    icon,
                    size: 72,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  void _submit() {
    setState(() {
      userError = userController.text.trim().isEmpty;
      equipmentError = equipmentController.text.trim().isEmpty;
      borrowError = borrowController.text.trim().isEmpty;
      descriptionError = descriptionController.text.trim().isEmpty;
    });

    if (userError || equipmentError || borrowError || descriptionError) return;

    final updatedLoan = Loan(
      id: widget.loan.id,
      userName: userController.text.trim(),
      equipmentName: equipmentController.text.trim(),
      borrowDate: borrowController.text.trim(),
      returnDate: returnController.text.trim(), // nullable
      dueDate: dueController.text.trim(),
      description: descriptionController.text.trim(), // nullable
      status: status,
    );

    widget.onEdit(updatedLoan);
    Navigator.pop(context);

    _showPopup(
      icon: Icons.check_circle,
      text: "Peminjaman Berhasil\nDiedit",
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: theme.colorScheme.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  "Edit Peminjaman",
                  style: theme.textTheme.headlineSmall,
                ),
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
              _dateField(borrowController, "Pilih Tanggal Pinjam"),
              if (borrowError) _error("Tanggal pinjam wajib diisi", theme),

              const SizedBox(height: 12),

              _label("Tanggal Kembali", theme),
              _dateField(returnController, "Pilih Tanggal Kembali"),
              if (borrowError) _error("Tanggal kembali wajib diisi", theme),

              const SizedBox(height: 12),

              _label("Dikembalikan", theme),
              _dateField(dueController, "Pilih Tanggal Dikembalikan"),              

              const SizedBox(height: 12),

              _label("Deskripsi", theme),
              _textField(descriptionController),              
              if (descriptionError) _error("Deskripsi diisi", theme),

              const SizedBox(height: 12),


              _label("Status", theme),
              _statusDropdown(context),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Simpan"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Batal',
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _label(String text, ThemeData theme) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: theme.textTheme.bodyLarge,
        ),
      );

  Widget _textField(TextEditingController controller,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        border: _border(context),
        enabledBorder: _border(context),
        focusedBorder: _border(context),
      ),
    );
  }

  Widget _dateField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () => _pickDate(controller),
      decoration: InputDecoration(
        hintText: hint,
        border: _border(context),
        enabledBorder: _border(context),
        focusedBorder: _border(context),
        suffixIcon: const Icon(Icons.calendar_month),
      ),
    );
  }

  Widget _statusDropdown(BuildContext context) {
    return DropdownButtonFormField<LoanStatus>(
      value: status,
      decoration: InputDecoration(
        border: _border(context),
        enabledBorder: _border(context),
        focusedBorder: _border(context),
      ),
      items: LoanStatus.values
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(statusText(s)),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => status = v!),
    );
  }

  Widget _error(String text, ThemeData theme) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style: theme.textTheme.bodySmall!.copyWith(
            color: Colors.red,
            fontSize: 11,
          ),
        ),
      );
}
