import 'package:flutter/material.dart';

class AuthButton extends StatefulWidget {
  final String text;
  final VoidCallback? onpressed;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.text,
    required this.onpressed,
    this.isLoading = false,
  });

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onpressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xff546A2F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: widget.isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                widget.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: "Poppins",
                ),
              ),
      ),
    );
  }
}
