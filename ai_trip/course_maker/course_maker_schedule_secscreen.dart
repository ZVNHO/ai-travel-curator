//course_maker_schedule_secscreen.dart
import 'package:flutter/material.dart';
import 'package:ai_trip/course_maker/course_maker_with_thscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_trip/course_maker/course_maker_map_eightscreen.dart';

class TravelScheduleScreen extends StatefulWidget {
  final Map<String, dynamic> userConditions;

  const TravelScheduleScreen({super.key, required this.userConditions});

  @override
  _TravelScheduleScreenState createState() => _TravelScheduleScreenState();
}

class _TravelScheduleScreenState extends State<TravelScheduleScreen> {
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = TimeOfDay(hour: 20, minute: 0);

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate : endDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2026, 12, 31),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? startTime : endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  Widget _buildDateSelector(String label, DateTime date, bool isStart) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        TextButton(
          onPressed: () => _selectDate(isStart),
          child: Text(
            "${date.year}.${date.month}.${date.day}",
            style: TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, bool isStart) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        TextButton(
          onPressed: () => _selectTime(isStart),
          child: Text(
            "${time.hour}:${time.minute.toString().padLeft(2, '0')}",
            style: TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.green,
        padding: EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
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
    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );
    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endTime.hour,
      endTime.minute,
    );
    final totalDays = end.difference(start).inDays + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text("여행 코스 추천"),
        foregroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: 0.25,
            minHeight: 6,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24),
              Text(
                "1. 여행 날짜를 선택해주세요",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDateSelector("출발일", startDate, true),
                  _buildDateSelector("도착일", endDate, false),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTimeSelector("출발 시간", startTime, true),
                  _buildTimeSelector("도착 시간", endTime, false),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildBottomButton('이전', () {
                      Navigator.pop(context);
                    }),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildBottomButton('다음', () {
                      final start = DateTime(
                        startDate.year,
                        startDate.month,
                        startDate.day,
                        startTime.hour,
                        startTime.minute,
                      );
                      final end = DateTime(
                        endDate.year,
                        endDate.month,
                        endDate.day,
                        endTime.hour,
                        endTime.minute,
                      );
                      final totalDays = end.difference(start).inDays + 1;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => TravelWithScreen(
                                userConditions: {
                                  ...widget.userConditions,
                                  "start_date": start.toIso8601String(),
                                  "end_date": end.toIso8601String(),
                                  "days": totalDays,
                                },
                              ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildBottomButton('Skip', () async {
                try {
                  final start = DateTime(
                    startDate.year,
                    startDate.month,
                    startDate.day,
                    startTime.hour,
                    startTime.minute,
                  );
                  final end = DateTime(
                    endDate.year,
                    endDate.month,
                    endDate.day,
                    endTime.hour,
                    endTime.minute,
                  );
                  final totalDays = end.difference(start).inDays + 1;

                  Map<String, dynamic> updatedConditions = {
                    ...widget.userConditions,
                    "start_date": start.toIso8601String(),
                    "end_date": end.toIso8601String(),
                    "days": totalDays,
                  };

                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) throw Exception("로그인된 사용자가 없습니다.");

                  final doc =
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .get();
                  final data = doc.data();
                  if (data == null || data['travelStyle'] == null) {
                    throw Exception("Firestore에 여행 스타일 정보가 없습니다.");
                  }

                  updatedConditions['travelStyle'] = data['travelStyle'];

                  final travelTags =
                      data['travelStyle']
                          .toString()
                          .split(',')
                          .map((e) => e.trim())
                          .toSet();

                  final Map<String, List<String>> travelCategories = {
                    "누구와 함께 가나요?": [
                      '나홀로',
                      '연인과',
                      '친구와',
                      '가족과',
                      '효도',
                      '자녀와',
                      '반려동물과',
                    ],
                    "일정 스타일": ['알찬 일정', '여유있는 일정'],
                    "여행 스타일": ['힐링', '활동적인', '배움이 있는', '맛있는', '교통이 편한', '알뜰한'],
                    "선호하는 활동": [
                      '레저 스포츠',
                      '문화시설',
                      '사진 명소',
                      '이색체험',
                      '유적지',
                      '박물관',
                      '공원',
                      '사찰',
                      '성지',
                    ],
                    "선호하는 장소": [
                      '바다',
                      '산',
                      '드라이브',
                      '산책',
                      '쇼핑',
                      '실내여행지',
                      '시티투어',
                      '전통',
                    ],
                  };

                  final categorized = <String, List<String>>{};
                  travelCategories.forEach((category, keywords) {
                    final matched =
                        keywords.where((k) => travelTags.contains(k)).toList();
                    if (matched.isNotEmpty) categorized[category] = matched;
                  });

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (_) => AlertDialog(
                          title: Text(
                            "회원가입 시 선택한 태그",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  categorized.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.key,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 8,
                                            children:
                                                entry.value
                                                    .map(
                                                      (tag) => Chip(
                                                        label: Text(tag),
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text("취소"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text("확인"),
                            ),
                          ],
                        ),
                  );

                  if (confirmed == true) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => TravelMapScreen(
                              userConditions: updatedConditions,
                            ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("에러 발생: ${e.toString()}")),
                  );
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}
