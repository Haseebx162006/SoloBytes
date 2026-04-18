import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/UI/Auth/LoginScreen.dart';
import 'package:solobytes/UI/Auth/SignUpScreen.dart';
import 'package:solobytes/UI/DashboardScreen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(authAccessStateProvider);

    return accessState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const LoginScreen(),
      data: (state) {
        if (state == AuthAccessState.unauthenticated) {
          return const LoginScreen();
        }

        if (state == AuthAccessState.needsBusinessSetup) {
          return const signUP();
        }

        if (state == AuthAccessState.authenticated) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
