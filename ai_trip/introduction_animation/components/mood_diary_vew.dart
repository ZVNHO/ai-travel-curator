import 'package:flutter/material.dart';

class TravelStyleView extends StatefulWidget {
  final AnimationController animationController;

  const TravelStyleView({super.key, required this.animationController});

  @override
  TravelStyleViewState createState() => TravelStyleViewState();
}

class TravelStyleViewState extends State<TravelStyleView> {
  // 동행 옵션
  final List<Map<String, String>> companionOptions = [
    {'label': '나홀로'},
    {'label': '연인과'},
    {'label': '친구와'},
    {'label': '가족과'},
    {'label': '효도'},
    {'label': '자녀와'},
    {'label': '반려동물과'},
  ];
  
  // 일정 옵션
  final List<String> scheduleOptions = [
    '알찬 일정',
    '여유있는 일정',
  ];
  
  // 여행 스타일 옵션
  final List<Map<String, String>> travelStyleOptions = [
    {'label': '힐링'},
    {'label': '활동적인'},
    {'label': '배움이 있는'},
    {'label': '맛있는'},
    {'label': '교통이 편한'},
    {'label': '알뜰한'},
  ];
  
  // 활동 옵션
  final List<Map<String, String>> activityOptions = [
    {'label': '레저 스포츠'},
    {'label': '문화시설'},
    {'label': '사진 명소'},
    {'label': '이색체험'},
    {'label': '유적지'},
    {'label': '박물관'},
    {'label': '공원'},
    {'label': '사찰'},
    {'label': '성지'},
  ];
  
  // 장소 옵션
  final List<Map<String, String>> placeOptions = [
    {'label': '바다'},
    {'label': '산'},
    {'label': '드라이브'},
    {'label': '산책'},
    {'label': '쇼핑'},
    {'label': '실내여행지'},
    {'label': '시티투어'},
    {'label': '전통'},
  ];

  // 선택된 항목들 저장
  final Set<String> _selectedCompanions = {};
  final Set<String> _selectedSchedules = {};
  final Set<String> _selectedTravelStyles = {};
  final Set<String> _selectedActivities = {};
  final Set<String> _selectedPlaces = {};

  // 선택 토글 함수
  void _toggleCompanion(String option) {
    setState(() {
      if (_selectedCompanions.contains(option)) {
        _selectedCompanions.remove(option);
      } else {
        _selectedCompanions.add(option);
      }
    });
  }

  void _toggleSchedule(String option) {
    setState(() {
      if (_selectedSchedules.contains(option)) {
        _selectedSchedules.remove(option);
      } else {
        // 일정 옵션은 하나만 선택 가능하도록
        _selectedSchedules.clear();
        _selectedSchedules.add(option);
      }
    });
  }

  void _toggleTravelStyle(String option) {
    setState(() {
      if (_selectedTravelStyles.contains(option)) {
        _selectedTravelStyles.remove(option);
      } else {
        _selectedTravelStyles.add(option);
      }
    });
  }

  void _toggleActivity(String option) {
    setState(() {
      if (_selectedActivities.contains(option)) {
        _selectedActivities.remove(option);
      } else {
        _selectedActivities.add(option);
      }
    });
  }

  void _togglePlace(String option) {
    setState(() {
      if (_selectedPlaces.contains(option)) {
        _selectedPlaces.remove(option);
      } else {
        _selectedPlaces.add(option);
      }
    });
  }

  // 외부에서 선택된 정보 접근할 수 있도록 getter
  String get selectedCompanions => _selectedCompanions.join(', ');
  String get selectedSchedule => _selectedSchedules.join(', ');
  String get selectedTravelStyles => _selectedTravelStyles.join(', ');
  String get selectedActivities => _selectedActivities.join(', ');
  String get selectedPlaces => _selectedPlaces.join(', ');
  
  // 기존 코드와의 호환성을 위한 getter
  String get selectedStyle {
    List<String> allSelected = [];
    
    if (_selectedTravelStyles.isNotEmpty) {
      allSelected.addAll(_selectedTravelStyles);
    }
    if (_selectedCompanions.isNotEmpty) {
      allSelected.addAll(_selectedCompanions);
    }
    if (_selectedSchedules.isNotEmpty) {
      allSelected.addAll(_selectedSchedules);
    }
    if (_selectedActivities.isNotEmpty) {
      allSelected.addAll(_selectedActivities);
    }
    if (_selectedPlaces.isNotEmpty) {
      allSelected.addAll(_selectedPlaces);
    }
    
    return allSelected.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final firstHalfAnimation =
        Tween<Offset>(begin: const Offset(1, 0), end: const Offset(0, 0))
            .animate(CurvedAnimation(
      parent: widget.animationController,
      curve: const Interval(
        0.4,
        0.6,
        curve: Curves.fastOutSlowIn,
      ),
    ));
    final secondHalfAnimation =
        Tween<Offset>(begin: const Offset(0, 0), end: const Offset(-1, 0))
            .animate(CurvedAnimation(
      parent: widget.animationController,
      curve: const Interval(
        0.6,
        0.8,
        curve: Curves.fastOutSlowIn,
      ),
    ));

    return SlideTransition(
      position: firstHalfAnimation,
      child: SlideTransition(
        position: secondHalfAnimation,
        child: Padding(
          padding: EdgeInsets.only(
            top: 58 + MediaQuery.of(context).padding.top,
            bottom: 200,
            left: 16, 
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "선호하는 여행 스타일을 알려주세요",
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12), // 간격 축소
                
                // 동행 옵션
                _buildSectionTitle("누구와 함께 가나요?"),
                _buildOptionGrid(
                  companionOptions.map((opt) => opt['label']!).toList(),
                  _selectedCompanions,
                  _toggleCompanion,
                  crossAxisCount: 4,
                ),
                
                // 일정 옵션
                _buildSectionTitle("일정 스타일"),
                _buildOptionGrid(
                  scheduleOptions,
                  _selectedSchedules,
                  _toggleSchedule,
                  crossAxisCount: 2,
                ),
                
                // 여행 스타일 옵션
                _buildSectionTitle("여행 스타일"),
                _buildOptionGrid(
                  travelStyleOptions.map((opt) => opt['label']!).toList(),
                  _selectedTravelStyles,
                  _toggleTravelStyle,
                  crossAxisCount: 3,
                ),
                
                // 활동 옵션
                _buildSectionTitle("선호하는 활동"),
                _buildOptionGrid(
                  activityOptions.map((opt) => opt['label']!).toList(),
                  _selectedActivities,
                  _toggleActivity,
                  crossAxisCount: 3,
                ),
                
                // 장소 옵션
                _buildSectionTitle("선호하는 장소"),
                _buildOptionGrid(
                  placeOptions.map((opt) => opt['label']!).toList(),
                  _selectedPlaces,
                  _togglePlace,
                  crossAxisCount: 4,
                ),
                
                const SizedBox(height: 10), // 하단 간격 줄임
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 섹션 제목 위젯
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6), // 간격 축소
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16, // 폰트 크기 축소
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  // 옵션 그리드 생성 위젯 - 버튼 크기 축소
  Widget _buildOptionGrid(
    List<String> options,
    Set<String> selectedOptions,
    Function(String) toggleFunction, {
    required int crossAxisCount,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 2.8, // 비율 조정으로 버튼 높이 감소
        crossAxisSpacing: 6, // 간격 축소
        mainAxisSpacing: 6, // 간격 축소
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selectedOptions.contains(option);
        return GestureDetector(
          onTap: () => toggleFunction(option),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), // 패딩 축소
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.white,
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(12), // 모서리 반경 축소
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 15, // 폰트 크기 축소
                  color: isSelected ? Colors.white : Colors.blue,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}