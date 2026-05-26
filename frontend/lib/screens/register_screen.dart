import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';
import '../main.dart' show connectGlobalSocket;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form      = GlobalKey<FormState>();
  final _userCtrl  = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool    _loading = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose(); _passCtrl.dispose(); _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthService.registerUser(
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
                        color: AppColor.surface2, shape: BoxShape.circle,
                        border: Border.all(color: AppColor.border)),
                    child: const Icon(Icons.arrow_back,
                        color: AppColor.textSecondary, size: 20),
                  ),
                ),
                const SizedBox(height: 28),
                const Text('Create account',
                    style: TextStyle(
                        color: AppColor.textPrimary,
                        fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Join and start messaging',
                    style: TextStyle(
                        color: AppColor.textSecondary, fontSize: 14)),
                const SizedBox(height: 36),
                AppTextField(
                  label: 'Username', hint: 'Choose a username',
                  prefixIcon: Icons.person_outline, controller: _userCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Username is required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password', hint: 'Minimum 8 characters',
                  prefixIcon: Icons.lock_outline,
                  controller: _passCtrl, isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'At least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirm password', hint: 'Re-enter password',
                  prefixIcon: Icons.lock_outline,
                  controller: _pass2Ctrl, isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm password';
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColor.textHint, size: 14),
                    SizedBox(width: 6),
                    Text('Password must be at least 8 characters',
                        style: TextStyle(color: AppColor.textHint, fontSize: 12)),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  ErrorBanner(message: _error!),
                ],
                const SizedBox(height: 28),
                AppButton(
                    text: 'Create Account',
                    isLoading: _loading,
                    onPressed: _register),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ',
                        style: TextStyle(
                            color: AppColor.textHint, fontSize: 13)),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text('Sign in',
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
