import 'package:flutter/material.dart';
import '../page/alat.dart';

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
          borrowController.text =
              "${picked.day}/${picked.month}/${picked.year}";
        } else {
          returnDate = picked;
          returnController.text =
              "${picked.day}/${picked.month}/${picked.year}";
        }
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: theme.colorScheme.surface,
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
                    if (value == null || value.isEmpty) {
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
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {

                            // TUTUP DIALOG PERTAMA
                            Navigator.pop(context);

                            // TAMPILKAN POPUP SUCCESS
                            _showPopup(
                              icon: Icons.check_circle,
                              text: "Permintaan Berhasil\nDikirim",
                              onDone: () {
                                widget.onSubmit();
                              },
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Ajukan"),
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
      ),
    );
  }
}
