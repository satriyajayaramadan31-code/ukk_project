import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../page/alat.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

class BorrowRequest extends StatefulWidget {
  final Equipment equipment;
  final VoidCallback onSubmit;

  const BorrowRequest({
    super.key,
    required this.equipment,
    required this.onSubmit,
  });

  @override
  State<BorrowRequest> createState() => _BorrowRequestState();
}

class _BorrowRequestState extends State<BorrowRequest> {
  final _formKey = GlobalKey<FormState>();

  DateTime? borrowDate;
  DateTime? returnDate;
  String purpose = "";

  bool isSubmitting = false;

  final TextEditingController borrowController = TextEditingController();
  final TextEditingController returnController = TextEditingController();

  final _radius = BorderRadius.circular(8);

  OutlineInputBorder _border(BuildContext context) => OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          width: 1.5,
        ),
      );

  Future<void> _pickDate(BuildContext context, bool isBorrow) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        if (isBorrow) {
          borrowDate = picked;
          borrowController.text = "${picked.day}/${picked.month}/${picked.year}";
        } else {
          returnDate = picked;
          returnController.text =
              "${picked.day}/${picked.month}/${picked.year}";
        }
      });
    }
  }

  String _toSqlDate(DateTime dt) {
    // format: YYYY-MM-DD
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  void _showPopup({
    required IconData icon,
    required String text,
    required VoidCallback onDone,
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
      onDone();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (borrowDate == null || returnDate == null) return;

    // validasi tanggal
    if (returnDate!.isBefore(borrowDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tanggal kembali harus setelah pinjam")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final userId = await SupabaseService.getUserId();
      if (userId == null) {
        throw Exception("User belum login");
      }

      final alatId = int.tryParse(widget.equipment.id);
      if (alatId == null) {
        throw Exception("ID alat tidak valid");
      }

      await SupabaseService.addPeminjaman(
        userId: userId,
        alatId: alatId,
        tanggalPinjam: _toSqlDate(borrowDate!),
        tanggalKembali: _toSqlDate(returnDate!),
        tanggalPengembalian: null,
        alasan: purpose,
        status: "menunggu", // sesuai sistem kamu
      );

      if (!mounted) return;

      // tutup dialog form
      Navigator.pop(context);

      // popup sukses
      _showPopup(
        icon: Icons.check_circle,
        text: "Permintaan Berhasil\nDikirim",
        onDone: () {
          widget.onSubmit(); // refresh halaman alat
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengirim permintaan: $e")),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  void dispose() {
    borrowController.dispose();
    returnController.dispose();
    super.dispose();
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    "Ajukan Peminjaman",
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 16),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Image.network(
                    widget.equipment.image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        const Icon(Icons.broken_image),
                  ),
                  title: Text(widget.equipment.name),
                  subtitle: Text(widget.equipment.category),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: borrowController,
                  readOnly: true,
                  onTap: () => _pickDate(context, true),
                  decoration: InputDecoration(
                    labelText: "Tanggal Pinjam",
                    hintText: "Pilih tanggal",
                    border: _border(context),
                    enabledBorder: _border(context),
                    focusedBorder: _border(context),
                    suffixIcon: const Icon(Icons.calendar_month),
                  ),
                  validator: (value) {
                    if (borrowDate == null) return "Tanggal pinjam wajib diisi";
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: returnController,
                  readOnly: true,
                  onTap: () => _pickDate(context, false),
                  decoration: InputDecoration(
                    labelText: "Tanggal Kembali",
                    hintText: "Pilih tanggal",
                    border: _border(context),
                    enabledBorder: _border(context),
                    focusedBorder: _border(context),
                    suffixIcon: const Icon(Icons.calendar_month),
                  ),
                  validator: (value) {
                    if (returnDate == null) return "Tanggal kembali wajib diisi";
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Tujuan Peminjaman",
                    hintText: "Jelaskan tujuan peminjaman...",
                    border: _border(context),
                    enabledBorder: _border(context),
                    focusedBorder: _border(context),
                  ),
                  onChanged: (value) => purpose = value,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Tujuan wajib diisi";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("Ajukan"),
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
                        onPressed:
                            isSubmitting ? null : () => Navigator.pop(context),
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
      ),
    );
  }
}
