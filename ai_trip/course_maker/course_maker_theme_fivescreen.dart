import 'package:ai_trip/course_maker/course_maker_what_sixscreen.dart';
import 'package:flutter/material.dart';

class TravelThemeScreen extends StatefulWidget {
  final Map<String, dynamic> userConditions;

  const TravelThemeScreen({super.key, required this.userConditions});

  @override
  _TravelThemeScreenState createState() => _TravelThemeScreenState();
}

class _TravelThemeScreenState extends State<TravelThemeScreen> {
  List<String> selectedThemes = [];

  final List<Map<String, String>> travelStyleOptions = [
    {'label': '힐링 🧘‍♀️'},
    {'label': '활동적인 🏃'},
    {'label': '배움이 있는 📚'},
    {'label': '맛있는 🍽️'},
    {'label': '교통이 편한 🚆'},
    {'label': '알뜰한 💰'},
  ];

  void toggleTheme(String theme) {
    setState(() {
      if (selectedThemes.contains(theme)) {
        selectedThemes.remove(theme);
      } else {
        selectedThemes.add(theme);
      }
    });
  }

  Widget _buildThemeButton(String label) {
    final isSelected = selectedThemes.contains(label);

    return GestureDetector(
      onTap: () => toggleTheme(label),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(String text, VoidCallback onPressed) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.green,
      padding: EdgeInsets.symmetric(vertical: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('여행 코스 추천'),
        leading: BackButton(),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 고정된 LinearProgressIndicator
            LinearProgressIndicator(
              value: 0.625,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),

            // ✅ 고정된 텍스트 영역
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2. 여행 스타일을 알아볼게요.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '테마는 무엇인가요?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('* 중복 선택 가능', style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 16),
                ],
              ),
            ),

            // ⬇️ 스크롤 가능한 테마 버튼 리스트
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...travelStyleOptions
                        .map((option) => _buildThemeButton(option['label']!))
                        ,
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildBottomButton('이전', () {
                  Navigator.pop(context);
                }),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildBottomButton('다음', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TravelWhatScreen(
                       userConditions: {
                        ...widget.userConditions,
                        "themes": selectedThemes.map((e) => e.split(" ")[0]).toList(),
                       }
                    )),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}