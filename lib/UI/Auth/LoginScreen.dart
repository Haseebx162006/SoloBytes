import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/UI/Auth/SignUpScreen.dart';
import 'package:solobytes/Widgets/AuthButton.dart';
import 'package:solobytes/Widgets/AuthContainer.dart';

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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 25),
              Align(
                alignment: Alignment.topCenter,
                child: Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: "Poppins",
                  ),
                ),
              ),
              SizedBox(height: 25),
              Align(
                alignment: Alignment.topCenter,
                child: Text(
                  "Sign In to CashPilot",
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.black,
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 15),
              Align(
                alignment: Alignment.topCenter,
                child: Text(
                  "Enter your credentials to Grow your Business",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xff778462),
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 15),

              SizedBox(height: 15),

              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  " Email",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 8),
              AuthContainer(
                text: "Enter your email",
                obscureText: false,
                controller: emailController,
              ),
              SizedBox(height: 15),

              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  " Password",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 8),
              AuthContainer(
                text: "Enter your password",
                obscureText: true,
                controller: passwordController,
              ),
              SizedBox(height: 40),
              AuthButton(
                text: "Sign In",
                isLoading: isLoading,
                onpressed: isLoading ? null : _signInWithEmail,
              ),
              SizedBox(height: 35),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Dont have an account? ",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xff778462),
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => signUP()),
                      );
                    },
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xff546A2F),
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Color(0xff778462), thickness: 2),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "or Login with",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xff778462),
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.grey.shade500, thickness: 2),
                  ),
                ],
              ),
              SizedBox(height: 30),
              AbsorbPointer(
                absorbing: isLoading,
                child: Opacity(
                  opacity: isLoading ? 0.65 : 1,
                  child: GestureDetector(
                    onTap: _signInWithGoogle,
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xff778462), width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xff546A2F),
                                  ),
                                )
                              : const Icon(Icons.g_mobiledata, size: 28),
                          const SizedBox(width: 10),
                          const Text(
                            "Sign in with Google",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
