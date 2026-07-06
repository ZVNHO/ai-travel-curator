import 'package:flutter/material.dart';
import 'package:ai_trip/data/signupData.dart';

class CareView extends StatefulWidget {
  final AnimationController animationController;
  final SignUpData signUpData;
  @override
  final GlobalKey<CareViewState> key;

  const CareView({
    required this.key,
    required this.animationController,
    required this.signUpData,
  }) : super(key: key);

  @override
  CareViewState createState() => CareViewState();
}

class CareViewState extends State<CareView> {
  String? selectedGender;
  final TextEditingController ageController = TextEditingController();

  // 데이터를 외부에서 접근할 수 있게 getter 추가
  String? get gender => selectedGender;
  int? get age => int.tryParse(ageController.text.trim());

  @override
  Widget build(BuildContext context) {
    final firstHalfAnimation =
        Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0)).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(0.2, 0.4, curve: Curves.fastOutSlowIn),
      ),
    );
    final secondHalfAnimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(-1, 0)).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(0.4, 0.6, curve: Curves.fastOutSlowIn),
      ),
    );
    final textAnimation =
        Tween<Offset>(begin: Offset(2, 0), end: Offset(0, 0)).animate(
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
                  "프로필을 완성해주세요 :D",
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              SizedBox(height: 40),
              SlideTransition(
                position: textAnimation,
                child:
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _genderButton("남자"),
                  SizedBox(width: 16),
                  _genderButton("여자"),
                ],
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: 256,
                child: TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "나이",
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

  Widget _genderButton(String gender) {
    return SizedBox(
      width: 120,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedGender = gender;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedGender == gender ? Colors.blue : Colors.grey,
          foregroundColor: Colors.white,
        ),
        child: Text(
          gender,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
