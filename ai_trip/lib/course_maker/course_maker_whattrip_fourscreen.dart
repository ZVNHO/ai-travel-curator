import 'package:ai_trip/course_maker/course_maker_theme_fivescreen.dart';
import 'package:flutter/material.dart';

class TravelWhatTripScreen extends StatefulWidget {
  final Map<String, dynamic> userConditions;

  const TravelWhatTripScreen({super.key, required this.userConditions});

  @override
  _TravelWhatTripScreenState createState() => _TravelWhatTripScreenState();
}
class _TravelWhatTripScreenState extends State<TravelWhatTripScreen> {
  final List<String> scheduleOptions = [
    '알찬 일정 🏃‍♂️',
    '여유있는 일정 🚶‍♂️',
  ];

  String selectedOption = '여유있는 일정 🚶‍♂️';

  void selectOption(String option) {
    setState(() {
      selectedOption = option;
    });
  }

  Widget _buildOptionButton(String text) {
    final bool isSelected = selectedOption == text;

    return GestureDetector(
      onTap: () => selectOption(text),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(String text, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
          ),
          child: ElevatedButton(
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('여행 코스 추천'),
        leading: BackButton(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: 0.5,
            minHeight: 6,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24),
                Text(
                  '2. 여행 스타일을 알아볼게요.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  '어떤 여행을 원하시나요?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('* 기본값: 여유있는 일정', style: TextStyle(color: Colors.grey[600])),
                SizedBox(height: 24),
                ...scheduleOptions.map((option) => _buildOptionButton(option)),
              ],
            ),
          ),
          Spacer(),
          Row(
            children: [
              _buildBottomButton('이전', () {
                Navigator.pop(context);
              }),
              _buildBottomButton('다음', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TravelThemeScreen(
                    userConditions: {
                       ...widget.userConditions,
                       "pace": selectedOption.split(" ")[0],
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