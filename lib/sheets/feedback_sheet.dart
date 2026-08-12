import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../app_theme.dart';
import '../changelog.dart';
import '../services/feedback_service.dart';
import '../widgets/sheet_scaffold.dart';

/// ご要望・不具合報告フォーム。Firestoreの `feedback` コレクションに送信する。
void showFeedbackSheet(BuildContext context) {
  showAppSheet(context, title: 'ご要望・不具合報告', bodyBuilder: (ctx) => const _FeedbackBody());
}

class _FeedbackBody extends StatefulWidget {
  const _FeedbackBody();
  @override
  State<_FeedbackBody> createState() => _FeedbackBodyState();
}

class _FeedbackBodyState extends State<_FeedbackBody> {
  final _textCtrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AppState state) async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await FeedbackService.submit(
        text: text,
        email: state.settings.googleConnected ? state.settings.googleEmail : null,
        appVersion: kAppVersion,
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('送信に失敗しました。ネットワークをご確認のうえ、もう一度お試しください。'),
        backgroundColor: AppColors.coral,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (_sent) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        child: Column(children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: AppColors.sage, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          Text('送信しました', style: AppTheme.body(15, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('ご意見ありがとうございます。今後の改善の参考にさせていただきます。',
              textAlign: TextAlign.center, style: AppTheme.body(12.5, color: AppColors.inkSoft)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(backgroundColor: AppColors.surface2, padding: const EdgeInsets.symmetric(vertical: 13)),
              child: Text('閉じる', style: AppTheme.body(13, weight: FontWeight.w700, color: AppColors.inkSoft)),
            ),
          ),
        ]),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('機能のご要望や、不具合の報告をお送りください。開発の参考にします。',
              style: AppTheme.body(12.5, color: AppColors.inkSoft)),
          const SizedBox(height: 14),
          TextField(
            controller: _textCtrl,
            maxLines: 6,
            minLines: 4,
            style: AppTheme.body(13.5),
            decoration: InputDecoration(
              hintText: '例：〇〇の画面で△△だと嬉しいです／□□をタップするとエラーになります',
              hintStyle: AppTheme.body(12, color: AppColors.inkFaint),
              filled: true,
              fillColor: AppColors.surface2,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.line, width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.line, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.indigo, width: 1.5)),
            ),
          ),
          if (state.settings.googleConnected) ...[
            const SizedBox(height: 8),
            Text('連携中のメールアドレス（${state.settings.googleEmail}）が返信先として一緒に送られます',
                style: AppTheme.body(10.5, color: AppColors.inkFaint)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : () => _submit(state),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.surface2,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Text('送信する', style: AppTheme.body(14, weight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}
