import 'package:cloud_firestore/cloud_firestore.dart';

/// ご要望・不具合報告をFirestoreに送信するサービス。
///
/// 注意：Firestoreの既定のセキュリティルールでは、知らないコレクションへの
/// 書き込みは拒否されます。Firebaseコンソール →Firestore Database→ルール で、
/// 次のようなルールを追加してください（誰でも書き込み・自分では読めない、
/// 運営だけが見られる想定の簡易版）。
///
/// match /feedback/{doc} {
///   allow create: if true;
///   allow read, update, delete: if false;
/// }
class FeedbackService {
  static CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore.instance.collection('feedback');

  static Future<void> submit({
    required String text,
    String? email,
    String? appVersion,
  }) async {
    await _col.add({
      'text': text,
      'email': email,
      'appVersion': appVersion,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
