import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/app_settings.dart';
import 'persistence_service.dart';

/// Googleアカウントでログインしている間、tasks / projects / settings を
/// Firestore に保存・復元することで、同じアカウントでログインした
/// 別の端末（iPad・スマホなど）でも同じデータを使えるようにするサービス。
///
/// 注意：これを使うには、あなた自身のFirebaseプロジェクトが必要です。
/// プロジェクト直下の README_FLUTTER.md に作成手順を書いています。
///
/// データ構造はシンプルに、PersistenceServiceと全く同じJSONを
/// 1つの文字列フィールドとして保存しています（Firestoreの型変換の
/// 落とし穴を避けるため）。
class SyncService {
  static CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('studysync_users');

  static Future<void> push(
      String uid, List<Project> projects, List<Task> tasks, AppSettings settings) async {
    final jsonStr = jsonEncode({
      'projects': projects.map((p) => p.toJson()).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'settings': settings.toJson(),
    });
    await _col.doc(uid).set({
      'json': jsonStr,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<SavedBundle?> pull(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    final jsonStr = doc.data()?['json'] as String?;
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final projects = (map['projects'] as List)
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList();
      final tasks = (map['tasks'] as List)
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
      final settings = AppSettings.fromJson(map['settings'] as Map<String, dynamic>);
      return SavedBundle(projects, tasks, settings);
    } catch (_) {
      return null;
    }
  }
}
