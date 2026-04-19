import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/Widgets/AuthButton.dart';
import 'package:solobytes/Widgets/AuthContainer.dart';
import 'package:solobytes/theme/app_colors.dart';
import 'package:solobytes/theme/app_text_styles.dart';

class signUP extends ConsumerStatefulWidget {
  const signUP({super.key});

  @override
  ConsumerState<signUP> createState() => _signUPState();
}

class _signUPState extends ConsumerState<signUP> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController businessTypeController = TextEditingController();

  String _friendlyMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) {
      return 'Unable to save business profile';
    }
    return message;
  }

  Future<void> _saveBusinessProfile() async {
    if (ref.read(businessSetupProvider)) {
      return;
    }

    final user = ref.read(authUserProvider);
    if (user == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in with Google first.')),
      );
      return;
    }

    ref.read(businessSetupProvider.notifier).start();

    try {
      await ref
          .read(saveBusinessProfileUseCaseProvider)
          .execute(
            userId: user.uid,
            businessName: nameController.text,
            businessType: businessTypeController.text,
            businessEmail: emailController.text.trim().isEmpty
                ? null
                : emailController.text.trim(),
          );

      ref.invalidate(businessProfileProvider);
      ref.invalidate(authAccessStateProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile saved successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyMessage(error))));
    } finally {
      if (mounted) {
        ref.read(businessSetupProvider.notifier).stop();
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    businessTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(businessSetupProvider);

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
                      Icons.storefront_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Titles ──────────────────────────────
                Center(
                  child: Text(
                    'Business Setup',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Complete Your Profile',
                    style: AppTextStyles.heading1.copyWith(fontSize: 26),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Add business details to continue',
                    style: AppTextStyles.subtitle,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Business Name ───────────────────────
                const Text(' Business Name', style: AppTextStyles.label),
                const SizedBox(height: 8),
                AuthContainer(
                  text: 'Enter business name',
                  obscureText: false,
                  controller: nameController,
                  prefixIcon: Icons.business_outlined,
                ),
                const SizedBox(height: 20),

                // ── Business Email ──────────────────────
                const Text(
                  ' Business Email (Optional)',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 8),
                AuthContainer(
                  text: 'Enter business email',
                  obscureText: false,
                  controller: emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // ── Type of Business ────────────────────
                const Text(' Type of Business', style: AppTextStyles.label),
                const SizedBox(height: 8),
                AuthContainer(
                  text: 'Enter business type',
                  obscureText: false,
                  controller: businessTypeController,
                  prefixIcon: Icons.category_outlined,
                ),
                const SizedBox(height: 32),

                // ── Save Button ─────────────────────────
                AuthButton(
                  text: 'Save & Continue',
                  isLoading: isLoading,
                  onpressed: isLoading ? null : _saveBusinessProfile,
                ),
                const SizedBox(height: 24),

                // ── Sign Out Link ───────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Use another account? ',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await ref.read(authRepositoryProvider).signOut();
                      },
                      child: const Text('Sign Out', style: AppTextStyles.link),
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
                AuthButton(
                  text: 'Google',
                  isOutlined: true,
                  icon: Icons.g_mobiledata,
                  onpressed: () {},
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
