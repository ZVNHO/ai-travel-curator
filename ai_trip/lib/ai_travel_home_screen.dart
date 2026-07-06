//ai_travel_home_screen.dart
//ai_travel_home_screen.dart
import 'package:ai_trip/course_maker/course_maker_title_firscreen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'diary_detail_1.dart';
import 'package:ai_trip/settlement_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 홈페이지를 가운데에 위치시키기 위해 인덱스 1로 설정
  final int _selectedIndex = 1;
  // 페이지 상태를 갱신하기 위한 키 추가
  final GlobalKey<_HomePageState> _homePageKey = GlobalKey<_HomePageState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RouteMaker',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      // const 제거하고 key 추가하여 HomePage 상태 관리
      body: HomePage(key: _homePageKey),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          // 여행 아이콘 제거하고 일기 아이콘을 첫 번째로 이동
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: '일기',
            activeIcon: Icon(Icons.book, size: 28),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '홈',
            activeIcon: Icon(Icons.calendar_today, size: 28),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money),
            label: '정산',
            activeIcon: Icon(Icons.money, size: 28),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '내 정보',
            activeIcon: Icon(Icons.person, size: 28),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.black87, // 비활성화된 아이콘 색상을 더 진하게 설정
        iconSize: 24, // 기본 아이콘 크기 증가
        unselectedFontSize: 12, // 비활성화된 라벨 폰트 크기
        selectedFontSize: 14, // 활성화된 라벨 폰트 크기
        type: BottomNavigationBarType.fixed, // 네비게이션 바 타입을 fixed로 설정
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      // 일기
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DiaryScreen()),
      );
    } else if (index == 1) {
      // 홈 (현재 화면이므로 아무 것도 안 함)
    } else if (index == 2) {
      // 정산
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SettlementScreen()),
      );
    } else if (index == 3) {
      // 내 정보
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      ).then((_) {
        setState(() {});
        if (_homePageKey.currentState != null) {
          _homePageKey.currentState!._loadNickname();
        }
      });
    }
  }

  // 다른 탭에 대한 처리는 여기에 추가할 수 있습니다
}

// 여행 화면 관련 코드는 유지하되 사용하지 않음
class TravelScreen extends StatelessWidget {
  const TravelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight, size: 100, color: Colors.blue[300]),
          const SizedBox(height: 20),
          const Text(
            '여행 정보 화면',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text('여기에 여행 관련 정보가 표시됩니다.', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

// 홈 페이지 - 배너 부분 수정
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  // 배너 데이터 (여행지 이름, 이미지 URL, URL)
  final List<Map<String, String>> _bannerData = [
    {
      'name': '오월드',
      'imageUrl': 'assets/images/oland.png',
      'description': '오월드는 어때요?',
      'url': 'https://www.oworld.kr/newkfsweb/kfs/dcco/dccoMainindex.do',
    },
    {
      'name': '대청호',
      'imageUrl': 'assets/images/water.png',
      'description': '대청호는 어때요?',
      'url':
          'https://korean.visitkorea.or.kr/detail/ms_detail.do?cotid=394bc1f9-0d1b-420d-82ed-a8f4cc68f1da',
    },
    {
      'name': '성심당',
      'imageUrl': 'assets/images/sss.png',
      'description': '성심당은 어때요?',
      'url': 'https://sungsimdang.co.kr/',
    },
    {
      'name': '엑스포과학공원',
      'imageUrl': 'assets/images/s.png',
      'description': '엑스포과학공원은 어때요?',
      'url': 'https://www.djto.kr/kor/page.do?menuIdx=654',
    },
    {
      'name': '대전시립미술관',
      'imageUrl': 'assets/images/art.png',
      'description': '대전시립미술관은 어때요?',
      'url':
          'https://www.daejeon.go.kr/dma/dmaContentsHtmlView.do?menuSeq=6072',
    },
  ];

  String? nickname;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadNickname(); // 화면이 다시 표시될 때마다 닉네임 갱신
  }

  void _loadNickname() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // 캐시를 방지하기 위해 옵션 추가
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get(GetOptions(source: Source.server));

      if (doc.exists) {
        final updatedNickname = doc.data()?['nickname'] as String?;
        if (mounted) {
          setState(() {
            nickname = updatedNickname;
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNickname();
    _bannerTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        setState(() {
          _currentBannerIndex = (_currentBannerIndex + 1) % _bannerData.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void _onAiRecommendationPressed() {
    // AI 추천 기능 구현
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CourseMakerTitleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top banner with changing images and text - 배너 인디케이터 제거
          GestureDetector(
            onTap: () {
              _launchURL(_bannerData[_currentBannerIndex]['url']!);
            },
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image:
                      _bannerData[_currentBannerIndex]['imageUrl']!.startsWith(
                            'http',
                          )
                          ? NetworkImage(
                            _bannerData[_currentBannerIndex]['imageUrl']!,
                          )
                          : AssetImage(
                                _bannerData[_currentBannerIndex]['imageUrl']!,
                              )
                              as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(0.4),
                  ),
                  Positioned(
                    bottom: 80,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nickname != null
                              ? '$nickname 님,'
                              : '님,', // 불러오기 전엔 빈 값,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 3.0,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '대전 인기 여행지',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 3.0,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _bannerData[_currentBannerIndex]['description']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // AI Recommendation Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.thumb_up, color: Colors.green[300], size: 28),
                const SizedBox(width: 8),
                const Text(
                  'AI에게 추천받기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 여행 코스 추천 버튼만 추가
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InkWell(
              onTap: _onAiRecommendationPressed,
              child: Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '여행 코스 추천',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Featured Destinations Title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '2025 서울/대전 지연축제',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // 축제 카드 리스트
          SizedBox(
            height: 220,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                buildFestivalCard(
                  '2025 대청호 벚꽃축제',
                  'assets/images/festivities_1.png',
                  'https://daejeontour.co.kr/ko/festival/festivalView.do?festv_id=55&festv_nm=2025%20%EB%8C%80%EC%B2%AD%ED%98%B8%20%EB%B2%9A%EA%BD%83%EC%B6%95%EC%A0%9C%20&menuIdx=147',
                ),
                const SizedBox(width: 12),
                buildFestivalCard(
                  '2025 대덕물빛축제',
                  'assets/images/festivities_2.png',
                  'https://daejeontour.co.kr/ko/festival/festivalView.do?festv_id=54&festv_nm=2025%20%EB%8C%80%EB%8D%95%EB%AC%BC%EB%B9%9B%EC%B6%95%EC%A0%9C&menuIdx=147',
                ),
                const SizedBox(width: 12),
                buildFestivalCard(
                  '서울기록원 어린이 기록체험실',
                  'assets/images/fes_3.png',
                  'https://korean.visitseoul.net/exhibition/2024-Twisting/KOPs9gkpe',
                ),
                const SizedBox(width: 12),
                buildFestivalCard(
                  '이머시브K간송미술관 디지털 미디어아트 전시',
                  'assets/images/fes_4.png',
                  'https://korean.visitseoul.net/exhibition/2024-immersiveK/KOPd8sx8c',
                ),
                const SizedBox(width: 12),
                buildFestivalCard(
                  '기록으로 산책하기_서울의 공원',
                  'assets/images/fes_5.png',
                  'https://korean.visitseoul.net/exhibition/2024-seoulsparks/KOPmfskyu',
                ),
                const SizedBox(width: 12),
                buildFestivalCard(
                  'K-푸드 페스티벌 넉넉',
                  'assets/images/fes_6.png',
                  'https://korean.visitseoul.net/events/2024-K-FoodFestivalKnockKnock/KOPy0v1xv',
                ),
                const SizedBox(width: 12),
                buildFestivalCard(
                  '투명하고 향기나는 천사의 날개 빛깔처럼',
                  'assets/images/fes_7.png',
                  'https://korean.visitseoul.net/exhibition/2024-celestialwhisper/KOPg8me67',
                ),
                const SizedBox(width: 12),
                buildFestivalCard(
                  '2025 천호자전거거리 벚꽃라이딩챌린지',
                  'assets/images/fes_8.png',
                  'https://korean.visitseoul.net/events/2025-CheonhoBicycleStreetCherryBlossomRidingChallenge/KOPj691jr',
                ),
                const SizedBox(width: 12),
                buildFestivalCard(
                  '제 7회 대한민국맥주박람회',
                  'assets/images/fes_9.png',
                  'https://korean.visitseoul.net/events/2025koreaInternationalBeerAward/KOPwray9z',
                ),
                const SizedBox(width: 12),
                buildFestivalCard(
                  '제2회 쉬엄쉬엄 한강 3종 축제',
                  'assets/images/fes_10.png',
                  'https://korean.visitseoul.net/events/2025-mypace-hangang-triathlon-festival/KOP1x90yb',
                ),
                const SizedBox(width: 12),
                buildFestivalCard(
                  '2025 서울스프링페스타',
                  'assets/images/fes_11.png',
                  'https://korean.visitseoul.net/events/2025-seoulspringfesta/KOPof1ady',
                ),
                const SizedBox(width: 12),
                buildFestivalCard(
                  '연등회',
                  'assets/images/fes_12.png',
                  'https://korean.visitseoul.net/events/YeonDeungHoe/KOPvv2ijx',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFestivalCard(String title, String imageUrl, String url) {
    return InkWell(
      onTap: () {
        _launchURL(url);
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: AssetImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 별도의 함수로 분리된 getNickname은 제거하고 HomePage 내에서 직접 처리
