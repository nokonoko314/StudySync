import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../state/app_state.dart';
import '../models/app_settings.dart';
import '../app_theme.dart';
import '../nav_meta.dart';
import '../utils/date_utils.dart';
import '../widgets/sheet_scaffold.dart';
import '../widgets/pressable.dart';
import '../widgets/interval_chip_editor.dart';
import '../widgets/forgetting_curve_chart.dart';
import '../services/wallpaper_file_service.dart';
import '../services/notification_service.dart';

// =====================================================================
// 壁紙
// =====================================================================

void showWallpaperSheet(BuildContext context) {
  showAppSheet(context, title: '壁紙', bodyBuilder: (ctx) => const _WallpaperBody());
}

class _WallpaperBody extends StatefulWidget {
  const _WallpaperBody();
  @override
  State<_WallpaperBody> createState() => _WallpaperBodyState();
}

class _WallpaperBodyState extends State<_WallpaperBody> {
  bool _loading = false;

  Future<void> _pickPhoto() async {
    setState(() => _loading = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file == null) return;
      final savedPath = await WallpaperFileService.saveWallpaperImage(file.path);
      if (!mounted) return;
      context.read<AppState>().updateSettings((s) {
        s.wallpaperType = WallpaperType.image;
        s.wallpaperImagePath = savedPath;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.settings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('カラーから選ぶ', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppColors.wallpaperPalette.map((c) {
              final active = s.wallpaperType == WallpaperType.color && s.wallpaperColor == c.value;
              return Pressable(
                onTap: () => state.updateSettings((s) {
                  s.wallpaperType = WallpaperType.color;
                  s.wallpaperColor = c.value;
                }),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: c, border: Border.all(width: 3, color: active ? AppColors.ink : AppColors.line)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Text('写真から選ぶ', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loading ? null : _pickPhoto,
            icon: _loading
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.indigo))
                : const Icon(Icons.photo_outlined, size: 16, color: AppColors.indigo),
            label: Text('ライブラリから選択', style: AppTheme.body(13, weight: FontWeight.w700, color: AppColors.indigo)),
            style: OutlinedButton.styleFrom(backgroundColor: AppColors.indigoSoft, side: BorderSide.none, padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16)),
          ),
          if (s.wallpaperType == WallpaperType.image && s.wallpaperImagePath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(s.wallpaperImagePath!), height: 80, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => state.updateSettings((s) {
                s.wallpaperType = WallpaperType.defaultBg;
                s.wallpaperColor = null;
                s.wallpaperImagePath = null;
              }),
              child: Text('既定の背景に戻す', style: AppTheme.body(13, weight: FontWeight.w700, color: AppColors.inkSoft)),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// 文字の大きさ
// =====================================================================

void showFontSizeSheet(BuildContext context) {
  showAppSheet(context, title: '文字の大きさ', bodyBuilder: (ctx) => const _FontSizeBody());
}

class _FontSizeBody extends StatelessWidget {
  const _FontSizeBody();
  static const _options = [0.875, 1.0, 1.125, 1.25];
  static const _labels = {'0.875': '小', '1.0': '標準', '1.125': '大', '1.25': '特大'};

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('アプリ全体の文字サイズを変更します。', style: AppTheme.body(12.5, color: AppColors.inkSoft)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(99)),
            child: Row(
              children: _options.map((v) {
                final active = state.settings.fontScale == v;
                return Expanded(
                  child: Pressable(
                    onTap: () => state.updateSettings((s) => s.fontScale = v),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(color: active ? AppColors.indigo : Colors.transparent, borderRadius: BorderRadius.circular(99)),
                      child: Center(
                        child: Text(_labels[v.toString()] ?? '標準',
                            style: AppTheme.body(12.5, weight: FontWeight.w700, color: active ? Colors.white : AppColors.inkSoft)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Text('プレビュー：数学Ⅱ 三角関数の復習', style: AppTheme.body(14, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('この大きさでアプリ内のテキストが表示されます', style: AppTheme.body(11, color: AppColors.inkSoft)),
            ]),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// UIの配置（ボトムナビの並び替え）
// =====================================================================

void showLayoutSheet(BuildContext context) {
  showAppSheet(context, title: 'UIの配置', bodyBuilder: (ctx) => const _LayoutBody());
}

class _LayoutBody extends StatelessWidget {
  const _LayoutBody();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final order = state.settings.navOrder;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('下のナビゲーションに表示する順番を、矢印で並び替えできます。', style: AppTheme.body(12.5, color: AppColors.inkSoft)),
          const SizedBox(height: 10),
          ...order.asMap().entries.map((entry) {
            final idx = entry.key;
            final key = entry.value;
            final meta = kNavMeta[key]!;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Text('${idx + 1}', style: AppTheme.mono(11, color: AppColors.inkFaint)),
                const SizedBox(width: 10),
                Icon(meta.icon, size: 16, color: AppColors.inkSoft),
                const SizedBox(width: 8),
                Expanded(child: Text(meta.label, style: AppTheme.body(13.5, weight: FontWeight.w700))),
                Pressable(
                  onTap: idx == 0 ? null : () => state.reorderNav(idx, idx - 1),
                  child: Opacity(
                    opacity: idx == 0 ? 0.3 : 1,
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.keyboard_arrow_up, size: 16, color: AppColors.inkSoft),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Pressable(
                  onTap: idx == order.length - 1 ? null : () => state.reorderNav(idx, idx + 1),
                  child: Opacity(
                    opacity: idx == order.length - 1 ? 0.3 : 1,
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.inkSoft),
                    ),
                  ),
                ),
              ]),
            );
          }),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: state.resetNavOrder,
              child: Text('初期設定に戻す', style: AppTheme.body(13, weight: FontWeight.w700, color: AppColors.inkSoft)),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// 忘却曲線の手動設定
// =====================================================================

void showCurveSettingsSheet(BuildContext context) {
  showAppSheet(context, title: '忘却曲線の手動設定', bodyBuilder: (ctx) => const _CurveSettingsBody());
}

class _CurveSettingsBody extends StatelessWidget {
  const _CurveSettingsBody();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('新規タスクは自動で復習をON', style: AppTheme.body(14, weight: FontWeight.w700)),
                Text('新しいタスク作成時の初期設定です', style: AppTheme.body(11.5, color: AppColors.inkSoft)),
              ]),
            ),
            CupertinoSwitch(
                value: state.settings.globalAutoReview,
                activeColor: AppColors.sage,
                onChanged: (v) => state.updateSettings((s) => s.globalAutoReview = v)),
          ]),
          const SizedBox(height: 18),
          Text('既定の復習間隔（日数）', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 8),
          IntervalChipEditor(
              intervals: state.settings.globalIntervals,
              onChanged: (v) => state.updateSettings((s) => s.globalIntervals = v)),
          const SizedBox(height: 18),
          Text('プレビュー', style: AppTheme.body(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
            child: ForgettingCurveChart(intervals: state.settings.globalIntervals),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Googleアカウント連携
// =====================================================================

void showGoogleLinkSheet(BuildContext context) {
  showAppSheet(context, title: 'Googleアカウント連携', bodyBuilder: (ctx) => const _GoogleLinkBody());
}

class _GoogleLinkBody extends StatefulWidget {
  const _GoogleLinkBody();
  @override
  State<_GoogleLinkBody> createState() => _GoogleLinkBodyState();
}

class _GoogleLinkBodyState extends State<_GoogleLinkBody> {
  bool _connecting = false;
  String? _error;

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // ユーザーがサインインをキャンセルした
        setState(() => _connecting = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('サインインに失敗しました');
      if (!mounted) return;
      await context.read<AppState>().connectGoogle(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('連携しました'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
      ));
    } catch (e) {
      setState(() => _error = '連携に失敗しました。Firebaseの設定を確認してください。\n($e)');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _disconnect() async {
    await context.read<AppState>().disconnectGoogle();
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // サインアウト自体に失敗しても、アプリ内の連携状態は解除済みのままで問題ない
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    Widget content;
    if (_connecting) {
      content = Column(mainAxisSize: MainAxisSize.min, children: const [
        SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.indigo)),
        SizedBox(height: 14),
        Text('連携しています…'),
      ]);
    } else if (state.settings.googleConnected) {
      content = Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 30, backgroundColor: AppColors.indigoSoft, child: Text('G', style: AppTheme.display(26, color: AppColors.indigo))),
        const SizedBox(height: 12),
        Text(state.settings.googleEmail, style: AppTheme.body(14.5, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('として連携済みです。ほかの端末でも同じアカウントでログインすると、タスクが同期されます。',
            textAlign: TextAlign.center, style: AppTheme.body(12, color: AppColors.inkSoft)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _disconnect,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coralSoft, foregroundColor: AppColors.coral, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text('連携を解除', style: AppTheme.body(14, weight: FontWeight.w700)),
          ),
        ),
      ]);
    } else {
      content = Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 30, backgroundColor: AppColors.indigoSoft, child: Text('G', style: AppTheme.display(26, color: AppColors.indigo))),
        const SizedBox(height: 14),
        Text(
          'Googleアカウントと連携すると、タスクや科目のデータがクラウドに保存され、同じアカウントでログインした別の端末（iPad・スマホなど）でも同じ内容を見られるようになります。',
          textAlign: TextAlign.center,
          style: AppTheme.body(13, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _connect,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text('Googleでサインインして連携', style: AppTheme.body(14, weight: FontWeight.w700)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: AppTheme.body(11.5, color: AppColors.coral)),
        ],
      ]);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(16)),
        child: content,
      ),
    );
  }
}

// =====================================================================
// 通知
// =====================================================================

void showNotificationSheet(BuildContext context) {
  showAppSheet(context, title: '通知', bodyBuilder: (ctx) => const _NotificationBody());
}

class _NotificationBody extends StatelessWidget {
  const _NotificationBody();

  Future<void> _togglePermission(BuildContext context, AppState state) async {
    if (state.settings.notifGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通知をオフにするには端末の設定から変更してください'), backgroundColor: AppColors.ink));
      return;
    }
    final status = await Permission.notification.request();
    state.updateSettings((s) => s.notifGranted = status.isGranted);
    await _reschedule(state);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(status.isGranted ? '通知を許可しました' : '通知が拒否されました'),
      backgroundColor: status.isGranted ? AppColors.ink : AppColors.coral,
    ));
  }

  Future<void> _reschedule(AppState state) async {
    final enabled = state.settings.notifGranted &&
        (state.settings.notifReminders || state.settings.notifDeadline);
    await NotificationService.scheduleDailyReminder(
      hour: state.settings.reminderHour,
      minute: state.settings.reminderMinute,
      enabled: enabled,
    );
  }

  Future<void> _pickTime(BuildContext context, AppState state) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: state.settings.reminderHour, minute: state.settings.reminderMinute),
    );
    if (picked == null) return;
    state.updateSettings((s) {
      s.reminderHour = picked.hour;
      s.reminderMinute = picked.minute;
    });
    await _reschedule(state);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('通知時刻を${pad2(picked.hour)}:${pad2(picked.minute)}に設定しました'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleRow(context, '通知を許可', '現在の状態：${state.settings.notifGranted ? "許可済み" : "未設定"}',
              state.settings.notifGranted, (_) => _togglePermission(context, state)),
          _timeRow(context, state),
          _toggleRow(context, '復習リマインダー', '復習タスクの期限が近づいたら知らせる',
              state.settings.notifReminders, (v) async {
            state.updateSettings((s) => s.notifReminders = v);
            await _reschedule(state);
          }),
          _toggleRow(context, '期限が近いタスク', '通常タスクの期限前にも知らせる',
              state.settings.notifDeadline, (v) async {
            state.updateSettings((s) => s.notifDeadline = v);
            await _reschedule(state);
          }),
          if (!state.settings.notifGranted) ...[
            const SizedBox(height: 10),
            Text('※ 通知を許可すると、上で設定した時刻に毎日リマインダーが届きます。',
                style: AppTheme.body(11.5, color: AppColors.inkFaint)),
          ],
        ],
      ),
    );
  }

  Widget _timeRow(BuildContext context, AppState state) {
    final timeLabel = '${pad2(state.settings.reminderHour)}:${pad2(state.settings.reminderMinute)}';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('通知時刻', style: AppTheme.body(14, weight: FontWeight.w700)),
            Text('毎日この時刻にまとめて知らせます', style: AppTheme.body(11.5, color: AppColors.inkSoft)),
          ]),
        ),
        Pressable(
          onTap: () => _pickTime(context, state),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
                color: AppColors.surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
            child: Text(timeLabel, style: AppTheme.mono(14, weight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _toggleRow(BuildContext context, String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTheme.body(14, weight: FontWeight.w700)),
            Text(sub, style: AppTheme.body(11.5, color: AppColors.inkSoft)),
          ]),
        ),
        CupertinoSwitch(value: value, activeColor: AppColors.sage, onChanged: onChanged),
      ]),
    );
  }
}
