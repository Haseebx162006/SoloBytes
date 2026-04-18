import 'package:flutter/material.dart';
import 'package:solobytes/Controllers/AuthController.dart';
import 'package:solobytes/UI/Auth/LoginScreen.dart';
import 'package:solobytes/Widgets/AuthButton.dart';
import 'package:solobytes/Widgets/AuthContainer.dart';

class signUP extends StatefulWidget {
  const signUP({super.key});

  @override
  State<signUP> createState() => _signUPState();
}

class _signUPState extends State<signUP> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final Authcontroller _authcontroller = Authcontroller();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  "SignUp To Echo",
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
                  "Create your credentials to start Chatting",
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
                  " Name",
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
                text: "Enter your name",
                obscureText: false,
                controller: nameController,
              ),

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
                text: "Sign Up",
                onpressed: () {
                  _authcontroller.signUp(
                    context,
                    nameController.text.trim(),
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );
                },
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
