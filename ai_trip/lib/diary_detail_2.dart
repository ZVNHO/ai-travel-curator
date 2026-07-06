import 'dart:convert';
import 'dart:io';
import 'package:ai_trip/diary_gpt_screen_byplace.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker_view/multi_image_picker_view.dart';
import 'diary_gpt.dart';

class DiaryDetailScreen extends StatefulWidget {
  final String courseId;
  final String title;

  const DiaryDetailScreen({
    super.key,
    required this.courseId,
    required this.title,
  });

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  static const String _openAiApiKey = "YOUR_OPENAI_API_KEY";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  final Map<String, MultiImagePickerController> _imageControllers = {};
  Map<String, Map<String, dynamic>> _placeNotes = {};
  List<Map<String, dynamic>> _places = [];
  bool _isLoading = true;
  bool _isGeneratingDiary = false;

  // 선택 옵션들을 상수로 정의
  static const List<String> _weatherOptions = [
    '맑음',
    '구름 조금',
    '흐림',
    '비',
    '천둥번개',
    '눈',
    '바람',
    '안개',
    '추움',
    '더움',
  ];

  static const List<String> _moodOptions = [
    '설렘',
    '평온함',
    '감탄',
    '유쾌함',
    '그리움',
    '만족감',
    '아쉬움',
    '행복',
    '놀라움',
  ];

  static const List<String> _atmosphereOptions = [
    '조용',
    '평화',
    '활기',
    '북적',
    '고즈넉',
    '자연',
    '여유',
    '낭만',
    '감각',
    '세련',
    '웅장',
    '신비',
    '예술적',
    '독특',
    '청량',
    '상쾌',
    '몽환',
    '이국적',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  // 초기화 로직을 분리
  Future<void> _initializeData() async {
    await Future.wait([_loadCourseData(), _loadExistingNotes()]);
  }

  // 컨트롤러 정리
  void _disposeControllers() {
    for (final controller in _imageControllers.values) {
      controller.dispose();
    }
    _imageControllers.clear();
  }

  // 코스 데이터 로드
  Future<void> _loadCourseData() async {
    try {
      final doc =
          await _firestore
              .collection('travel_courses')
              .doc(widget.courseId)
              .get();

      if (!doc.exists) {
        debugPrint('❗ 코스 문서가 존재하지 않습니다.');
        setState(() => _isLoading = false);
        return;
      }

      final data = doc.data();
      if (data == null) {
        debugPrint('❗ 코스 데이터가 null입니다.');
        setState(() => _isLoading = false);
        return;
      }

      _places = _parsePlacesData(data['places']);
      debugPrint('✅ 코스 데이터 로드 성공: ${_places.length}개 장소');
    } catch (e) {
      debugPrint('❌ 코스 데이터 로드 실패: $e');
      _showErrorSnackBar('코스 데이터를 불러오는데 실패했습니다.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Places 데이터 파싱 로직 분리
  List<Map<String, dynamic>> _parsePlacesData(dynamic placesData) {
    if (placesData is! List) {
      debugPrint('❗ places 필드가 List 형식이 아닙니다.');
      return [];
    }

    return placesData.asMap().entries.map((entry) {
      final index = entry.key;
      final place = Map<String, dynamic>.from(entry.value);

      return {
        ...place,
        'placeId':
            place['placeId']?.toString() ??
            place['name']?.toString() ??
            'place_$index',
      };
    }).toList();
  }

  // Diary ID 조회
  Future<String?> _getDiaryIdFromCourseId(String courseId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('❗ 사용자가 로그인되어 있지 않습니다.');
      return null;
    }

    try {
      final snapshot =
          await _firestore
              .collection('diary')
              .where('courseId', isEqualTo: courseId)
              .where('userId', isEqualTo: uid)
              .limit(1)
              .get();

      return snapshot.docs.isNotEmpty ? snapshot.docs.first.id : null;
    } catch (e) {
      debugPrint('❌ Diary ID 조회 실패: $e');
      return null;
    }
  }

  // 이미지 컨트롤러 관리
  MultiImagePickerController _getImageControllerFor(String placeId) {
    return _imageControllers.putIfAbsent(placeId, () {
      final controller = MultiImagePickerController(
        maxImages: 5,
        picker: (int count, Object? params) async {
          try {
            final picked = await _picker.pickMultiImage();
            return picked
                .map(
                  (x) => ImageFile(
                    UniqueKey().toString(),
                    name: x.name,
                    extension: x.name.split('.').last,
                    path: x.path,
                  ),
                )
                .toList();
          } catch (e) {
            debugPrint('❌ 이미지 선택 실패: $e');
            return [];
          }
        },
      );

      _initializeExistingImages(controller, placeId);
      return controller;
    });
  }

  // 기존 이미지 초기화
  void _initializeExistingImages(
    MultiImagePickerController controller,
    String placeId,
  ) {
    final existingImages = _placeNotes[placeId]?['images'];
    if (existingImages is List<String>) {
      for (final imagePath in existingImages) {
        final file = File(imagePath);
        if (file.existsSync()) {
          controller.addImage(
            ImageFile(
              UniqueKey().toString(),
              name: imagePath.split('/').last,
              extension: imagePath.split('.').last,
              path: imagePath,
            ),
          );
        }
      }
    }
  }

  // 이미지 업로드
  Future<List<String>> _uploadImagesForPlace(String placeId) async {
    final controller = _getImageControllerFor(placeId);
    final List<String> downloadUrls = [];

    for (final imageFile in controller.images) {
      try {
        final filePath = imageFile.path;
        if (filePath == null || !File(filePath).existsSync()) continue;

        final file = File(filePath);
        final fileName =
            'diary/$placeId/${DateTime.now().millisecondsSinceEpoch}_${imageFile.name ?? 'image.jpg'}';
        final ref = FirebaseStorage.instance.ref().child(fileName);

        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        downloadUrls.add(url);
      } catch (e) {
        debugPrint('❌ 이미지 업로드 실패: $e');
      }
    }

    return downloadUrls;
  }

  // 기존 노트 로드
  Future<void> _loadExistingNotes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot =
          await _firestore
              .collection('diary_notes')
              .where('courseId', isEqualTo: widget.courseId)
              .where('userId', isEqualTo: uid)
              .get();

      final Map<String, Map<String, dynamic>> notes = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final placeId = data['placeId']?.toString();
        if (placeId != null) {
          notes[placeId] = {...data, 'docId': doc.id};
        }
      }

      if (mounted) {
        setState(() => _placeNotes = notes);
      }
    } catch (e) {
      debugPrint('❌ 기존 노트 로드 실패: $e');
    }
  }

  // 장소별 일기 재생성
  Future<void> _regeneratePlaceDiary({
    required String diaryId,
    required String placeId,
    required String placeName,
    required int day,
    required Map<String, dynamic> note,
  }) async {
    try {
      final prompt = _buildDiaryPrompt(placeName, day, note);
      final newText = await _askGpt(prompt);
      final imageUrls = List<String>.from(note['images'] ?? []);

      await _saveGptTextToFirestore(
        diaryId: diaryId,
        placeId: placeId,
        placeName: placeName,
        day: day,
        gptText: newText,
        imageUrls: imageUrls,
      );
    } catch (e) {
      debugPrint('❌ 장소별 일기 재생성 실패: $e');
      _showErrorSnackBar('일기 재생성에 실패했습니다.');
    }
  }

  // 장소 노트 저장
  Future<void> _savePlaceNote({
    required String placeId,
    required List<String> weather,
    required List<String> mood,
    required List<String> atmosphere,
    required String note,
    required List<String> imagePaths,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showErrorSnackBar('로그인이 필요합니다.');
      return;
    }

    try {
      final existing = _placeNotes[placeId];
      final data = {
        'userId': uid,
        'courseId': widget.courseId,
        'placeId': placeId,
        'weather': weather,
        'mood': mood,
        'atmosphere': atmosphere,
        'note': note,
        'images': imagePaths,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      String? docId;
      if (existing?['docId'] != null) {
        docId = existing!['docId'] as String;
        await _firestore.collection('diary_notes').doc(docId).update(data);
      } else {
        final docRef = await _firestore.collection('diary_notes').add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
        docId = docRef.id;
      }

      setState(() {
        _placeNotes[placeId] = {...data, 'docId': docId};
      });

      _showSuccessSnackBar('저장되었습니다.');
    } catch (e) {
      debugPrint('❌ 장소 노트 저장 실패: $e');
      _showErrorSnackBar('저장 중 오류가 발생했습니다.');
    }
  }

  // GPT 텍스트를 Firestore에 저장
  Future<void> _saveGptTextToFirestore({
    required String diaryId,
    required String placeId,
    required String placeName,
    required int day,
    required String gptText,
    required List<String> imageUrls,
  }) async {
    try {
      final ref = _firestore
          .collection('diary')
          .doc(diaryId)
          .collection('places')
          .doc(placeId);

      await ref.set({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'place_name': placeName,
        'day': day,
        'gpt_text': gptText,
        'image_urls': imageUrls,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ GPT 텍스트 저장 실패: $e');
      throw Exception('일기 저장에 실패했습니다.');
    }
  }

  // 장소 노트 다이얼로그 표시
  Future<void> _showPlaceNoteDialog(
    Map<String, dynamic> place,
    String placeId,
  ) async {
    final existing = _placeNotes[placeId];
    final controller = _getImageControllerFor(placeId);

    // 기존 데이터로 초기화
    List<String> weathers = List<String>.from(existing?['weather'] ?? []);
    List<String> moods = List<String>.from(existing?['mood'] ?? []);
    List<String> atmospheres = List<String>.from(existing?['atmosphere'] ?? []);
    final noteController = TextEditingController(text: existing?['note'] ?? '');

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('${place['name']} 코스 기록하기'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildImageSection(controller, setState),
                        const SizedBox(height: 16),
                        _buildChipSection(
                          '날씨',
                          _weatherOptions,
                          weathers,
                          setState,
                        ),
                        const SizedBox(height: 16),
                        _buildChipSection('기분', _moodOptions, moods, setState),
                        const SizedBox(height: 16),
                        _buildChipSection(
                          '분위기',
                          _atmosphereOptions,
                          atmospheres,
                          setState,
                        ),
                        const SizedBox(height: 16),
                        _buildMemoSection(noteController),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _savePlaceNote(
                          placeId: placeId,
                          weather: weathers,
                          mood: moods,
                          atmosphere: atmospheres,
                          note: noteController.text,
                          imagePaths:
                              controller.images.map((f) => f.path!).toList(),
                        );
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('저장'),
                    ),
                  ],
                ),
          ),
    );
  }

  // 이미지 섹션 위젯
  Widget _buildImageSection(
    MultiImagePickerController controller,
    StateSetter setState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('사진 (최대 5장)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            await controller.pickImages();
            setState(() {});
          },
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.add_a_photo, color: Colors.black54),
            ),
          ),
        ),
        if (controller.images.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                controller.images.map((img) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File(img.path!),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }

  // 칩 섹션 위젯
  Widget _buildChipSection(
    String title,
    List<String> options,
    List<String> selected,
    StateSetter setState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              options
                  .map(
                    (option) => FilterChip(
                      label: Text(option),
                      selected: selected.contains(option),
                      onSelected:
                          (isSelected) => setState(() {
                            isSelected
                                ? selected.add(option)
                                : selected.remove(option);
                          }),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  // 메모 섹션 위젯
  Widget _buildMemoSection(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('메모', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '이 장소에 대한 느낌이나 기억을 남겨보세요.',
          ),
        ),
      ],
    );
  }

  // 일기 텍스트 맵 생성
  Future<Map<String, String>> _buildDiaryTextMap() async {
    await _loadExistingNotes();

    final sortedPlaces = [..._places]..sort((a, b) {
      final dayA = int.tryParse(a['day'].toString()) ?? 0;
      final dayB = int.tryParse(b['day'].toString()) ?? 0;
      return dayA.compareTo(dayB);
    });

    final Map<String, String> diaryMap = {};

    for (final place in sortedPlaces) {
      final placeId = place['placeId'].toString();
      final note = _placeNotes[placeId] ?? _getDefaultNote();

      final prompt = _buildDiaryPrompt(place['name'], place['day'], note);

      try {
        final result = await _askGpt(prompt);
        diaryMap[placeId] = result;
      } catch (e) {
        debugPrint('❌ GPT 요청 실패 ($placeId): $e');
        diaryMap[placeId] = '일기 생성에 실패했습니다.';
      }
    }

    return diaryMap;
  }

  // 기본 노트 데이터
  Map<String, dynamic> _getDefaultNote() {
    return {
      'weather': ['정보 없음'],
      'mood': ['정보 없음'],
      'atmosphere': ['정보 없음'],
      'note': '기록 없음',
      'images': [],
    };
  }

  // 일기 프롬프트 생성
  String _buildDiaryPrompt(
    String placeName,
    dynamic day,
    Map<String, dynamic> note,
  ) {
    final weathers = (note['weather'] as List).join(', ');
    final moods = (note['mood'] as List).join(', ');
    final atmospheres = (note['atmosphere'] as List).join(', ');

    return '''
당신은 여행 일기를 대신 써주는 작가입니다.

- 장소: $placeName
- 방문일차: ${day}일차
- 날씨: $weathers
- 기분: $moods
- 분위기: $atmospheres
- 메모: ${note['note'] ?? '기록 없음'}

조건:
- 문장은 자연스럽게 연결되도록 작성
- 방문일차와 장소명을 꼭 포함
- 한국어로 작성
- 150자 이내로 간결하게 작성
''';
  }

  // GPT API 호출
  Future<String> _askGpt(String prompt) async {
    const apiKey =
        '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';

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    print('응답 코드: ${response.statusCode}');
    print('응답 바디: ${utf8.decode(response.bodyBytes)}');

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body['choices'][0]['message']['content'].toString().trim();
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }

  // 에러 스낵바 표시
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // 성공 스낵바 표시
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  // 저장 버튼 핸들러
  Future<void> _handleSavePressed(Map<String, String> diaryMap) async {
    try {
      final diaryId = await _getDiaryIdFromCourseId(widget.courseId);
      if (diaryId == null) {
        throw Exception('일기 ID를 찾을 수 없습니다.');
      }

      for (final place in _places) {
        final placeId = place['placeId'].toString();
        final placeName = place['name']?.toString() ?? '';
        final day = int.tryParse(place['day'].toString()) ?? 1;
        final gptText = diaryMap[placeId] ?? '기록 없음';
        final imageUrls = await _uploadImagesForPlace(placeId);

        await _saveGptTextToFirestore(
          diaryId: diaryId,
          placeId: placeId,
          placeName: placeName,
          day: day,
          gptText: gptText,
          imageUrls: imageUrls,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar('일기가 저장되었습니다.');
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ 일기 저장 실패: $e');
      _showErrorSnackBar('일기 저장에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), elevation: 0),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isGeneratingDiary
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 40,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      "일기를 생성하는 중입니다",
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
                        valueColor: AlwaysStoppedAnimation(Colors.blue),
                      ),
                    ),
                  ],
                ),
              )
              : _places.isEmpty
              ? const Center(
                child: Text(
                  '등록된 장소가 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _places.length,
                itemBuilder: (context, index) {
                  final place = _places[index];
                  final placeId = place['placeId'].toString();
                  final hasNote = _placeNotes.containsKey(placeId);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            hasNote
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                        child: Icon(
                          Icons.location_on,
                          color: hasNote ? Colors.blue : Colors.grey,
                        ),
                      ),
                      title: Text(
                        place['name']?.toString() ?? '장소명 없음',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle:
                          hasNote
                              ? const Text(
                                '기록 완료',
                                style: TextStyle(color: Colors.blue),
                              )
                              : const Text(
                                '기록 필요',
                                style: TextStyle(color: Colors.grey),
                              ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showPlaceNoteDialog(place, placeId),
                    ),
                  );
                },
              ),
      floatingActionButton:
          _places.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed:
                    _isGeneratingDiary
                        ? null
                        : () async {
                          setState(() => _isGeneratingDiary = true);
                          try {
                            final diaryMap = await _buildDiaryTextMap();
                            if (!mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => DiaryGptScreenByPlace(
                                      courseId: widget.courseId,
                                      courseTitle: widget.title,
                                      places: _places,
                                      diaryMap: diaryMap,
                                      onSavePressed:
                                          () async => await _handleSavePressed(
                                            diaryMap,
                                          ),
                                      // ✅ 이 부분이 추가되어야 합니다!
                                      onRegenerateDiary: (
                                        String placeId,
                                        String placeName,
                                      ) async {
                                        // 해당 장소의 정보를 찾기
                                        final place = _places.firstWhere(
                                          (p) =>
                                              p['placeId'].toString() ==
                                              placeId,
                                          orElse: () => {'day': 1}, // 기본값
                                        );
                                        final day =
                                            int.tryParse(
                                              place['day'].toString(),
                                            ) ??
                                            1;

                                        // 기존 노트 데이터 가져오기 (없으면 기본값 사용)
                                        final note =
                                            _placeNotes[placeId] ??
                                            _getDefaultNote();

                                        // GPT로 새 일기 생성
                                        final prompt = _buildDiaryPrompt(
                                          placeName,
                                          day,
                                          note,
                                        );
                                        return await _askGpt(prompt);
                                      },
                                    ),
                              ),
                            );
                          } catch (e) {
                            _showErrorSnackBar('일기 생성에 실패했습니다.');
                          } finally {
                            if (mounted) {
                              setState(() => _isGeneratingDiary = false);
                            }
                          }
                        },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('일기 생성'),
              )
              : null,
    );
  }
}
