import 'package:flutter/material.dart';
import 'package:ai_trip/data/signupData.dart';

class RelaxView extends StatefulWidget {
  final AnimationController animationController;
  final SignUpData signUpData;

  const RelaxView({
    super.key,
    required this.animationController,
    required this.signUpData,
  });

  @override
  State<RelaxView> createState() => RelaxViewState();
}

class RelaxViewState extends State<RelaxView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  String get email => _emailController.text.trim();
  String get password => _passwordController.text.trim();
  String get nickname => _nicknameController.text.trim();

  @override
  Widget build(BuildContext context) {
    final firstHalfAnimation =
        Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0)).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(0.0, 0.2, curve: Curves.fastOutSlowIn),
      ),
    );
    final secondHalfAnimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(-1, 0)).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(0.2, 0.4, curve: Curves.fastOutSlowIn),
      ),
    );
    final textAnimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(-2, 0)).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(0.2, 0.4, curve: Curves.fastOutSlowIn),
      ),
    );

    return SlideTransition(
      position: firstHalfAnimation,
      child: SlideTransition(
        position: secondHalfAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SlideTransition(
                position: textAnimation,
                child: Text(
                  "시작합시다!",
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 40),
              SlideTransition(
                position: textAnimation,
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "이메일",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: 16),
              SlideTransition(
                position: textAnimation,
                child: TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: "비밀번호",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ),
              SizedBox(height: 16),
              SlideTransition(
                position: textAnimation,
                child: TextField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    labelText: "닉네임",
                    border: OutlineInputBorder(),
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
