import 'package:flutter/material.dart';

/// ボトムナビゲーションの各項目のメタ情報。
/// root_shell（実際のナビバー）と、設定の「UIの配置」シートの
/// 両方から参照されるため、循環import を避けて独立ファイルにしています。
class NavMeta {
  final String label;
  final IconData icon;
  const NavMeta(this.label, this.icon);
}

const Map<String, NavMeta> kNavMeta = {
  'home': NavMeta('ホーム', Icons.home_rounded),
  'calendar': NavMeta('カレンダー', Icons.calendar_month_rounded),
  'stats': NavMeta('統計', Icons.bar_chart_rounded),
  'settings': NavMeta('設定', Icons.tune_rounded),
};
