import 'package:flutter/material.dart';
import '../page/user.dart';

class EditUserDialog extends StatefulWidget {
  final User user;
  final Function(String username, String role, String password) onSubmit;

  const EditUserDialog({
    super.key,
    required this.user,
    required this.onSubmit,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late TextEditingController usernameController;
  late TextEditingController passwordController;

  String role = "peminjam";

  bool usernameError = false;
  bool passwordError = false;

  final _radius = BorderRadius.circular(8);

  OutlineInputBorder _border(BuildContext context) => OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          width: 1.5,
        ),
      );

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.user.username);
    passwordController = TextEditingController(text: widget.user.password);
    role = widget.user.role;
  }

  // ================= POPUP =================
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
      usernameError = usernameController.text.trim().isEmpty;
      passwordError = passwordController.text.trim().isEmpty;
    });

    if (usernameError || passwordError) return;

    widget.onSubmit(
      usernameController.text.trim(),
      role,
      passwordController.text.trim(),
    );

    Navigator.pop(context);

    _showPopup(
      icon: Icons.check_circle,
      text: "User Berhasil\nDiperbarui",
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        "Edit User",
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _label("Username", theme),
              _textField(usernameController),
              if (usernameError) _error("Username wajib diisi", theme),

              const SizedBox(height: 12),

              _label("Role", theme),
              _roleDropdown(context),

              const SizedBox(height: 12),

              _label("Password", theme),
              _textField(passwordController, isPassword: true),
              if (passwordError) _error("Password wajib diisi", theme),

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
      decoration: InputDecoration(
        border: _border(context),
        enabledBorder: _border(context),
        focusedBorder: _border(context),
      ),
    );
  }

  Widget _roleDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: role,
      decoration: InputDecoration(
        border: _border(context),
        enabledBorder: _border(context),
        focusedBorder: _border(context),
      ),
      items: const [
        DropdownMenuItem(value: "admin", child: Text("Admin")),
        DropdownMenuItem(value: "petugas", child: Text("Petugas")),
        DropdownMenuItem(value: "peminjam", child: Text("Peminjam")),
      ],
      onChanged: (v) => setState(() => role = v!),
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
