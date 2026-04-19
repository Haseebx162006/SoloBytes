import 'package:flutter/material.dart';
import 'package:solobytes/theme/app_colors.dart';
import 'package:solobytes/theme/app_text_styles.dart';

class AuthButton extends StatefulWidget {
  final String text;
  final VoidCallback? onpressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  const AuthButton({
    super.key,
    required this.text,
    required this.onpressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
  });

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => _animController.forward(),
      onTapUp: widget.isLoading ? null : (_) => _animController.reverse(),
      onTapCancel: widget.isLoading ? null : () => _animController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: widget.isOutlined
              ? OutlinedButton(
                  onPressed: widget.isLoading ? null : widget.onpressed,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.border,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _buildChild(isOutlined: true),
                )
              : ElevatedButton(
                  onPressed: widget.isLoading ? null : widget.onpressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withAlpha(150),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _buildChild(isOutlined: false),
                ),
        ),
      ),
    );
  }

  Widget _buildChild({required bool isOutlined}) {
    if (widget.isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: isOutlined ? AppColors.primary : Colors.white,
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 20),
          const SizedBox(width: 10),
          Text(
            widget.text,
            style: isOutlined
                ? AppTextStyles.button.copyWith(color: AppColors.textPrimary)
                : AppTextStyles.button,
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: isOutlined
          ? AppTextStyles.button.copyWith(color: AppColors.textPrimary)
          : AppTextStyles.button,
    );
  }
}
