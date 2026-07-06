//profile_screen.dart
import 'package:flutter/material.dart';
import 'diary_save.dart';
import 'course_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'introduction_animation/introduction_animation_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'travel_style_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String nickname = '닉네임';
  String profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      getUserProfile(uid).then((profile) {
        setState(() {
          nickname = profile['nickname']!;
          profileImageUrl = profile['profileImageUrl']!;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 상단 헤더 부분
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'RouteMaker',
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
                      const SizedBox(height: 30),
                      // 프로필 이미지와 정보
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : null,
                        child:
                            profileImageUrl.isEmpty
                                ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                )
                                : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        nickname,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => EditProfileScreen(
                                    initialNickname: nickname,
                                    initialProfileImageUrl: profileImageUrl,
                                  ),
                            ),
                          );
                          if (result != null && result is Map<String, String>) {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .update({
                                    'nickname': result['nickname'],
                                    'profileImageUrl':
                                        result['profileImageUrl'],
                                  });
                            }
                            setState(() {
                              nickname = result['nickname'] ?? nickname;
                              profileImageUrl =
                                  result['profileImageUrl'] ?? profileImageUrl;
                            });
                          }
                        },
                        child: const Text(
                          '프로필 편집',
                          style: TextStyle(color: Colors.blue, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 메뉴 카드들
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildMenuCard(
                      icon: Icons.route,
                      title: '저장된 코스',
                      subtitle: '내가 만든 여행 코스를 확인하세요',
                      onTap: () {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      CourseScreen(userId: currentUser.uid),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('로그인이 필요합니다.')),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      icon: Icons.book,
                      title: '저장된 일기',
                      subtitle: '여행의 추억을 기록해보세요',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiaryScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      icon: Icons.psychology,
                      title: '내 성향',
                      subtitle: '나만의 여행 스타일을 확인하세요',
                      onTap: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final userId = user.uid;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      TravelStyleScreen(userId: userId),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('로그인이 필요합니다.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 하단 액션 버튼들
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.logout,
                              color: Colors.grey,
                            ),
                            title: const Text(
                              '로그아웃',
                              style: TextStyle(fontSize: 16),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () async {
                              final confirmed = await _showConfirmDialog(
                                '로그아웃 하시겠습니까?',
                              );
                              if (confirmed) {
                                await FirebaseAuth.instance.signOut();
                                if (context.mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const IntroductionAnimationScreen(),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          Divider(height: 1, color: Colors.grey[200]),
                          ListTile(
                            leading: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            title: const Text(
                              '계정삭제',
                              style: TextStyle(fontSize: 16, color: Colors.red),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.red,
                            ),
                            onTap: () async {
                              final confirmed = await _showConfirmDialog(
                                '정말로 계정을 삭제하시겠습니까?',
                              );
                              if (confirmed) {
                                final password = await _getPasswordFromUser();
                                if (password == null || password.isEmpty)
                                  return;

                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null && user.email != null) {
                                  final cred = EmailAuthProvider.credential(
                                    email: user.email!,
                                    password: password,
                                  );
                                  try {
                                    await user.reauthenticateWithCredential(
                                      cred,
                                    );
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .delete();
                                    await user.delete();
                                    if (context.mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const IntroductionAnimationScreen(),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '계정 삭제 중 오류가 발생했습니다. 다시 시도해주세요.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('확인'),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('아니오'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('예'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<String?> _getPasswordFromUser() async {
    String? password;
    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('비밀번호 확인'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '비밀번호를 입력하세요',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                password = controller.text;
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
    return password;
  }
}

class EditProfileScreen extends StatefulWidget {
  final String initialNickname;
  final String initialProfileImageUrl;

  const EditProfileScreen({
    super.key,
    required this.initialNickname,
    required this.initialProfileImageUrl,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nicknameController;
  late TextEditingController profileImageController;
  final ImagePicker _picker = ImagePicker();

  String profileImageUrl = '';
  File? _selectedImage;
  bool isUploading = false;

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  Future<void> _uploadToFirebaseAndSave() async {
    if (_selectedImage == null) return;

    setState(() => isUploading = true);

    try {
      final fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(_selectedImage!.path)}';
      final ref = FirebaseStorage.instance.ref().child(
        'profile_images/$fileName',
      );

      await ref.putFile(_selectedImage!);
      final downloadUrl = await ref.getDownloadURL();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'nickname': nicknameController.text,
          'profileImageUrl': downloadUrl,
        }, SetOptions(merge: true));
      }

      setState(() {
        profileImageUrl = downloadUrl;
        isUploading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('업로드 및 저장 완료')));
    } catch (e) {
      setState(() => isUploading = false);
      print("오류 발생: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    nicknameController = TextEditingController(text: widget.initialNickname);
    profileImageController = TextEditingController(
      text: widget.initialProfileImageUrl,
    );
    profileImageUrl = widget.initialProfileImageUrl;
  }

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
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '프로필 편집',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        isUploading
                            ? null
                            : () async {
                              await _uploadToFirebaseAndSave();
                              Navigator.pop(context, {
                                'nickname': nicknameController.text,
                                'profileImageUrl': profileImageUrl,
                              });
                            },
                    child: Text(
                      isUploading ? '저장중...' : '저장',
                      style: TextStyle(
                        color: isUploading ? Colors.grey : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 편집 폼
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // 프로필 이미지 편집
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : (profileImageUrl.isNotEmpty
                                          ? NetworkImage(profileImageUrl)
                                          : null)
                                      as ImageProvider<Object>?,
                          child:
                              (_selectedImage == null &&
                                      profileImageUrl.isEmpty)
                                  ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  )
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImageFromGallery,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // 닉네임 입력 필드
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: nicknameController,
                        decoration: const InputDecoration(
                          labelText: '닉네임',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<Map<String, String>> getUserProfile(String uid) async {
  final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

  if (doc.exists) {
    final data = doc.data()!;
    return {
      'nickname': data['nickname'] ?? '닉네임',
      'profileImageUrl': data['profileImageUrl'] ?? '',
    };
  } else {
    return {'nickname': '', 'profileImageUrl': ''};
  }
}
