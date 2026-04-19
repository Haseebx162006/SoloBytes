import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/Providers/locale_provider.dart';
import 'package:solobytes/theme/app_colors.dart';
import 'package:solobytes/theme/app_text_styles.dart';

final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((
  ref,
) async {
  final user = ref.watch(authUserProvider);
  if (user == null || user.uid.isEmpty) return null;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  if (doc.exists) {
    return doc.data();
  }
  return null;
});

class ProfileTab extends ConsumerWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUrdu = ref.watch(isUrduProvider);
    final user = ref.watch(authUserProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: userProfileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Text(
            isUrdu ? 'پروفائل لوڈ کرنے میں خرابی' : 'Error loading profile',
            style: AppTextStyles.body.copyWith(color: AppColors.error),
          ),
        ),
        data: (profileData) {
          final fullName =
              profileData?['fullName'] as String? ??
              user?.email?.split('@').first ??
              'User';
          final businessName = profileData?['businessName'] as String? ?? 'N/A';
          final businessEmail =
              profileData?['businessEmail'] as String? ?? user?.email ?? 'N/A';
          final businessType = profileData?['businessType'] as String? ?? 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              children: [
                // Header with Avatar
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primarySurface,
                          border: Border.all(
                            color: AppColors.primary.withAlpha(50),
                            width: 2,
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            Icons.person_rounded,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(fullName, style: AppTextStyles.heading2),
                      const SizedBox(height: 4),
                      Text(
                        businessName,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Info Cards
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.storefront_rounded,
                        label: isUrdu ? 'کاروبار کا نام' : 'Business Name',
                        value: businessName,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: AppColors.divider, height: 1),
                      ),
                      _buildInfoRow(
                        icon: Icons.email_outlined,
                        label: isUrdu ? 'ای میل' : 'Email Address',
                        value: businessEmail,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: AppColors.divider, height: 1),
                      ),
                      _buildInfoRow(
                        icon: Icons.category_outlined,
                        label: isUrdu ? 'کاروبار کی قسم' : 'Business Type',
                        value: businessType,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Urdu Toggle Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySurface,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.translate_rounded),
                    label: Text(
                      isUrdu ? 'Switch to English' : 'اردو میں تبدیل کریں',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    onPressed: () {
                      ref.read(isUrduProvider.notifier).state = !isUrdu;
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
