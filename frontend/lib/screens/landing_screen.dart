import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/app_widgets.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.primaryColor,
                  boxShadow: [
                    BoxShadow(
                        color:  AppColor.primaryColor.withOpacity(0.4),
                        blurRadius: 32, spreadRadius: 4),
                  ],
                ),
                child: const Icon(Icons.chat_bubble_rounded,
                    color: Colors.white, size: 38),
              ),
              const SizedBox(height: 28),
              const Text(AppStrings.appName,
                  style: TextStyle(
                      color: AppColor.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5)),
              const SizedBox(height: 10),
              const Text(
                'Simple, fast, and secure messaging.\nConnect with anyone, anywhere.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColor.textSecondary, fontSize: 15, height: 1.6),
              ),
              const Spacer(),
              AppButton(
                  text: 'Sign In',
                  onPressed: () => Navigator.pushNamed(context, '/login')),
              const SizedBox(height: 12),
              AppButton(
                  text: 'Create Account',
                  isOutlined: true,
                  onPressed: () => Navigator.pushNamed(context, '/register')),
              const SizedBox(height: 32),
              const Text(AppStrings.tagline,
                  style: TextStyle(color: AppColor.textHint, fontSize: 12)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
