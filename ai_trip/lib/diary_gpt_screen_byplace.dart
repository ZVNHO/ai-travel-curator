// ✅ DiaryGptScreenByPlace.dart (편집 + 다시 생성 기능 추가)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// DiaryEntry 클래스 추가
class DiaryEntry {
  final DateTime date;
  final String title;
  final String content;

  DiaryEntry({required this.date, required this.title, required this.content});

  DiaryEntry copyWith({String? title, String? content}) {
    return DiaryEntry(
      date: date,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }
}

class DiaryGptScreenByPlace extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final List<Map<String, dynamic>> places;
  final Map<String, String> diaryMap;
  final Future<void> Function() onSavePressed;
  final Future<String> Function(String placeId, String placeName)?
  onRegenerateDiary; // 다시 생성 콜백 추가

  const DiaryGptScreenByPlace({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.places,
    required this.diaryMap,
    required this.onSavePressed,
    this.onRegenerateDiary,
  });

  @override
  State<DiaryGptScreenByPlace> createState() => _DiaryGptScreenByPlaceState();
}

class _DiaryGptScreenByPlaceState extends State<DiaryGptScreenByPlace> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isSaving = false;
  Map<String, bool> _regeneratingMap = {}; // 각 장소별 재생성 상태 관리
  Map<String, bool> _editingMap = {}; // 각 장소별 편집 상태 관리
  late Map<String, String> _currentDiaryMap; // 현재 일기 맵 (업데이트 가능)
  Map<String, TextEditingController> _textControllers = {}; // 텍스트 컨트롤러들

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentDiaryMap = Map.from(widget.diaryMap); // 복사본 생성

    // 각 장소별 텍스트 컨트롤러 초기화
    for (final place in widget.places) {
      final placeId = place['placeId'].toString();
      _textControllers[placeId] = TextEditingController(
        text: _currentDiaryMap[placeId] ?? '일기 내용이 없습니다.',
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    // 모든 텍스트 컨트롤러 해제
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < widget.places.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 편집 모드 토글
  void _toggleEdit(String placeId) {
    setState(() {
      final isCurrentlyEditing = _editingMap[placeId] ?? false;

      if (isCurrentlyEditing) {
        // 편집 완료 - 변경사항 저장
        _currentDiaryMap[placeId] = _textControllers[placeId]?.text ?? '';
      }

      _editingMap[placeId] = !isCurrentlyEditing;
    });
  }

  // GPT 다시 생성 함수
  // DiaryGptScreenByPlace에서 _regenerateDiary 함수를 이렇게 개선할 수 있습니다
  Future<void> _regenerateDiary(String placeId, String placeName) async {
    print('🔄 _regenerateDiary 호출됨: $placeName');

    if (widget.onRegenerateDiary == null) {
      print('❌ onRegenerateDiary가 null입니다!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일기 재생성 기능이 설정되지 않았습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _regeneratingMap[placeId] = true;
    });

    try {
      final newDiaryContent = await widget.onRegenerateDiary!(
        placeId,
        placeName,
      );

      setState(() {
        _currentDiaryMap[placeId] = newDiaryContent;
        // 텍스트 컨트롤러도 업데이트
        _textControllers[placeId]?.text = newDiaryContent;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$placeName 일기가 다시 생성되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 일기 재생성 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$placeName 일기 재생성에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _regeneratingMap[placeId] = false;
        });
      }
    }
  }

  void _handleSave() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 편집 중인 내용들을 모두 저장
      for (final placeId in _textControllers.keys) {
        if (_editingMap[placeId] == true) {
          _currentDiaryMap[placeId] = _textControllers[placeId]?.text ?? '';
        }
      }

      // 기존 Firestore 저장
      await widget.onSavePressed();

      // DiaryEntry 생성 (전체 일기를 하나로 합침)
      final String combinedContent = _createCombinedDiaryContent();
      final DiaryEntry newEntry = DiaryEntry(
        date: DateTime.now(),
        title: widget.courseTitle,
        content: combinedContent,
      );

      if (mounted) {
        // DiaryScreen으로 이동하면서 새 일기 전달
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryScreen(initialEntry: newEntry),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // 전체 일기 내용을 하나로 합치는 함수
  String _createCombinedDiaryContent() {
    final StringBuffer buffer = StringBuffer();

    // 정렬된 장소들로 일기 생성
    final sortedPlaces = [...widget.places];
    sortedPlaces.sort((a, b) {
      final dayA = int.tryParse(a['day'].toString()) ?? 0;
      final dayB = int.tryParse(b['day'].toString()) ?? 0;
      return dayA.compareTo(dayB);
    });

    for (int i = 0; i < sortedPlaces.length; i++) {
      final place = sortedPlaces[i];
      final placeId = place['placeId'].toString();
      final placeName = place['name']?.toString() ?? '장소명 없음';
      final day = place['day']?.toString() ?? '${i + 1}';
      final diaryText = _currentDiaryMap[placeId] ?? '일기 내용이 없습니다.';

      buffer.writeln('📍 ${day}일차 - $placeName');
      buffer.writeln(diaryText);

      if (i < sortedPlaces.length - 1) {
        buffer.writeln(''); // 장소 간 구분을 위한 빈 줄
      }
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '${widget.courseTitle} 일기',
          style: const TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child:
                _isSaving
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                    : const Text(
                      '저장',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 페이지 인디케이터
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_currentPage + 1} / ${widget.places.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 페이지 뷰
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: widget.places.length,
              itemBuilder: (context, index) {
                final place = widget.places[index];
                final placeId = place['placeId'].toString();
                final placeName = place['name']?.toString() ?? '장소명 없음';
                final day = place['day']?.toString() ?? '${index + 1}';
                final isRegenerating = _regeneratingMap[placeId] ?? false;
                final isEditing = _editingMap[placeId] ?? false;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 헤더
                          Row(
                            children: [
                              // GPT 다시 생성 버튼
                              GestureDetector(
                                onTap:
                                    isRegenerating || isEditing
                                        ? null
                                        : () => _regenerateDiary(
                                          placeId,
                                          placeName,
                                        ),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        isRegenerating || isEditing
                                            ? Colors.grey
                                            : Colors.blue,
                                  ),
                                  child:
                                      isRegenerating
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                          : const Icon(
                                            Icons.refresh,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // 편집 버튼
                              GestureDetector(
                                onTap:
                                    isRegenerating
                                        ? null
                                        : () => _toggleEdit(placeId),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        isRegenerating
                                            ? Colors.grey
                                            : (isEditing
                                                ? Colors.green
                                                : Colors.orange),
                                  ),
                                  child: Icon(
                                    isEditing ? Icons.check : Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      placeName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${day}일차',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 20),

                          // 일기 내용 (편집 가능)
                          Expanded(
                            child:
                                isEditing
                                    ? TextField(
                                      controller: _textControllers[placeId],
                                      maxLines: null,
                                      expands: true,
                                      textAlignVertical: TextAlignVertical.top,
                                      decoration: const InputDecoration(
                                        hintText: '일기 내용을 입력하세요...',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.all(16),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.6,
                                      ),
                                    )
                                    : SingleChildScrollView(
                                      child: Text(
                                        _textControllers[placeId]?.text ??
                                            _currentDiaryMap[placeId] ??
                                            '일기 내용이 없습니다.',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          height: 1.6,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                          ),

                          // 편집 모드일 때 도움말 텍스트
                          if (isEditing)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '편집 중입니다. 완료하려면 체크 버튼을 눌러주세요.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 네비게이션 버튼
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentPage > 0 ? _previousPage : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('이전'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                ),

                // 페이지 인디케이터 점들
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.places.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            index == _currentPage
                                ? Colors.blue
                                : Colors.grey[300],
                      ),
                    ),
                  ),
                ),

                ElevatedButton.icon(
                  onPressed:
                      _currentPage < widget.places.length - 1
                          ? _nextPage
                          : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('다음'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// DiaryScreen 클래스들 추가
class DiaryScreen extends StatefulWidget {
  final DiaryEntry? initialEntry;
  const DiaryScreen({super.key, this.initialEntry});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<DiaryEntry> diaryEntries = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialEntry != null) {
      diaryEntries.insert(0, widget.initialEntry!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('저장된 일기')),
      body:
          diaryEntries.isEmpty
              ? const Center(
                child: Text(
                  '저장된 일기가 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView.builder(
                itemCount: diaryEntries.length,
                itemBuilder: (_, index) {
                  final entry = diaryEntries[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          '${entry.date.day}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(entry.title),
                      subtitle: Text(
                        '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final updatedEntry = await Navigator.push<DiaryEntry>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DiaryDetailScreen(entry: entry),
                          ),
                        );

                        if (updatedEntry != null) {
                          setState(() {
                            diaryEntries[index] = updatedEntry;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
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

  void _toggleEdit() {
    if (isEditing) {
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
            child: Text(
              isEditing ? '완료' : '수정',
              style: const TextStyle(color: Colors.white),
            ),
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
              decoration: InputDecoration(
                labelText: '제목',
                border:
                    isEditing ? const OutlineInputBorder() : InputBorder.none,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                readOnly: !isEditing,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  labelText: '내용',
                  border:
                      isEditing ? const OutlineInputBorder() : InputBorder.none,
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
