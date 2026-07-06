import 'package:ai_trip/ai_travel_home_screen.dart';
import 'package:ai_trip/introduction_animation/components/care_view.dart';
import 'package:ai_trip/introduction_animation/components/center_next_button.dart';
import 'package:ai_trip/introduction_animation/components/mood_diary_vew.dart';
import 'package:ai_trip/introduction_animation/components/relax_view.dart';
import 'package:ai_trip/introduction_animation/components/splash_view.dart';
import 'package:ai_trip/introduction_animation/components/top_back_skip_view.dart';
import 'package:ai_trip/introduction_animation/components/welcome_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ai_trip/data/signupData.dart';

late SignUpData signUpData;
final GlobalKey<RelaxViewState> relaxViewKey = GlobalKey<RelaxViewState>();
final GlobalKey<CareViewState> careViewKey = GlobalKey<CareViewState>();
final GlobalKey<TravelStyleViewState> travelStyleViewKey =
    GlobalKey<TravelStyleViewState>();

class IntroductionAnimationScreen extends StatefulWidget {
  const IntroductionAnimationScreen({super.key});

  @override
  _IntroductionAnimationScreenState createState() =>
      _IntroductionAnimationScreenState();
}

class _IntroductionAnimationScreenState
    extends State<IntroductionAnimationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    signUpData = SignUpData();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 8),
    );
    _animationController.animateTo(0.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(_animationController.value);

    return Scaffold(
      backgroundColor: Color(0xffF7EBE1),
      body: Container(
        color: Color(0xffF7EBE1),
        child: ClipRect(
          child: Stack(
            children: [
              WelcomeView(animationController: _animationController),
              RelaxView(
                key: relaxViewKey,
                animationController: _animationController,
                signUpData: signUpData,
              ),
              CareView(
                key: careViewKey,
                animationController: _animationController,
                signUpData: signUpData,
              ),
              TravelStyleView(
                key: travelStyleViewKey,
                animationController: _animationController,
              ),

              TopBackSkipView(
                onBackClick: _onBackClick,
                onSkipClick: _onSkipClick,
                animationController: _animationController,
              ),

              CenterNextButton(
                animationController: _animationController,
                onNextClick: _onNextClick,
              ),

              SplashView(
                animationController: _animationController,
                onLoginPressed: (email, password) async {
                  try {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );

                    if (!context.mounted) return;

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainScreen()),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('로그인 실패: ${e.toString()}')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSkipClick() {
    _animationController.animateTo(0.8, duration: Duration(milliseconds: 1200));
  }

  void _onBackClick() {
    // Adjust animation states accordingly
    if (_animationController.value >= 0 && _animationController.value <= 0.2) {
      _animationController.animateTo(0.0);
    } else if (_animationController.value > 0.2 &&
        _animationController.value <= 0.4) {
      _animationController.animateTo(0.2);
    } else if (_animationController.value > 0.4 &&
        _animationController.value <= 0.6) {
      _animationController.animateTo(0.4);
    } else if (_animationController.value > 0.6 &&
        _animationController.value <= 0.8) {
      _animationController.animateTo(0.6);
    } else if (_animationController.value > 0.8 &&
        _animationController.value <= 1.0) {
      _animationController.animateTo(0.8);
    }
  }

  void _onNextClick() {
    debugPrint("Before Next Click: ${_animationController.value}");

    if (_animationController.value >= 0 && _animationController.value <= 0.2) {
      // RelaxView: 이메일, 비밀번호, 닉네임 저장
      final relaxState = relaxViewKey.currentState;

      if (relaxState != null) {
        signUpData.email = relaxState.email;
        signUpData.password = relaxState.password;
        signUpData.nickname = relaxState.nickname;
        debugPrint(
          "🟢 이메일: ${signUpData.email}, 비번: ${signUpData.password}, 닉네임: ${signUpData.nickname}",
        );
      }

      _animationController.animateTo(0.4);
    } else if (_animationController.value > 0.2 &&
        _animationController.value <= 0.4) {
      // CareView: 성별, 나이 저장
      final careState = careViewKey.currentState;

      if (careState != null &&
          careState.gender != null &&
          careState.age != null) {
        signUpData.gender = careState.gender!;
        signUpData.age = careState.age!;
        debugPrint("🟢 성별: ${signUpData.gender}, 나이: ${signUpData.age}");

        _animationController.animateTo(0.6);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("성별과 나이를 입력해주세요.")));
      }
    } else if (_animationController.value > 0.4 &&
        _animationController.value <= 0.6) {
      // TravelStyleView: 스타일 저장
      final styleState = travelStyleViewKey.currentState;

      if (styleState != null) {
        signUpData.travelStyle = styleState.selectedStyle;
        debugPrint("🟢 여행 스타일: ${signUpData.travelStyle}");
      }

      _animationController.animateTo(0.8);
    } else if (_animationController.value > 0.6 &&
        _animationController.value <= 0.8) {
      _signUpClick();
    }

    debugPrint("After Next Click: ${_animationController.value}");
  }

  // 특정 타입의 State를 찾는 헬퍼 함수
  State? _getStateOf<T extends StatefulWidget>() {
    final widgetType = T.toString();
    final element = context.findAncestorStateOfType<State<StatefulWidget>>();
    if (element != null &&
        element.widget.runtimeType.toString() == widgetType) {
      return element;
    }
    return null;
  }

  void _signUpClick() async {
    debugPrint("회원가입 버튼 클릭됨! 회원 생성 시도 중...");

    try {
      // 1. Firebase Auth: 이메일로 회원가입
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: signUpData.email,
            password: signUpData.password,
          );

      // 2. Firestore에 유저 정보 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': signUpData.email,
            'nickname': signUpData.nickname,
            'gender': signUpData.gender,
            'age': signUpData.age,
            'travelStyle': signUpData.travelStyle,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 3. 메인 화면으로 이동
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    } catch (e) {
      debugPrint("회원가입 실패: $e");

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("회원가입 실패: ${e.toString()}")));
    }
  }
}
