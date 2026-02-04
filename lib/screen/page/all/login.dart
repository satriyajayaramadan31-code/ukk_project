import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../../service/supabase_service.dart';
import 'dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _usernameError;
  String? _passwordError;

  late final AnimationController _usernameShakeController;
  late final AnimationController _passwordShakeController;

  late final Animation<Offset> _usernameShake;
  late final Animation<Offset> _passwordShake;

  @override
  void initState() {
    super.initState();

    _usernameShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _passwordShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _usernameShake = _shake(_usernameShakeController);
    _passwordShake = _shake(_passwordShakeController);
  }

  Animation<Offset> _shake(AnimationController controller) {
    return TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(-0.04, 0)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-0.04, 0), end: const Offset(0.04, 0)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.04, 0), end: Offset.zero),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _usernameError = null;
      _passwordError = null;
    });

    if (username.isEmpty) {
      _usernameShakeController.forward(from: 0);
      setState(() => _usernameError = 'Username wajib diisi');
      return;
    }

    if (password.isEmpty) {
      _passwordShakeController.forward(from: 0);
      setState(() => _passwordError = 'Password wajib diisi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await SupabaseService.login(
        username: username,
        password: password,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            });

            return const AlertDialog(
              title: Text('Berhasil'),
              content: Text('Login berhasil'),
            );
          },
        );

        await Future.delayed(const Duration(milliseconds: 1300));
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardPage(role: result['role']),
          ),
        );
      } else {
        final message = (result['message'] ?? 'Login gagal').toString();

        if (message.toLowerCase().contains('username')) {
          _usernameShakeController.forward(from: 0);
          setState(() => _usernameError = message);
        } else {
          _passwordShakeController.forward(from: 0);
          setState(() => _passwordError = message);
        }
      }
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameShakeController.dispose();
    _passwordShakeController.dispose();
    super.dispose();
  }

  // Widget input + shake + error text
  Widget _shakeField({
    required Animation<Offset> shake,
    required TextEditingController controller,
    required String hint,
    required String? errorText,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 48,
            child: SlideTransition(
              position: shake,
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                onSubmitted: onSubmitted,
                decoration: InputDecoration(
                  hintText: hint,
                  isDense: true,
                  suffixIcon: suffixIcon,
                ),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: const TextStyle(
              color: AppTheme.statusLate,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Image.asset('image/logo.png'),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Mesin Kita',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Masuk ke akun Anda untuk melanjutkan',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),

                      /// USERNAME
                      _shakeField(
                        shake: _usernameShake,
                        controller: _usernameController,
                        hint: 'Username',
                        errorText: _usernameError,
                      ),

                      SizedBox(height: _usernameError != null ? 14 : 16),

                      /// PASSWORD
                      _shakeField(
                        shake: _passwordShake,
                        controller: _passwordController,
                        hint: 'Password',
                        errorText: _passwordError,
                        obscureText: _obscurePassword,
                        onSubmitted: (_) => _handleLogin(),
                        suffixIcon: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}
