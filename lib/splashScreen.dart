import 'dart:async';
import 'package:flutter/material.dart';
import 'package:solobytes/AuthWrapper.dart';

class splashScreen extends StatefulWidget {
  const splashScreen({super.key});

  @override
  State<splashScreen> createState() => _splashScreenState();
}

class _splashScreenState extends State<splashScreen> {
  double progress = 0;

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {
        progress += 0.02;
        if (progress >= 1) {
          timer.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AuthWrapper()),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 200),
          Center(
            child: SizedBox(
              height: 230,
              width: 260,
              child: Image.asset('lib/Assets/Images/splash.png'),
            ),
          ),
          SizedBox(height: 300),
          SizedBox(
            height: 2,
            width: 200,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade900),
            ),
          ),
          SizedBox(height: 16),
          Text(
            "INITIALIZING",
            style: TextStyle(
              fontSize: 15,
              fontFamily: "Poppins",
              fontWeight: FontWeight.w300,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
