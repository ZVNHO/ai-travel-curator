import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'travel_course_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class CourseScreen extends StatefulWidget {
  final String userId;

  const CourseScreen({super.key, required this.userId});

  @override
  _CourseScreenState createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        '저장된 여행 코스',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // balance for back button
                  ],
                ),
              ),
            ),

            // 코스 목록
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('travel_courses')
                        .where('userId', isEqualTo: widget.userId)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState('에러가 발생했습니다.\n다시 시도해주세요.');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final courses = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final doc = courses[index];
                      final courseData = doc.data() as Map<String, dynamic>?;
                      final courseName =
                          courseData?['courseName'] ?? '코스 제목 없음';
                      final places = courseData?['places'] as List? ?? [];
                      final totalDays = _calculateTotalDays(
                        courseData?['places'],
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCourseCard(
                          courseName: courseName,
                          totalDays: totalDays,
                          placesCount: places.length,
                          places: places,
                          onTap: () {
                            if (courseData != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TravelCourseDetailScreen(
                                        travelResult: {
                                          'courseName':
                                              courseData['courseName'] ??
                                              '코스 제목 없음',
                                          'places':
                                              List<Map<String, dynamic>>.from(
                                                courseData['places'] ?? [],
                                              ),
                                          'scores': Map<String, dynamic>.from(
                                            courseData['scores'] ?? {},
                                          ),
                                          'totalDays': totalDays,
                                        },
                                      ),
                                ),
                              );
                            }
                          },
                          onStart: () => _startCourse(courseName, doc.id),
                          onDelete: () => _deleteCourse(doc.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 이메일로 코스 공유
  void _sendEmailWithCourse(String courseName, List places) async {
    // ✅ day 순 정렬
    final sortedPlaces = List.from(places)..sort((a, b) {
      final dayA = a['day'] ?? 999;
      final dayB = b['day'] ?? 999;
      return dayA.compareTo(dayB);
    });

    final bodyBuffer = StringBuffer();
    bodyBuffer.writeln('📌 여행 코스: $courseName');
    bodyBuffer.writeln('🗓 장소 수: ${sortedPlaces.length}');
    bodyBuffer.writeln('\n📍 일정:');

    for (var p in sortedPlaces) {
      bodyBuffer.writeln(
        '- DAY${p['day'] ?? '?'}: ${p['name'] ?? '장소 없음'} (${p['address'] ?? ''})',
      );
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: '',
      query: Uri.encodeFull(
        'subject=$courseName 여행 코스 공유&body=${bodyBuffer.toString()}',
      ),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("이메일 앱을 실행할 수 없습니다")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("이메일 공유 중 오류가 발생했습니다")));
      }
    }
  }

  // Share Plus를 사용한 일반 공유
  void _shareWithCourse(String courseName, List places) {
    // ✅ day 순 정렬
    final sortedPlaces = List.from(places)..sort((a, b) {
      final dayA = a['day'] ?? 999;
      final dayB = b['day'] ?? 999;
      return dayA.compareTo(dayB);
    });

    final buffer = StringBuffer();
    buffer.writeln("📌 여행 코스: $courseName");
    buffer.writeln("🗓 장소 수: ${sortedPlaces.length}");
    buffer.writeln("\n📍 일정:");

    for (var p in sortedPlaces) {
      buffer.writeln(
        "- DAY${p['day'] ?? '?'}: ${p['name'] ?? '장소 없음'} (${p['address'] ?? ''})",
      );
    }

    Share.share(buffer.toString());
  }

  // 공유 방법 선택 다이얼로그
  void _showShareDialog(String courseName, List places) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('공유 방법 선택'),
            content: const Text('어떤 방식으로 공유할까요?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _sendEmailWithCourse(courseName, places);
                },
                child: const Text('이메일'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _shareWithCourse(courseName, places);
                },
                child: const Text('기타 앱 (카카오톡 포함)'),
              ),
            ],
          ),
    );
  }

  Widget _buildCourseCard({
    required String courseName,
    required int totalDays,
    required int placesCount,
    required List places,
    required VoidCallback onTap,
    required VoidCallback onStart,
    required VoidCallback onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 코스 정보
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.route,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courseName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalDays일',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$placesCount개 장소',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 액션 버튼들
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '여행 시작',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_forward, color: Colors.grey[600]),
                      onPressed: onTap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share, color: Colors.green),
                      onPressed: () => _showShareDialog(courseName, places),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.route, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              '저장된 코스가 없습니다',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 여행 코스를 만들어보세요!',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 여행 시작 → 다이어리 등록
  Future<void> _startCourse(String courseName, String courseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.blue),
                SizedBox(width: 8),
                Text('여행 시작'),
              ],
            ),
            content: Text('$courseName 여행을 시작하시겠습니까?\n일기에 자동으로 기록됩니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('시작하기'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await createDiaryEntry(
            userId: user.uid,
            courseName: courseName,
            courseId: courseId,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text('$courseName 여행이 일기에 기록되었습니다!')),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('일기 등록 중 오류가 발생했습니다.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      }
    }
  }

  /// 다이어리 등록 함수
  Future<void> createDiaryEntry({
    required String userId,
    required String courseName,
    required String courseId,
  }) async {
    await _firestore.collection('diary').add({
      'userId': userId,
      'title': courseName,
      'body': '',
      'diary_photo': [],
      'status': ['started'],
      'created_at': FieldValue.serverTimestamp(),
      'courseId': courseId,
    });
  }

  /// 코스 삭제
  Future<void> _deleteCourse(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text('삭제 확인'),
              ],
            ),
            content: const Text('정말로 이 코스를 삭제하시겠습니까?\n삭제된 코스는 복구할 수 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('travel_courses').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.white),
                  SizedBox(width: 8),
                  Text('코스가 삭제되었습니다.'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('삭제 중 오류가 발생했습니다.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  /// 여행 일정 총 일수 계산
  int _calculateTotalDays(dynamic places) {
    if (places == null || (places as List).isEmpty) return 1;
    final days =
        places.map<int>((p) => int.tryParse(p['day'].toString()) ?? 1).toSet();
    return days.length;
  }
}
