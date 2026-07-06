import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'firestore_service.dart';
import 'travel_course_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String firebaseProjectId = 'ai-travel-platform';
const String firebaseApiKey = 'AIzaSyCGUy9dQJ--voPcCC6xR7ju1jkiMSasgVk';

class TravelResultsScreen extends StatefulWidget {
  final Map<String, dynamic> userConditions;

  const TravelResultsScreen({super.key, required this.userConditions});

  @override
  State<TravelResultsScreen> createState() => _TravelResultsScreenState();
}

class _TravelResultsScreenState extends State<TravelResultsScreen> {
  List<Map<String, dynamic>> travelResults = [];
  Set<int> selectedIndexes = {};
  bool isLoading = true;
  String gptAnswer = 'GPT에게 질문을 해보세요!';

  late final Map<String, dynamic> conditions;
  late final List<String> companions;
  late final List<String> activities;
  late final List<String> themes;
  late final List<String> places;
  late final Map<String, dynamic> location;
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  int totalDays = 1;

  @override
  void initState() {
    super.initState();

    try {
      conditions = widget.userConditions;

      final startDateStr = conditions['start_date'];
      final endDateStr = conditions['end_date'];

      if (startDateStr == null || endDateStr == null) {
        throw Exception("여행 날짜 정보가 없습니다.");
      }

      startDate = DateTime.parse(startDateStr);
      endDate = DateTime.parse(endDateStr);
      startTime = TimeOfDay.fromDateTime(startDate!);
      endTime = TimeOfDay.fromDateTime(endDate!);
      totalDays = endDate!.difference(startDate!).inDays + 1;

      companions = List<String>.from(conditions['companions'] ?? []);
      activities = List<String>.from(conditions['activities'] ?? []);
      themes = List<String>.from(conditions['themes'] ?? []);
      places = List<String>.from(conditions['places'] ?? []);
      location = Map<String, dynamic>.from(conditions['location'] ?? {});

      fetchPlacesAndAskGpt();
    } catch (e) {
      print('❌ 조건 초기화 중 오류 발생: $e');
      setState(() {
        gptAnswer = '❌ 여행 조건이 부족하여 코스를 생성할 수 없습니다.';
        isLoading = false;
      });
    }
  }

  Future<void> fetchPlacesAndAskGpt() async {
    List<Map<String, dynamic>> allPlaces = [];

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('places').get();
      allPlaces =
          snapshot.docs
              .map((doc) {
                final data = doc.data();
                final lat = data['location']?['lat'] ?? 0.0;
                final lng = data['location']?['lng'] ?? 0.0;
                final distance = calculateDistance(
                  location['lat'] ?? 0.0,
                  location['lng'] ?? 0.0,
                  lat,
                  lng,
                );

                if (distance <= (location['radius_km'] ?? 10.0)) {
                  return {
                    'name': data['pname'] ?? '이름 없음',
                    'address': data['address'] ?? '주소 없음',
                    'tags': List<String>.from(data['ptags'] ?? []),
                    'lat': lat,
                    'lng': lng,
                  };
                }
                return null;
              })
              .where((p) => p != null)
              .cast<Map<String, dynamic>>()
              .toList();

      debugPrint("📦 총 수집된 장소 수: ${allPlaces.length}");
    } catch (e) {
      debugPrint("Firestore 불러오기 실패: $e");
      setState(() {
        gptAnswer = '❌ Firestore 불러오기 실패';
        isLoading = false;
      });
      return;
    }

    final prompt = buildPrompt(allPlaces);
    // 프롬프트 출력
    print("사용자에게 보낼 GPT 프롬프트:\n$prompt");

    final result = await askGPT(prompt);
    final jsonStr = extractJson(result);
    try {
      final parsed = jsonDecode(jsonStr);
      if (parsed is List) {
        final processedResults = validateAndFixDays(parsed);
        setState(() {
          travelResults = processedResults;
          isLoading = false;
          gptAnswer = '여행 코스가 준비되었습니다!';
        });
      } else {
        throw Exception("리스트 형태 아님");
      }
    } catch (e) {
      print("JSON 파싱 오류: $e\n응답 내용: $result");
      setState(() {
        travelResults = [];
        gptAnswer = '❌ 응답 형식 오류';
        isLoading = false;
      });
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degToRad(double degree) => degree * pi / 180.0;

  String buildPrompt(List<Map<String, dynamic>> placeList) {
    final prompt = StringBuffer();
    prompt.writeln(
      "당신은 여행 플래너입니다. 아래 조건에 따라 '$totalDays일 일정' 코스를 JSON 배열로 추천해주세요.",
    );
    prompt.writeln(
      "[ { courseName: string, scores: {}, comparisons: [], places: [{name, address, day, duration, lat, lng}] }, ... ]",
    );
    prompt.writeln("조건:");
    prompt.writeln("- 동행자: ${companions.join(', ')}");
    prompt.writeln("- 활동: ${activities.join(', ')}");
    prompt.writeln("- 테마: ${themes.join(', ')}");
    prompt.writeln("- 장소 키워드: ${places.join(', ')}");
    prompt.writeln(
      "- 여행 기간: ${startDate?.year ?? '??'}.${startDate?.month ?? '??'}.${startDate?.day ?? '??'}"
      " ~ ${endDate?.year ?? '??'}.${endDate?.month ?? '??'}.${endDate?.day ?? '??'}",
    );
    prompt.writeln("- 중요: 각 코스에서 모든 날짜(day)마다 최소 3개 이상의 장소를 반드시 포함해야 합니다.");
    prompt.writeln("- 각 날짜는 1부터 $totalDays까지 순차적으로 모두 포함되어야 합니다.");
    prompt.writeln(
      "- 모든 장소에는 반드시 name, address, day, duration, lat, lng 값이 포함되어야 합니다.",
    );
    prompt.writeln("\n📍 후보 장소 목록:");
    for (var p in placeList) {
      prompt.writeln(
        "- ${p['name']} / ${p['address']} / ${p['tags'].join(', ')}",
      );
    }
    return prompt.toString();
  }

  Future<String> askGPT(String prompt) async {
    const apiKey =
        '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';

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "user", "content": prompt},
        ],
      }),
    );

    print('GPT 응답 코드: ${response.statusCode}');
    print('GPT 응답 바디: ${utf8.decode(response.bodyBytes)}');

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      return '[]';
    }
  }

  String extractJson(String input) {
    final start = input.indexOf('[');
    final end = input.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      return input.substring(start, end + 1);
    }
    return '[]';
  }

  List<Map<String, dynamic>> validateAndFixDays(List<dynamic> results) {
    List<Map<String, dynamic>> fixedResults = [];
    for (var result in results) {
      if (result is Map) {
        Map<String, dynamic> fixedResult = Map<String, dynamic>.from(result);
        List<dynamic> places = fixedResult['places'] ?? [];

        Map<int, int> daysCount = {for (int i = 1; i <= totalDays; i++) i: 0};
        for (var place in places) {
          int day = int.tryParse(place['day'].toString()) ?? 0;
          if (day >= 1 && day <= totalDays)
            daysCount[day] = (daysCount[day] ?? 0) + 1;
        }

        List<int> missingDays = [
          for (int i = 1; i <= totalDays; i++)
            if (daysCount[i] == 0) i,
        ];

        if (missingDays.isNotEmpty) {
          List<Map<String, dynamic>> fixedPlaces =
              places.map((p) => Map<String, dynamic>.from(p)).toList();
          int placeIndex = 0;
          for (int missingDay in missingDays) {
            if (placeIndex < fixedPlaces.length) {
              fixedPlaces[placeIndex]['day'] = missingDay;
              placeIndex++;
            } else {
              fixedPlaces.add({
                'name': '추천 장소 $missingDay',
                'address': '주소 정보 없음',
                'day': missingDay,
                'duration': '2시간',
              });
            }
          }
          fixedResult['places'] = fixedPlaces;
        }
        fixedResults.add(fixedResult);
      }
    }
    return fixedResults;
  }

  @override
  Widget build(BuildContext context) {
    final tripTitle = conditions['title'] ?? '나의 여행';
    final formattedDateTimeRange =
        (startDate != null &&
                endDate != null &&
                startTime != null &&
                endTime != null)
            ? "${startDate!.year}.${startDate!.month.toString().padLeft(2, '0')}.${startDate!.day.toString().padLeft(2, '0')} ${startTime!.format(context)} ~ "
                "${endDate!.year}.${endDate!.month.toString().padLeft(2, '0')}.${endDate!.day.toString().padLeft(2, '0')} ${endTime!.format(context)}"
            : "여행 기간 정보 없음";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '여행 코스 추천',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body:
          isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.flight_takeoff,
                        size: 40,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      "여행 코스를 짜는 중입니다",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "잠시만 기다려주세요...",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // 상단 정보 카드
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tripTitle,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 8),
                            Text(
                              formattedDateTimeRange,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (companions.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 8),
                              Text(
                                companions.join(', '),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 코스 목록
                  Expanded(
                    child:
                        travelResults.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.sentiment_dissatisfied,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    gptAnswer,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: travelResults.length,
                              itemBuilder: (context, index) {
                                final result = travelResults[index];
                                final places = result['places'] ?? [];
                                final isSelected = selectedIndexes.contains(
                                  index,
                                );

                                return Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        isSelected
                                            ? Border.all(
                                              color: Colors.green,
                                              width: 2,
                                            )
                                            : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // 헤더 부분
                                      Container(
                                        padding: EdgeInsets.all(20),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    result['courseName'] ??
                                                        '코스 제목 없음',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    '${places.length}개 장소 • ${totalDays}일 일정',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  if (isSelected) {
                                                    selectedIndexes.remove(
                                                      index,
                                                    );
                                                  } else {
                                                    selectedIndexes.add(index);
                                                  }
                                                });
                                              },
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color:
                                                        isSelected
                                                            ? Colors.green
                                                            : Colors.grey[400]!,
                                                    width: 2,
                                                  ),
                                                  color:
                                                      isSelected
                                                          ? Colors.green
                                                          : Colors.transparent,
                                                ),
                                                child:
                                                    isSelected
                                                        ? Icon(
                                                          Icons.check,
                                                          size: 16,
                                                          color: Colors.white,
                                                        )
                                                        : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 장소 목록 미리보기
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        child: Column(
                                          children:
                                              places.take(3).map<Widget>((
                                                place,
                                              ) {
                                                return Container(
                                                  margin: EdgeInsets.only(
                                                    bottom: 8,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 6,
                                                        height: 6,
                                                        decoration:
                                                            BoxDecoration(
                                                              color:
                                                                  Colors.green,
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                            ),
                                                      ),
                                                      SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          place['name'] ??
                                                              '장소명 없음',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      ),

                                      if (places.length > 3)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(width: 18),
                                              Text(
                                                '외 ${places.length - 3}개 장소',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // 하단 버튼
                                      Container(
                                        padding: EdgeInsets.all(20),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) =>
                                                            TravelCourseDetailScreen(
                                                              travelResult: {
                                                                ...result,
                                                                'totalDays':
                                                                    totalDays,
                                                              },
                                                            ),
                                                  ),
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.green,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                              ),
                                              child: Text(
                                                '자세히 보기',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),

                  // 하단 저장 버튼
                  Container(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            selectedIndexes.isEmpty
                                ? null
                                : () async {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  final userId = user?.uid ?? '';

                                  if (userId.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('로그인이 필요합니다.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  for (var index in selectedIndexes) {
                                    final course = travelResults[index];
                                    final days = course['places'] ?? [];

                                    await saveTravelCourse(
                                      userId: userId,
                                      courseName:
                                          course['courseName'] ?? '코스 제목 없음',
                                      places: List<Map<String, dynamic>>.from(
                                        days,
                                      ),
                                    );
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('선택한 코스가 저장되었습니다!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  setState(() {
                                    selectedIndexes.clear();
                                  });
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              selectedIndexes.isEmpty
                                  ? Colors.grey[300]
                                  : Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          selectedIndexes.isEmpty
                              ? '코스를 선택해주세요'
                              : '선택한 코스 저장 (${selectedIndexes.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
