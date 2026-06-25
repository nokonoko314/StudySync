import 'package:flutter/material.dart';

/// 教科（旧プロジェクト）を表すモデル。
class Project {
  String id;
  String name;
  Color color;

  Project({
    required this.id,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.value,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        color: Color(json['color'] as int),
      );
}
