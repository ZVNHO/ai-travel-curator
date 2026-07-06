// // diary_gpt.dart (최종 버전)
// import 'package:flutter/material.dart';

// class DiaryGptScreen extends StatefulWidget {
//   final String courseTitle;
//   final String diaryText;
//   final Future<String> Function()? onRetry;

//   const DiaryGptScreen({
//     super.key,
//     required this.courseTitle,
//     required this.diaryText,
//     this.onRetry,
//   });

//   @override
//   State<DiaryGptScreen> createState() => _DiaryGptScreenState();
// }

// class _DiaryGptScreenState extends State<DiaryGptScreen> {
//   late TextEditingController _controller;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = TextEditingController(text: widget.diaryText);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   Future<void> _regenerateDiary() async {
//     if (widget.onRetry == null) return;
//     setState(() => _isLoading = true);

//     final regenerated = await widget.onRetry!();

//     setState(() {
//       _controller.text = regenerated;
//       _isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('${widget.courseTitle} - 자동 생성 일기')),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             const Text(
//               '📖 생성된 일기',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: TextField(
//                 controller: _controller,
//                 maxLines: null,
//                 expands: true,
//                 decoration: InputDecoration(
//                   border: OutlineInputBorder(),
//                   hintText: 'GPT가 생성한 일기가 여기에 표시됩니다.',
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             if (_isLoading)
//               CircularProgressIndicator()
//             else
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: _regenerateDiary,
//                     icon: const Icon(Icons.refresh),
//                     label: const Text('다시 생성'),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: () => Navigator.pop(context, _controller.text),
//                     icon: const Icon(Icons.check),
//                     label: const Text('완료'),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class DiaryGptScreen extends StatefulWidget {
  final String courseTitle;
  final String diaryText;
  final Future<String> Function()? onRetry;
  final VoidCallback? onSave; // 저장 콜백 추가

  const DiaryGptScreen({
    super.key,
    required this.courseTitle,
    required this.diaryText,
    this.onRetry,
    this.onSave,
  });

  @override
  State<DiaryGptScreen> createState() => _DiaryGptScreenState();
}

class _DiaryGptScreenState extends State<DiaryGptScreen> {
  late TextEditingController _controller;
  bool _isLoading = false;
  bool _hasChanges = false; // 변경사항 추적

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.diaryText);

    // 텍스트 변경 감지
    _controller.addListener(() {
      if (!_hasChanges && _controller.text != widget.diaryText) {
        setState(() => _hasChanges = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _regenerateDiary() async {
    if (widget.onRetry == null) return;

    // 변경사항이 있을 때 확인 다이얼로그
    if (_hasChanges) {
      final shouldRegenerate = await _showRegenerateDialog();
      if (!shouldRegenerate) return;
    }

    setState(() => _isLoading = true);

    try {
      final regenerated = await widget.onRetry!();
      setState(() {
        _controller.text = regenerated;
        _hasChanges = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('일기가 다시 생성되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기 재생성 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<bool> _showRegenerateDialog() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('일기 다시 생성'),
                content: const Text('현재 수정한 내용이 사라집니다. 계속하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('계속'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _saveDiary() async {
    if (widget.onSave != null) {
      try {
        widget.onSave!();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('일기가 저장되었습니다.'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, _controller.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } else {
      Navigator.pop(context, _controller.text);
    }
  }

  // 뒤로가기 시 변경사항 확인
  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('변경사항이 있습니다'),
                content: const Text('저장하지 않고 나가시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('나가기'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.courseTitle} - 자동 생성 일기'),
          backgroundColor: Colors.blue.shade50,
          elevation: 0,
          actions: [
            if (_hasChanges)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '수정됨',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 섹션
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.auto_stories,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📖 AI가 생성한 여행 일기',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '자유롭게 수정하고 저장하세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 일기 텍스트 입력 영역
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        letterSpacing: 0.5,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(20),
                        hintText:
                            'AI가 생성한 일기가 여기에 표시됩니다.\n자유롭게 수정하여 나만의 일기로 만들어보세요.',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 하단 버튼들
                if (_isLoading)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text(
                            'AI가 일기를 다시 생성하고 있습니다...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              widget.onRetry != null ? _regenerateDiary : null,
                          icon: const Icon(Icons.refresh),
                          label: const Text('다시 생성'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color:
                                  widget.onRetry != null
                                      ? Colors.blue.shade300
                                      : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _saveDiary,
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text(
                            '저장하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
