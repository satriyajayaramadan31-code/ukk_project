import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

class AddPeminjamanDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  final BuildContext parentContext;

  const AddPeminjamanDialog({
    super.key,
    required this.onAdd,
    required this.parentContext,
  });

  @override
  State<AddPeminjamanDialog> createState() => _AddPeminjamanDialogState();
}

class _AddPeminjamanDialogState extends State<AddPeminjamanDialog> {
  // controllers
  final userController = TextEditingController();
  final equipmentController = TextEditingController();
  final borrowController = TextEditingController();
  final returnController = TextEditingController();
  final dueController = TextEditingController();
  final descriptionController = TextEditingController();

  // selected ids (IMPORTANT)
  int? _selectedUserId;
  int? _selectedAlatId;

  bool userError = false;
  bool equipmentError = false;
  bool borrowError = false;
  bool returnError = false;
  bool descriptionError = false;

  bool _loading = false;

  final _radius = BorderRadius.circular(8);

  // status valid
  final List<String> _statuses = const [
    'menunggu',
    'diproses',
    'dipinjam',
    'dikembalikan',
    'terlambat',
    'ditolak',
  ];

  String status = 'menunggu';

  // data autocomplete
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _alatList = [];

  @override
  void initState() {
    super.initState();
    _loadAutocompleteData();
  }

  Future<void> _loadAutocompleteData() async {
    try {
      final users = await SupabaseService.getUsers();
      final alat = await SupabaseService.getAlatList();

      // ✅ filter hanya user role peminjam
      final peminjamUsers = users.where((u) {
        final role = (u['role'] ?? '').toString().toLowerCase().trim();
        return role == 'peminjam';
      }).toList();

      if (!mounted) return;
      setState(() {
        _users = peminjamUsers;
        _alatList = alat;
      });
    } catch (e) {
      debugPrint("❌ LOAD AUTOCOMPLETE ERROR: $e");
    }
  }

  OutlineInputBorder _border(BuildContext context) => OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          width: 1.5,
        ),
      );

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final initial =
        controller.text.isEmpty ? now : DateTime.tryParse(controller.text) ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  void _showSuccessPopup() {
    showDialog(
      context: widget.parentContext,
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
                  onPressed: () => Navigator.of(widget.parentContext).pop(),
                ),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.check_circle, size: 72, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                "Peminjaman Berhasil Ditambahkan",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      userError = _selectedUserId == null;
      equipmentError = _selectedAlatId == null;
      borrowError = borrowController.text.trim().isEmpty;
      returnError = returnController.text.trim().isEmpty;
      descriptionError = descriptionController.text.trim().isEmpty;
    });

    if (userError || equipmentError || borrowError || returnError || descriptionError) {
      return;
    }

    setState(() => _loading = true);

    try {
      final normalizedStatus = status.toLowerCase().trim();
      final safeStatus = _statuses.contains(normalizedStatus) ? normalizedStatus : 'menunggu';

      final inserted = await SupabaseService.addPeminjaman(
        userId: _selectedUserId!,
        alatId: _selectedAlatId!,
        tanggalPinjam: borrowController.text.trim(),
        tanggalKembali: returnController.text.trim(),
        tanggalPengembalian:
            dueController.text.trim().isEmpty ? null : dueController.text.trim(),
        alasan: descriptionController.text.trim(),
        status: safeStatus,
      );

      widget.onAdd(inserted);

      if (!mounted) return;
      Navigator.of(context).pop();

      Future.microtask(_showSuccessPopup);
    } catch (e) {
      debugPrint('❌ ADD PEMINJAMAN ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal tambah peminjaman: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentStatus = _statuses.contains(status) ? status : 'menunggu';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: theme.colorScheme.background,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text("Tambah Peminjaman", style: theme.textTheme.headlineSmall),
              ),
              const SizedBox(height: 16),

              _label("Nama Peminjam", theme),
              _userAutocomplete(),
              if (userError) _error("Pilih user dari daftar", theme),

              const SizedBox(height: 12),

              _label("Nama Alat", theme),
              _alatAutocomplete(),
              if (equipmentError) _error("Pilih alat dari daftar", theme),

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
              _dateField(dueController, "Tanggal pengembalian (opsional)"),

              const SizedBox(height: 12),

              _label("Deskripsi / Alasan", theme),
              _textField(descriptionController),
              if (descriptionError) _error("Deskripsi wajib diisi", theme),

              const SizedBox(height: 12),

              _label("Status", theme),
              _statusDropdown(value: currentStatus),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Tambah"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

  // ================= FIXED AUTOCOMPLETE =================

  Widget _userAutocomplete() {
    return Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.toLowerCase().trim();
        if (query.isEmpty) return const Iterable<Map<String, dynamic>>.empty();

        return _users.where((u) {
          final username = (u['username'] ?? '').toString().toLowerCase();
          return username.contains(query);
        });
      },
      displayStringForOption: (opt) => opt['username'].toString(),
      onSelected: (opt) {
        setState(() {
          _selectedUserId = (opt['id'] as num).toInt();
          userError = false;
        });
        userController.text = opt['username'].toString();
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: "Ketik nama user peminjam...",
            border: _border(context),
            enabledBorder: _border(context),
            focusedBorder: _border(context),
          ),
          onChanged: (v) {
            userController.text = v;
            setState(() => _selectedUserId = null);
          },
        );
      },
    );
  }

  Widget _alatAutocomplete() {
    return Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.toLowerCase().trim();
        if (query.isEmpty) return const Iterable<Map<String, dynamic>>.empty();

        return _alatList.where((a) {
          final nama = (a['nama_alat'] ?? '').toString().toLowerCase();
          return nama.contains(query);
        });
      },
      displayStringForOption: (opt) => opt['nama_alat'].toString(),
      onSelected: (opt) {
        setState(() {
          _selectedAlatId = (opt['id'] as num).toInt();
          equipmentError = false;
        });
        equipmentController.text = opt['nama_alat'].toString();
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: "Ketik nama alat...",
            border: _border(context),
            enabledBorder: _border(context),
            focusedBorder: _border(context),
          ),
          onChanged: (v) {
            equipmentController.text = v;
            setState(() => _selectedAlatId = null);
          },
        );
      },
    );
  }

  Widget _statusDropdown({required String value}) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        border: _border(context),
        enabledBorder: _border(context),
        focusedBorder: _border(context),
      ),
      items: _statuses.map((s) {
        final label = s[0].toUpperCase() + s.substring(1);
        return DropdownMenuItem(value: s, child: Text(label));
      }).toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() => status = v);
      },
    );
  }

  Widget _error(String text, ThemeData theme) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style: theme.textTheme.bodySmall!.copyWith(
            color: Colors.red,
            fontSize: 15,
          ),
        ),
      );
}
