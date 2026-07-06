import 'package:ai_trip/course_maker/course_maker_whattrip_fourscreen.dart';
import 'package:flutter/material.dart';

class TravelWithScreen extends StatefulWidget {
  final Map<String, dynamic> userConditions;

  const TravelWithScreen({super.key, required this.userConditions});

  @override
  _TravelWithScreenState createState() => _TravelWithScreenState();
}

class _TravelWithScreenState extends State<TravelWithScreen> {
  final List<String> options = [
    '나홀로',
    '연인과',
    '친구와',
    '가족과',
    '효도',
    '자녀와',
    '반려동물과',
  ];

  final Set<String> selectedOptions = {};

  void toggleSelection(String option) {
    setState(() {
      if (selectedOptions.contains(option)) {
        selectedOptions.remove(option);
      } else {
        selectedOptions.add(option);
      }
    });
  }

  Widget _buildOptionButton(String label, String emoji) {
  final isSelected = selectedOptions.contains(label);

  return GestureDetector(
    onTap: () => toggleSelection(label),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green[200] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.green : Colors.grey,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: 18)),
          SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 16)),
        ],
      ),
    ),
  );
}

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.black,
            foregroundColor: Colors.green,
          ),
          onPressed: onPressed,
          child: Text(text, style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> companionOptions = [
      {'label': '나홀로 🧍'},
      {'label': '연인과 💑'},
      {'label': '친구와 🧑‍🤝‍🧑'},
      {'label': '가족과 👨‍👩‍👧‍👦'},
      {'label': '효도 👴'},
      {'label': '자녀와 👶'},
      {'label': '반려동물과 🐶'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('여행 코스 추천'),
        leading: BackButton(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: 0.375, minHeight: 6, backgroundColor: Colors.grey[300], valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
            Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            SizedBox(height: 24),
            Text(
              '2. 여행 스타일을 골라주세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              '누구와 떠나시나요?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('* 중복 선택 가능', style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 24),
            Wrap(
              children: companionOptions
                  .map((option) =>
                      _buildOptionButton(option['label']!.split(' ')[0], option['label']!.split(' ')[1]))
                  .toList(),
            ),
              ],
              ),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildButton("이전", () => Navigator.pop(context)),
                _buildButton("다음", () {
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TravelWhatTripScreen(
                    userConditions: {
                      ...widget.userConditions,
                      "companions": selectedOptions.toList(),
                    }
                  )),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}