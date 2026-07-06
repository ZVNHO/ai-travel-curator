// import 'package:cloud_firestore/cloud_firestore.dart';

// Future<void> saveTravelCourse({
//  required String userId,
//   required String courseName,
//   required List<Map<String, dynamic>> places, // ✅ 여기가 'places'
// }) async {
//   try {
//     final FirebaseFirestore firestore = FirebaseFirestore.instance;

//     await firestore.collection('travel_courses').add({
//       'userId': userId,
//       'courseName': courseName,
//       'places': places, // <- 여기도 'places'
//       'createdAt': FieldValue.serverTimestamp(),
//     });

//     print('Travel course 저장 완료!');
//   } catch (e) {
//     print('저장 실패: $e');
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> saveTravelCourse({
  required String userId,
  required String courseName,
  required List<Map<String, dynamic>> places, // ✅ 여기가 'places'
}) async {
  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    await firestore.collection('travel_courses').add({
      'userId': userId,
      'courseName': courseName,
      'places': places, // <- 여기도 'places'
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    print('Travel course 저장 완료!');
  } catch (e) {
    print('저장 실패: $e');
    throw e; // 오류를 다시 throw하여 호출자가 처리할 수 있도록 함
  }
}