import 'package:flutter/material.dart';

/// タップ時に少し縮むフィードバックを与える共通ウィジェット。
/// HTMLプロトタイプの `:active { transform: scale(.96) }` に相当し、
/// アイコンボタン・タスクカード・FAB・チップなど、タップできる要素
/// 全体に使うことで「iOSらしい押し心地」を統一しています。
///
/// 注意：Pressable を入れ子にしない（ボタンをボタンの中に置かない）こと。
/// Flutter のジェスチャーは親子で独立して反応するため、入れ子にすると
/// 内側をタップしたときに外側の onTap も一緒に呼ばれてしまいます。
/// アイコン用ボタンなどは、選択用Pressableの「外」に兄弟として置いてください。
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final Duration duration;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.96,
    this.duration = const Duration(milliseconds: 110),
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
