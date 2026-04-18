import 'package:flutter/material.dart';

class AuthContainer extends StatefulWidget {
  final String text;
  final TextEditingController controller;
  final bool obscureText;

  const AuthContainer({
    super.key,
    required this.text,
    required this.obscureText,
    required this.controller,
  });

  @override
  State<AuthContainer> createState() => _AuthContainerState();
}

class _AuthContainerState extends State<AuthContainer> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.obscureText,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        hint: Text(
          widget.text,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xff778462),
            fontFamily: "Poppins",
            fontWeight: FontWeight.w500,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xff778462), width: 1),
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xff778462), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xff778462), width: 2),
        ),
      ),
    );
  }
}