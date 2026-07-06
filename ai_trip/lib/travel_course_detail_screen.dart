// travel_course_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

final user = FirebaseAuth.instance.currentUser;
final userId = user?.uid ?? ''; // 현재 로그인한 사용자의 ID

//Result.dart연동 코드
class TravelCourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> travelResult;

  const TravelCourseDetailScreen({super.key, required this.travelResult});
  //생성자가 반드시 travelResult 받아오게 되어있다
  @override
  State<TravelCourseDetailScreen> createState() =>
      _TravelCourseDetailScreenState();
}

class _TravelCourseDetailScreenState extends State<TravelCourseDetailScreen> {
  int selectedDay = 1;
  List<Map<String, String>> travelTimes = [];
  bool isLoading = true;
  String apiError = '';

  @override
  void initState() {
    super.initState();
    _fetchTravelTimes(); // 초기 호출
  }

  Future<void> _fetchTravelTimes() async {
    setState(() {
      isLoading = true;
      apiError = '';
    });

    final places = widget.travelResult['places'] as List<dynamic>? ?? [];

    // 디버깅을 위해 모든 장소 정보 출력
    debugPrint("📍 전체 장소 개수: ${places.length}");

    // 선택한 날짜의 장소만 필터링 (문자열과 숫자 비교가 모두 가능하도록)
    final dayPlaces =
        places.where((p) {
          final placeDay = p['day'];
          // day 값이 문자열이나 숫자 등 다양한 형태일 수 있으므로 toString()으로 변환하여 비교
          return placeDay.toString() == selectedDay.toString();
        }).toList();

    debugPrint("선택된 날짜($selectedDay) 장소 수: ${dayPlaces.length}");
    debugPrint("📍 DAY$selectedDay 장소 ${dayPlaces.length}개 조회됨");

    // 디버깅: 각 장소의 day 값과 필터링 결과 확인
    for (var place in places) {
      debugPrint(
        "장소: ${place['name']}, day: ${place['day']}, 타입: ${place['day'].runtimeType}",
      );
    }

    if (dayPlaces.isEmpty) {
      setState(() {
        travelTimes = [];
        isLoading = false;
      });
      return;
    }

    List<Map<String, String>> times = [];

    for (int i = 0; i < dayPlaces.length - 1; i++) {
      final start = dayPlaces[i];
      final end = dayPlaces[i + 1];

      // 좌표 가져오기 (lat/lng 형태로 저장되어 있는 경우)
      debugPrint(
        "🧭 좌표 디버깅: ${start['name']}(${start['lat']}, ${start['lng']}) → ${end['name']}(${end['lat']}, ${end['lng']})",
      );
      double? startLat =
          start['lat'] is double
              ? start['lat']
              : double.tryParse(start['lat']?.toString() ?? '');
      double? startLng =
          start['lng'] is double
              ? start['lng']
              : double.tryParse(start['lng']?.toString() ?? '');
      double? endLat =
          end['lat'] is double
              ? end['lat']
              : double.tryParse(end['lat']?.toString() ?? '');
      double? endLng =
          end['lng'] is double
              ? end['lng']
              : double.tryParse(end['lng']?.toString() ?? '');

      if (startLat == null ||
          startLng == null ||
          endLat == null ||
          endLng == null) {
        debugPrint("❌ 장소 좌표 누락: ${start['name']} → ${end['name']}");

        // 좌표가 없는 경우 에러 처리
        times.add({'car': '좌표 누락', 'walk': '좌표 누락', 'transit': '좌표 누락'});
        continue;
      }

      if (startLat! < 33 ||
          startLat > 39 ||
          startLng! < 124 ||
          startLng > 132) {
        debugPrint("⚠️ 출발지 좌표 이상함: $startLat, $startLng");
        continue;
      }
      if (endLat! < 33 || endLat > 39 || endLng! < 124 || endLng > 132) {
        debugPrint("⚠️ 도착지 좌표 이상함: $endLat, $endLng");
        continue;
      }

      debugPrint("🔍 길찾기 시작: ${start['name']} → ${end['name']}");

      try {
        final origin = '$startLat,$startLng';
        final destination = '$endLat,$endLng';

        // 자동차 시간 - URL을 명확하게 구성하고 인코딩
        final carUri = Uri.parse('http://localhost:8000/tmap/car');

        debugPrint("자동차 API 요청: ${carUri.toString()}");
        final carRes = await http.post(
          carUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'startX': '$startLng',
            'startY': '$startLat',
            'endX': '$endLng',
            'endY': '$endLat',
            'startName': start['name'] ?? '출발지',
            'endName': end['name'] ?? '도착지',
          }),
        );
        debugPrint("자동차 API 응답 코드: ${carRes.statusCode}");

        // 도보 시간 - URL을 명확하게 구성하고 인코딩
        final walkUri = Uri.parse('http://localhost:8000/tmap/walk');

        debugPrint("🚶 도보 API 요청: ${walkUri.toString()}");
        final walkRes = await http.post(
          walkUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'startX': '$startLng',
            'startY': '$startLat',
            'endX': '$endLng',
            'endY': '$endLat',
            'startName': start['name'] ?? '출발지',
            'endName': end['name'] ?? '도착지',
          }),
        );
        debugPrint("도보 API 응답 코드: ${walkRes.statusCode}");

        //  대중교통 시간 - URL을 명확하게 구성하고 인코딩
        final transitUri = Uri.parse(
          'http://localhost:8000/directions',
        ).replace(
          queryParameters: {
            'origin': '$startLat,$startLng',
            'destination': '$endLat,$endLng',
            'mode': 'transit',
          },
        );

        debugPrint(" 대중교통 API 요청: ${transitUri.toString()}");
        final transitRes = await http.get(
          transitUri,
        ); // FastAPI가 대신 Google API 호출
        debugPrint("대중교통 API 응답 코드: ${transitRes.statusCode}");

        String carDuration = '정보 없음';
        String walkDuration = '정보 없음';
        String transitDuration = '정보 없음';

        // 자동차 응답 처리
        if (carRes.statusCode == 200) {
          debugPrint("✅ 자동차차 API 응답 성공 (Tmap)");
          final carData = json.decode(carRes.body);

          if (carData['features'] != null && carData['features'].isNotEmpty) {
            final properties = carData['features'][0]['properties'];
            final totalTime = properties['totalTime']; // 단위: 초 (seconds)
            if (totalTime != null) {
              carDuration = '${(totalTime / 60).round()}분'; // 분 단위로 표시
            } else {
              debugPrint("⚠️ totalTime 없음");
            }
          } else {
            debugPrint("자동차 Tmap 응답에 features 없음");
          }
        } else {
          debugPrint("❌ 도보 API 응답 실패: ${carRes.body}");
        }

        // 도보 응답 처리 (tmap)
        if (walkRes.statusCode == 200) {
          debugPrint("✅ 도보 API 응답 성공 (Tmap)");
          final walkData = json.decode(walkRes.body);

          //debugPrint("Tmap 도보 응답 원본: ${walkRes.body}");

          if (walkData['features'] != null && walkData['features'].isNotEmpty) {
            final properties = walkData['features'][0]['properties'];
            final totalTime = properties['totalTime']; // 단위: 초 (seconds)
            if (totalTime != null) {
              walkDuration = '${(totalTime / 60).round()}분'; // 분 단위로 표시
            } else {
              debugPrint("⚠️ totalTime 없음");
            }
          } else {
            debugPrint("🚶 Tmap 응답에 features 없음");
          }
        } else {
          debugPrint("❌ 도보 API 응답 실패: ${walkRes.body}");
        }

        // 대중교통 응답 처리
        if (transitRes.statusCode == 200) {
          debugPrint("✅ 대중교통 API 응답 성공");
          final transitData = json.decode(transitRes.body);
          if (transitData['routes'] != null &&
              transitData['routes'].isNotEmpty) {
            transitDuration =
                transitData['routes'][0]['legs'][0]['duration']['text'] ??
                '정보 없음';
          } else {
            debugPrint("🚍 ZERO_RESULTS or route 없음");
          }

          times.add({
            'car': carDuration,
            'walk': walkDuration,
            'transit': transitDuration,
          });

          debugPrint(
            "🕒 계산된 시간: 자동차 $carDuration분, 도보 $walkDuration분, 대중교통 $transitDuration분",
          );
        } else {
          debugPrint(
            "❌ 길찾기 API 응답 실패: 자동차(${carRes.statusCode}), 도보(${walkRes.statusCode}), 대중교통 (${transitRes.statusCode})",
          );

          // 에러 응답 내용 확인
          if (carRes.statusCode != 200) {
            debugPrint("자동차 API 에러: ${carRes.body}");
          }
          if (walkRes.statusCode != 200) {
            debugPrint("도보 API 에러: ${walkRes.body}");
          }
          if (transitRes.statusCode != 200) {
            debugPrint("대중교통 API 에러: ${transitRes.body}");
          }

          times.add({'car': '통신 오류', 'walk': '통신 오류', 'transit': '통신 오류'});
        }
      } catch (e) {
        debugPrint("❌ 길찾기 API 호출 오류: $e");
        times.add({'car': '에러', 'walk': '에러', 'transit': '에러'});

        setState(() {
          apiError = '네트워크 오류: $e';
        });
      }
    }

    setState(() {
      travelTimes = times;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scores = Map<String, dynamic>.from(
      widget.travelResult['scores'] ?? {},
    );
    final places = widget.travelResult['places'] as List<dynamic>? ?? [];
    final availableDays = _getAvailableDays(places);

    // 디버깅 정보
    debugPrint("전체 장소 데이터: ${jsonEncode(places)}");
    debugPrint("이용 가능한 날짜들: $availableDays");

    // 날짜 필터링 더 명확하게 처리
    final dayPlaces =
        places.where((p) {
          var placeDay = p['day'];
          return placeDay.toString() == selectedDay.toString();
        }).toList();

    debugPrint("선택된 날짜($selectedDay) 장소 수: ${dayPlaces.length}");

    // 장소 좌표 평균 계산
    double avgLat = 36.35; // 기본 좌표
    double avgLng = 127.38;

    if (dayPlaces.isNotEmpty) {
      double totalLat = 0;
      double totalLng = 0;
      int validPlaces = 0;

      for (var place in dayPlaces) {
        double? lat =
            place['lat'] is double
                ? place['lat']
                : double.tryParse(place['lat']?.toString() ?? '');
        double? lng =
            place['lng'] is double
                ? place['lng']
                : double.tryParse(place['lng']?.toString() ?? '');

        if (lat != null && lng != null) {
          totalLat += lat;
          totalLng += lng;
          validPlaces++;
        }
      }

      if (validPlaces > 0) {
        avgLat = totalLat / validPlaces;
        avgLng = totalLng / validPlaces;
      }
    }

    // 경로 좌표 리스트 생성 - 각 장소의 좌표를 순서대로 연결
    List<LatLng> routePoints = [];
    for (var place in dayPlaces) {
      double? lat =
          place['lat'] is double
              ? place['lat']
              : double.tryParse(place['lat']?.toString() ?? '');
      double? lng =
          place['lng'] is double
              ? place['lng']
              : double.tryParse(place['lng']?.toString() ?? '');

      if (lat != null && lng != null) {
        routePoints.add(LatLng(lat, lng));
      }
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          '여행 코스 추천',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          if (scores.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                children:
                    scores.entries.map((entry) {
                      return Chip(label: Text('${entry.key} ${entry.value}'));
                    }).toList(),
              ),
            ),

          // 지도 영역
          SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(avgLat, avgLng),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),

                // 경로 표시를 위한 PolylineLayer 추가
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: Colors.red,
                      strokeWidth: 3.0,
                    ),
                  ],
                ),

                MarkerLayer(
                  markers:
                      dayPlaces.asMap().entries.map((entry) {
                        final index = entry.key;
                        final place = entry.value;

                        double? lat =
                            place['lat'] is double
                                ? place['lat']
                                : double.tryParse(
                                  place['lat']?.toString() ?? '',
                                );
                        double? lng =
                            place['lng'] is double
                                ? place['lng']
                                : double.tryParse(
                                  place['lng']?.toString() ?? '',
                                );

                        if (lat == null || lng == null)
                          return Marker(
                            point: LatLng(0, 0),
                            child: Container(),
                          );

                        return Marker(
                          point: LatLng(lat, lng),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 36,
                              ),
                              Positioned(
                                top: 4,
                                child: Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),

          // 일자 선택 탭 - 개선된 UI
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    availableDays.map((day) {
                      bool isSelected = selectedDay == day;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDay = day;
                            debugPrint("선택된 날짜 변경: $day");
                          });
                          _fetchTravelTimes(); // 변경 시 재호출
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 12),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Color(0xFF4CAF50)
                                    : Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Color(0xFF4CAF50)
                                      : Colors.grey[300]!,
                              width: 1,
                            ),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: Color(
                                          0xFF4CAF50,
                                        ).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Text(
                            'DAY $day',
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.grey[700],
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),

          // API 에러 표시
          if (apiError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(apiError, style: TextStyle(color: Colors.red)),
            ),

          // 장소 목록
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : dayPlaces.isEmpty
                    ? Center(child: Text('해당 일자에 장소가 없습니다.'))
                    : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: dayPlaces.length,
                      itemBuilder: (context, index) {
                        final place = dayPlaces[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 장소 이름과 체류 시간
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(child: Text('${index + 1}')),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${place['name'] ?? '장소 정보 없음'}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '소요 시간: ${place['duration'] ?? '정보 없음'}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 다음 장소로의 이동 시간 정보
                            if (index < travelTimes.length)
                              Container(
                                margin: EdgeInsets.only(left: 16, bottom: 16),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.directions_car, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          '자동차: ${travelTimes[index]['car']}',
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.directions_walk, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          '도보: ${travelTimes[index]['walk']}',
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.directions_transit,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '대중교통: ${travelTimes[index]['transit']}',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                            // 마지막 아이템이 아닌 경우 화살표 표시
                            if (index < dayPlaces.length - 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Icon(
                                  Icons.arrow_downward,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchTravelTimes,
        tooltip: '이동 시간 새로고침',
        child: Icon(Icons.refresh),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  final courseName =
                      widget.travelResult['courseName'] ?? '코스 제목 없음';
                  final places =
                      widget.travelResult['places'] ?? []; // 'places'로 변경

                  // saveTravelCourse 호출 시 'places'를 전달
                  await saveTravelCourse(
                    userId: userId, // 실제 로그인한 유저 ID로 교체
                    courseName:
                        widget.travelResult['courseName'] ??
                        '코스 제목 없음', // 수정된 부분
                    places: List<Map<String, dynamic>>.from(
                      places,
                    ), // 'days' → 'places'
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('여행이 성공적으로 저장되었습니다!')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  debugPrint('저장 오류: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '코스를 선택해주세요',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<int> _getAvailableDays(List<dynamic> places) {
    final daySet = <int>{};
    for (var place in places) {
      // 어떤 형태로든 day 값을 추출
      var day = place['day'];
      if (day != null) {
        // 문자열이나 다른 형식이면 파싱 시도
        final dayInt = day is int ? day : int.tryParse(day.toString());
        if (dayInt != null) daySet.add(dayInt);
      }
    }
    final sortedDays = daySet.toList()..sort();
    debugPrint("이용 가능한 날짜들: $sortedDays");
    return sortedDays;
  }
}
