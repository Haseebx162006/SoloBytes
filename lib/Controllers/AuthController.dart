import 'package:flutter/material.dart';
import 'package:solobytes/Services/AuthService.dart';

class Authcontroller {
  final AuthService _authService = AuthService();

  Future<void> LogOut(BuildContext context) async {
    try {
      await _authService.LogOut();
      if (!context.mounted) {
        return;
      }
      final snackBar = const SnackBar(content: Text("Logged Out Successfully"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> signIn(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final error = await _authService.signIn(email, password);
      if (!context.mounted) {
        return;
      }
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        return;
      }

      final snackBar = const SnackBar(content: Text("Login Successful"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> signUp(
    BuildContext context,
    String name,
    String email,
    String password,
  ) async {
    try {
      final error = await _authService.signUp(name, email, password);
      if (!context.mounted) {
        return;
      }
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        return;
      }

      final snackBar = const SnackBar(content: Text("Sign Up Successful"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
