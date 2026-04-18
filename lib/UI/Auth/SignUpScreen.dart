import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/UI/Auth/LoginScreen.dart';
import 'package:solobytes/Widgets/AuthButton.dart';
import 'package:solobytes/Widgets/AuthContainer.dart';

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
                  "Business Setup",
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
                  "Complete Your Profile",
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
                  "Add business details to continue",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xff778462),
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 15),

              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  " Business Name",
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
                text: "Enter business name",
                obscureText: false,
                controller: nameController,
              ),

              SizedBox(height: 15),

              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  " Business Email (Optional)",
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
                text: "Enter business email",
                obscureText: false,
                controller: emailController,
              ),
              SizedBox(height: 15),

              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  " Type of Business",
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
                text: "Enter business type",
                obscureText: false,
                controller: businessTypeController,
              ),
              SizedBox(height: 40),
              AuthButton(
                text: "Save & Continue",
                isLoading: isLoading,
                onpressed: isLoading ? null : _saveBusinessProfile,
              ),
              SizedBox(height: 35),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xff778462),
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Sign In",
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
                      "or continue with",
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
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xff778462), width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.g_mobiledata, size: 24),
                    SizedBox(width: 10),
                    Text(
                      "Google",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
