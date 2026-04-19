import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/UI/Auth/EmailSignUpScreen.dart';
import 'package:solobytes/Widgets/AuthButton.dart';
import 'package:solobytes/Widgets/AuthContainer.dart';
import 'package:solobytes/theme/app_colors.dart';
import 'package:solobytes/theme/app_text_styles.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String _friendlyMessage(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    final lower = raw.toLowerCase();

    if (lower.contains('invalid credentials') ||
        lower.contains('invalid-credential') ||
        lower.contains('wrong password') ||
        lower.contains('wrong-password') ||
        lower.contains('user not found') ||
        lower.contains('user-not-found')) {
      return 'Invalid credentials';
    }

    if (lower.contains('cancelled') || lower.contains('popup-closed-by-user')) {
      return 'Google sign-in was cancelled.';
    }

    if (raw.isEmpty) {
      return 'Login failed';
    }

    return raw;
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    if (ref.read(authActionLoadingProvider)) {
      return;
    }

    ref.read(authActionLoadingProvider.notifier).start();

    try {
      await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyMessage(error))));
    } finally {
      if (mounted) {
        ref.read(authActionLoadingProvider.notifier).stop();
      }
    }
  }

  Future<void> _signInWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required')),
      );
      return;
    }

    await _runAuthAction(() async {
      await ref.read(loginUseCaseProvider).executeEmail(email, password);
    });
  }

  Future<void> _signInWithGoogle() async {
    await _runAuthAction(() async {
      await ref.read(loginUseCaseProvider).executeGoogle();
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authActionLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // ── Green accent icon ────────────────────
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Titles ──────────────────────────────
                Center(
                  child: Text(
                    'Welcome Back',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Sign In to CashPilot',
                    style: AppTextStyles.heading1.copyWith(fontSize: 26),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Enter your credentials to grow your business',
                    style: AppTextStyles.subtitle,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Email Field ─────────────────────────
                const Text(' Email', style: AppTextStyles.label),
                const SizedBox(height: 8),
                AuthContainer(
                  text: 'Enter your email',
                  obscureText: false,
                  controller: emailController,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),

                // ── Password Field ──────────────────────
                const Text(' Password', style: AppTextStyles.label),
                const SizedBox(height: 8),
                AuthContainer(
                  text: 'Enter your password',
                  obscureText: true,
                  controller: passwordController,
                  prefixIcon: Icons.lock_outline,
                ),
                const SizedBox(height: 32),

                // ── Sign In Button ──────────────────────
                AuthButton(
                  text: 'Sign In',
                  isLoading: isLoading,
                  onpressed: isLoading ? null : _signInWithEmail,
                ),
                const SizedBox(height: 24),

                // ── Sign Up Link ────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EmailSignUpScreen(),
                          ),
                        );
                      },
                      child: const Text('Sign Up', style: AppTextStyles.link),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Divider ─────────────────────────────
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.border, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or continue with',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.border, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Google Button ────────────────────────
                AbsorbPointer(
                  absorbing: isLoading,
                  child: Opacity(
                    opacity: isLoading ? 0.6 : 1,
                    child: AuthButton(
                      text: 'Sign in with Google',
                      isLoading: false,
                      isOutlined: true,
                      icon: Icons.g_mobiledata,
                      onpressed: _signInWithGoogle,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
