import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GPTTestPage(),
    );
  }
}

class GPTTestPage extends StatefulWidget {
  const GPTTestPage({super.key});

  @override
  State<GPTTestPage> createState() => _GPTTestPageState();
}

class _GPTTestPageState extends State<GPTTestPage> {
  String responseText = 'GPT 응답이 여기에 표시됩니다';

  Future<void> fetchGPTResponse() async {
    const apiKey = 'sk-proj-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'; // ✅ 너의 실제 키로 교체

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "user", "content": "안녕! 너 누구야?"}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final content = result['choices'][0]['message']['content'];
      setState(() {
        responseText = content;
      });
    } else {
      setState(() {
        responseText = '에러 발생: ${response.statusCode}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPT 연동 테스트')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: fetchGPTResponse,
              child: const Text('GPT에게 물어보기'),
            ),
            const SizedBox(height: 20),
            Text(responseText),
          ],
        ),
      ),
    );
  }
}
