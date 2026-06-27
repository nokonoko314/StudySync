import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../app_theme.dart';
import '../changelog.dart';
import '../sheets/settings_sheets.dart';
import '../sheets/project_list_sheet.dart';
import '../sheets/group_management_sheet.dart';
import '../sheets/changelog_sheet.dart';
import '../widgets/pressable.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
      children: [
        Text('設定', style: AppTheme.display(21)),
        Text('表示・連携・通知をカスタマイズ', style: AppTheme.body(12, color: AppColors.inkSoft)),
        const SizedBox(height: 16),
        _sectionLabel('表示'),
        _group([
          _row(context, Icons.wallpaper_outlined, AppColors.indigoSoft, AppColors.indigo, '壁紙', '写真またはカラーを設定', () => showWallpaperSheet(context)),
          _row(context, Icons.format_size, AppColors.sageSoft, AppColors.sage, '文字の大きさ', _fontLabel(state.settings.fontScale), () => showFontSizeSheet(context)),
          _row(context, Icons.tune, AppColors.goldSoft, AppColors.gold, 'UIの配置', 'ナビゲーションの並び順を変更', () => showLayoutSheet(context)),
        ]),
        const SizedBox(height: 8),
        _sectionLabel('タスク'),
        _group([
          _row(
            context,
            Icons.schedule_outlined,
            AppColors.indigoSoft,
            AppColors.indigo,
            'タスクの既定の期限時刻',
            '新規タスク作成時、今日の${_timeLabel(state.settings.defaultDueHour, state.settings.defaultDueMinute)}を既定値にします',
            () => _pickDefaultDueTime(context, state),
          ),
        ]),
        const SizedBox(height: 8),
        _sectionLabel('教科'),
        _group([
          _row(context, Icons.folder_outlined, AppColors.sageSoft, AppColors.sage, '教科の管理', '追加・編集・削除', () => showSubjectsSheet(context)),
        ]),
        const SizedBox(height: 8),
        _sectionLabel('プロジェクト'),
        _group([
          _row(context, Icons.label_outline, AppColors.coralSoft, AppColors.coral, 'プロジェクトの管理', 'タスク作成時に出てくる候補の追加・変更・削除',
              () => showProjectsManagementSheet(context)),
        ]),
        const SizedBox(height: 8),
        _sectionLabel('忘却曲線'),
        _group([
          _row(context, Icons.show_chart, AppColors.indigoSoft, AppColors.indigo, '復習スケジュールの手動設定', '自動追加のON/OFFと間隔を編集', () => showCurveSettingsSheet(context)),
        ]),
        const SizedBox(height: 8),
        _sectionLabel('連携'),
        _group([
          _row(context, Icons.link, AppColors.coralSoft, AppColors.coral, 'Googleアカウント連携', state.settings.googleConnected ? '連携済み' : '未連携', () => showGoogleLinkSheet(context)),
          _row(context, Icons.notifications_outlined, AppColors.goldSoft, AppColors.gold, '通知', state.settings.notifGranted ? '許可済み' : '未設定', () => showNotificationSheet(context)),
        ]),
        const SizedBox(height: 8),
        _sectionLabel('アプリ情報'),
        _group([
          _row(context, Icons.info_outline, AppColors.surface2, AppColors.inkSoft, 'StudySync', '$kAppVersion・変更履歴を見る', () => showChangelogSheet(context)),
        ]),
      ],
    );
  }

  String _fontLabel(double v) => {0.875: '小', 1.0: '標準', 1.125: '大', 1.25: '特大'}[v] ?? '標準';

  String _timeLabel(int h, int m) => '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  Future<void> _pickDefaultDueTime(BuildContext context, AppState state) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: state.settings.defaultDueHour, minute: state.settings.defaultDueMinute),
    );
    if (picked == null) return;
    state.updateSettings((s) {
      s.defaultDueHour = picked.hour;
      s.defaultDueMinute = picked.minute;
    });
  }

  Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
        child: Row(children: [
          Text(t, style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: AppColors.line)),
        ]),
      );

  Widget _group(List<Widget> children) => Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const Divider(height: 1, color: AppColors.line, indent: 15, endIndent: 15),
          ],
        ]),
      );

  Widget _row(BuildContext context, IconData icon, Color bg, Color fg, String title, String sub, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 15, color: fg)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTheme.body(14, weight: FontWeight.w700)),
              Text(sub, style: AppTheme.body(11.5, color: AppColors.inkSoft)),
            ]),
          ),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.inkFaint),
        ]),
      ),
    );
  }
}
