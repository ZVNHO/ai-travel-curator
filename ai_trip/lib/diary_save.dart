import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  List<DiaryEntry> diaryEntries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiaryEntries();
  }

  Future<void> _loadDiaryEntries() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final diarySnapshot =
          await _firestore
              .collection('diary')
              .where('userId', isEqualTo: user.uid)
              .get();

      List<DiaryEntry> loadedEntries = [];

      for (final doc in diarySnapshot.docs) {
        final data = doc.data();
        final title = data['title'] ?? '제목 없음';
        final date =
            (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now();

        // 하위 places 컬렉션 가져오기
        final placesSnapshot =
            await _firestore
                .collection('diary')
                .doc(doc.id)
                .collection('places')
                .orderBy('day')
                .get();

        final buffer = StringBuffer();
        int placeCount = placesSnapshot.docs.length;
        int dayCount =
            placeCount > 0 ? placesSnapshot.docs.last.data()['day'] ?? 1 : 1;

        for (var placeDoc in placesSnapshot.docs) {
          final place = placeDoc.data();
          final text = place['gpt_text'] ?? '';
          buffer.writeln(text);
        }

        loadedEntries.add(
          DiaryEntry(
            docId: doc.id,
            date: date,
            title: title,
            content: buffer.toString(),
            dayCount: dayCount,
            placeCount: placeCount,
          ),
        );
      }

      if (mounted) {
        setState(() {
          diaryEntries = loadedEntries;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ 일기 불러오기 실패: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatDateRange(DateTime startDate, int dayCount) {
    final endDate = startDate.add(Duration(days: dayCount - 1));

    final startFormatted =
        '${startDate.year.toString().substring(2)}'
        '${startDate.month.toString().padLeft(2, '0')}'
        '${startDate.day.toString().padLeft(2, '0')}';

    final endFormatted =
        '${endDate.year.toString().substring(2)}'
        '${endDate.month.toString().padLeft(2, '0')}'
        '${endDate.day.toString().padLeft(2, '0')}';

    return '$dayCount일($startFormatted~$endFormatted)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '저장된 여행 코스',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : diaryEntries.isEmpty
              ? const Center(child: Text('저장된 일기가 없습니다.'))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: diaryEntries.length,
                  itemBuilder: (_, index) {
                    final entry = diaryEntries[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.blue[600],
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDateRange(
                                                entry.date,
                                                entry.dayCount,
                                              ),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.place,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${entry.placeCount}개 장소',
                                              style: TextStyle(
                                                fontSize: 13,
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
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final updatedEntry =
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => DiaryDetailScreen(
                                                      entry: entry,
                                                    ),
                                              ),
                                            );
                                        if (updatedEntry != null && mounted) {
                                          setState(() {
                                            diaryEntries[index] = updatedEntry;
                                          });
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.play_arrow, size: 18),
                                          SizedBox(width: 4),
                                          Text(
                                            '일기 보기',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      onPressed: () {
                                        // 삭제 기능 구현
                                        _showDeleteDialog(context, index);
                                      },
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red[400],
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  void _showDeleteDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('삭제 확인'),
            content: const Text('이 여행 코스를 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteDiary(index);
                },
                child: const Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _deleteDiary(int index) async {
    final entry = diaryEntries[index];
    final diaryRef = _firestore.collection('diary').doc(entry.docId);

    try {
      // 1. places 하위 문서들 삭제
      final placesSnapshot = await diaryRef.collection('places').get();
      for (final doc in placesSnapshot.docs) {
        await doc.reference.delete();
      }

      // 2. diary 문서 삭제
      await diaryRef.delete();

      // 3. UI 갱신
      setState(() {
        diaryEntries.removeAt(index);
      });
    } catch (e) {
      debugPrint('❌ 삭제 실패: $e');
    }
  }
}

class DiaryEntry {
  final String docId;
  final DateTime date;
  final String title;
  final String content;
  final int dayCount;
  final int placeCount;

  DiaryEntry({
    required this.docId,
    required this.date,
    required this.title,
    required this.content,
    this.dayCount = 1,
    this.placeCount = 0,
  });

  DiaryEntry copyWith({String? title, String? content}) {
    return DiaryEntry(
      docId: docId,
      date: date,
      title: title ?? this.title,
      content: content ?? this.content,
      dayCount: dayCount,
      placeCount: placeCount,
    );
  }
}

class DiaryDetailScreen extends StatefulWidget {
  final DiaryEntry entry;
  const DiaryDetailScreen({super.key, required this.entry});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  bool isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _contentController = TextEditingController(text: widget.entry.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final diaryId = widget.entry.docId;

    try {
      // 1. 제목 업데이트
      await _firestore.collection('diary').doc(diaryId).update({
        'title': _titleController.text,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 2. 내용을 day: 1번 place만 수정 (또는 content 전체를 하나로 저장하는 필드를 따로 생성해도 됨)
      final placesRef = _firestore
          .collection('diary')
          .doc(diaryId)
          .collection('places');
      final places = await placesRef.orderBy('day').get();
      if (places.docs.isNotEmpty) {
        await places.docs.first.reference.update({
          'gpt_text': _contentController.text,
        });
      }
    } catch (e) {
      debugPrint('❌ Firestore 업데이트 실패: $e');
    }
  }

  void _toggleEdit() async {
    if (isEditing) {
      await _saveChanges();
      Navigator.pop(
        context,
        widget.entry.copyWith(
          title: _titleController.text,
          content: _contentController.text,
        ),
      );
    } else {
      setState(() {
        isEditing = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.entry.date.year}년 ${widget.entry.date.month}월 ${widget.entry.date.day}일',
        ),
        actions: [
          TextButton(
            onPressed: _toggleEdit,
            child: Text(isEditing ? '완료' : '수정'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              readOnly: !isEditing,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                readOnly: !isEditing,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(labelText: '내용'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
