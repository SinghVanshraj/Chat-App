import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';
import '../main.dart' show connectGlobalSocket;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form     = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool    _loading = false;
  String? _error;

  @override
  void dispose() { _userCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthService.loginUser(
        _userCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      await connectGlobalSocket();         
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/directMessages');
    } else {
      setState(() => _error = result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: AppColor.surface2,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColor.border)),
                    child: const Icon(Icons.arrow_back,
                        color: AppColor.textSecondary, size: 20),
                  ),
                ),
                const SizedBox(height: 28),
                const Text('Welcome back',
                    style: TextStyle(
                        color: AppColor.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Sign in to your account',
                    style: TextStyle(
                        color: AppColor.textSecondary, fontSize: 14)),
                const SizedBox(height: 36),
                AppTextField(
                  label: 'Username', hint: 'Enter your username',
                  prefixIcon: Icons.person_outline, controller: _userCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Username is required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password', hint: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  controller: _passCtrl, isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'At least 8 characters';
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  ErrorBanner(message: _error!),
                ],
                const SizedBox(height: 28),
                AppButton(
                    text: 'Sign In', isLoading: _loading, onPressed: _login),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ",
                        style: TextStyle(
                            color: AppColor.textHint, fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                          context, '/register'),
                      child: const Text('Sign up',
                          style: TextStyle(
                              color: AppColor.primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
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
