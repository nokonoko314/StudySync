import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/app_settings.dart';

class SavedBundle {
  final List<Project> projects;
  final List<Task> tasks;
  final AppSettings settings;
  SavedBundle(this.projects, this.tasks, this.settings);
}

/// tasks / projects / settings をまとめて1つのJSON文字列として
/// shared_preferences に保存・復元するサービス。
///
/// 既存プロジェクトに他の永続化方法（Hive, sqlite, サーバー同期など）が
/// あれば、この1ファイルだけ差し替えれば AppState 側は変更不要です。
class PersistenceService {
  static const _key = 'studysync_data_v1';

  static Future<SavedBundle?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final projects = (map['projects'] as List)
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList();
      final tasks = (map['tasks'] as List)
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
      final settings =
          AppSettings.fromJson(map['settings'] as Map<String, dynamic>);
      return SavedBundle(projects, tasks, settings);
    } catch (_) {
      // 壊れたデータが入っていた場合は初期データから再構築する
      return null;
    }
  }

  static Future<void> save(
      List<Project> projects, List<Task> tasks, AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'projects': projects.map((p) => p.toJson()).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'settings': settings.toJson(),
    };
    await prefs.setString(_key, jsonEncode(map));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
