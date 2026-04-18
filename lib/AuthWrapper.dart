import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/UI/Auth/LoginScreen.dart';
import 'package:solobytes/UI/Auth/SignUpScreen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const LoginScreen(),
      data: (user) {
        if (user != null) {
          // Uses the current authenticated destination screen.
          return const signUP();
        }

        return const LoginScreen();
      },
    );
  }
}
