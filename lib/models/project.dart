import 'package:flutter/material.dart';

/// プロジェクト（教科・科目）を表すモデル。
/// テスト期間（start〜end）はオプションで、設定すると
/// ドロワーに「テスト期間 〇/〇〜〇/〇・あとN日」と表示されます。
class Project {
  String id;
  String name;
  Color color;
  DateTime? start;
  DateTime? end;

  Project({
    required this.id,
    required this.name,
    required this.color,
    this.start,
    this.end,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.value,
        'start': start?.millisecondsSinceEpoch,
        'end': end?.millisecondsSinceEpoch,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        color: Color(json['color'] as int),
        start: json['start'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['start'] as int)
            : null,
        end: json['end'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['end'] as int)
            : null,
      );
}
