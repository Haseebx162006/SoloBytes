import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/Widgets/AuthButton.dart';
import 'package:solobytes/Widgets/AuthContainer.dart';
import 'package:solobytes/theme/app_colors.dart';
import 'package:solobytes/theme/app_text_styles.dart';

class EmailSignUpScreen extends ConsumerStatefulWidget {
  const EmailSignUpScreen({super.key});

  @override
  ConsumerState<EmailSignUpScreen> createState() => _EmailSignUpScreenState();
}

class _EmailSignUpScreenState extends ConsumerState<EmailSignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _friendlyMessage(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isEmpty) {
      return 'Sign-up failed. Please try again.';
    }

    return raw;
  }

  Future<void> _submit() async {
    if (_isLoading) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name, email, and password are required.'),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters.'),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(email, password, name: name);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully.')),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Title Section ─────────────────────────
              Text(
                'Create Account',
                style: AppTextStyles.heading1.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your account and continue to business setup.',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 32),

              // ── Full Name ─────────────────────────────
              const Text(' Full Name', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AuthContainer(
                text: 'Enter your name',
                obscureText: false,
                controller: _nameController,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 20),

              // ── Email ─────────────────────────────────
              const Text(' Email', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AuthContainer(
                text: 'Enter your email',
                obscureText: false,
                controller: _emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // ── Password ──────────────────────────────
              const Text(' Password', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AuthContainer(
                text: 'Choose a password',
                obscureText: true,
                controller: _passwordController,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 20),

              // ── Confirm Password ──────────────────────
              const Text(' Confirm Password', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AuthContainer(
                text: 'Repeat your password',
                obscureText: true,
                controller: _confirmPasswordController,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 32),

              // ── Create Account Button ─────────────────
              AuthButton(
                text: 'Create Account',
                isLoading: _isLoading,
                onpressed: _isLoading ? null : _submit,
              ),
              const SizedBox(height: 24),

              // ── Sign In Link ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Sign In', style: AppTextStyles.link),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
