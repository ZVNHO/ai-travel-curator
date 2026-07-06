import 'introduction_animation/introduction_animation_screen.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_travel_home_screen.dart'; // 홈 화면 import
import 'package:ai_trip/createAccount&Login/Login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: "assets/.env"); // .env 파일 로드

  await testGPTConnection(); // ✅ GPT 연결 테스트 실행
  runApp(MyApp());
}

Future<void> testGPTConnection() async {
  const apiKey =
      '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';

  try {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "user", "content": "이건 GPT 연결 테스트 요청입니다"},
        ],
      }),
    );

    print('✅ GPT 상태 코드: ${response.statusCode}');
    print('📨 GPT 응답: ${response.body}');
  } catch (e) {
    print('❌ GPT 호출 중 오류 발생: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoading = true;
  Widget initialScreen = IntroductionAnimationScreen();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 현재 로그인 상태 확인
    final currentUser = FirebaseAuth.instance.currentUser;

    setState(() {
      if (currentUser != null) {
        // 로그인 되어 있으면 홈 화면으로
        initialScreen = MainScreen();
      } else {
        // 로그인 안 되어 있으면 소개 화면
        initialScreen = IntroductionAnimationScreen();
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Route Maker',
      home: initialScreen,
    );
  }
}
