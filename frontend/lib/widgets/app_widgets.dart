import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AppTextField extends StatefulWidget {
  final String label, hint;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.controller,
    this.isPassword   = false,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColor.textSecondary,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller:    widget.controller,
          obscureText:   widget.isPassword && _obscure,
          keyboardType:  widget.keyboardType,
          validator:     widget.validator,
          style: const TextStyle(color: AppColor.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText:  widget.hint,
            hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 14),
            prefixIcon: Icon(widget.prefixIcon, color: AppColor.textHint, size: 20),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppColor.textHint,
                        size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
            filled:      true,
            fillColor:   AppColor.surface2,
            border:            OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColor.border)),
            enabledBorder:     OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColor.border)),
            focusedBorder:     OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColor.primaryColor, width: 1.5)),
            errorBorder:       OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColor.error)),
            focusedErrorBorder:OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColor.error, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading, isOutlined;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading  = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side:  const BorderSide(color: AppColor.primaryColor, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(text,
                  style: const TextStyle(
                      color: AppColor.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                disabledBackgroundColor: AppColor.primaryColor.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
            ),
    );
  }
}

class AvatarWidget extends StatelessWidget {
  final String username;
  final double size;
  final bool   isOnline;

  const AvatarWidget({
    super.key,
    required this.username,
    this.size     = 46,
    this.isOnline = false,
  });

  Color _color(String name) {
    const colors = [
      Color(0xFF7C3AED), Color(0xFF0EA5E9), Color(0xFF10B981),
      Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFFEC4899),
    ];
    return colors[(name.isNotEmpty ? name.codeUnitAt(0) : 0) % colors.length];
  }

  String get _initials {
    final t = username.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return t.substring(0, t.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
              color: _color(username).withOpacity(0.2),
              shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(_initials,
              style: TextStyle(
                  color: _color(username),
                  fontWeight: FontWeight.w600,
                  fontSize: size * 0.32)),
        ),
        if (isOnline)
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: size * 0.28, height: size * 0.28,
              decoration: BoxDecoration(
                  color: AppColor.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.background, width: 2)),
            ),
          ),
      ],
    );
  }
}

class MessageStatusIcon extends StatelessWidget {
  final String status;
  const MessageStatusIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'read':
        return const Icon(Icons.done_all, size: 14, color: AppColor.primaryColor);
      case 'delivered':
        return Icon(Icons.done_all, size: 14, color: Colors.white.withOpacity(0.6));
      default:
        return Icon(Icons.done,     size: 14, color: Colors.white.withOpacity(0.5));
    }
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:  AppColor.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColor.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: AppColor.error, fontSize: 13))),
        ],
      ),
    );
  }
}
