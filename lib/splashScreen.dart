import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solobytes/AuthWrapper.dart';
import 'package:solobytes/theme/app_colors.dart';
import 'package:solobytes/theme/app_text_styles.dart';

class splashScreen extends StatefulWidget {
  const splashScreen({super.key});

  @override
  State<splashScreen> createState() => _splashScreenState();
}

class _splashScreenState extends State<splashScreen>
    with SingleTickerProviderStateMixin {
  double progress = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        progress += 0.02;
        if (progress >= 1) {
          timer.cancel();
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const AuthWrapper(),
              transitionDuration: const Duration(milliseconds: 400),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.15),

              // ── Logo ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: SizedBox(
                  height: 120,
                  width: 140,
                  child: Image.asset(
                    'lib/Assets/Images/splash.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── App Name ────────────────────────────────
              Text(
                'CashPilot',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.primary,
                  fontSize: 26,
                  letterSpacing: 1.2,
                ),
              ),

              const Spacer(),

              // ── Progress ────────────────────────────────
              SizedBox(
                height: 3,
                width: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'INITIALIZING',
                style: AppTextStyles.caption.copyWith(
                  letterSpacing: 3,
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),

              SizedBox(height: size.height * 0.08),
            ],
          ),
        ),
      ),
    );
  }
}
