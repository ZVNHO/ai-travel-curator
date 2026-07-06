import 'package:ai_trip/course_maker/course_maker_schedule_secscreen.dart';
import 'package:flutter/material.dart';

class CourseMakerTitleScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  CourseMakerTitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("새 여행"),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로그레스 바
          LinearProgressIndicator(value: 0.125, minHeight: 6, backgroundColor: Colors.grey[300], valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("새 여행", style: TextStyle(color: Colors.grey, fontSize: 16)),
                SizedBox(height: 8),
                Text("여행 이름을 입력해주세요.",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                // 입력 필드
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "신나는 여행",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () => _controller.clear(),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          // 다음 버튼
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TravelScheduleScreen(
                    userConditions:{
                       "title": _controller.text.trim(),
                    }
                  )),
                );
              },
              child: Text("다음", style: TextStyle(color: Colors.lightGreen, fontSize: 18)),
            ),
          )
        ],
      ),
    );
  }
}