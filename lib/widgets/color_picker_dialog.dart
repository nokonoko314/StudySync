import 'package:flutter/material.dart';
import '../app_theme.dart';

/// RGBスライダー＋HEX入力のシンプルなカラーピッカー。
/// 外部パッケージは使わず、Flutter標準のColorだけで作っている。
/// 教科のカラー・壁紙のカラー、両方の「カスタムカラーを追加」から
/// 共通で呼ばれる。
Future<Color?> showColorPickerDialog(BuildContext context, Color initial) {
  int r = initial.red;
  int g = initial.green;
  int b = initial.blue;
  final hexCtrl = TextEditingController(text: _toHex(initial));

  return showDialog<Color>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final color = Color.fromARGB(255, r, g, b);

          void syncHex() => hexCtrl.text = _toHex(color);

          Widget channelSlider(String label, int value, Color trackColor, ValueChanged<int> onChanged) {
            return Row(children: [
              SizedBox(width: 50, child: Text(label, style: AppTheme.body(12, color: AppColors.inkSoft))),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(ctx).copyWith(
                    activeTrackColor: trackColor,
                    thumbColor: trackColor,
                    overlayColor: trackColor.withOpacity(.2),
                    inactiveTrackColor: AppColors.line,
                  ),
                  child: Slider(
                    value: value.toDouble(),
                    min: 0,
                    max: 255,
                    onChanged: (v) => setStateDialog(() {
                      onChanged(v.round());
                      syncHex();
                    }),
                  ),
                ),
              ),
              SizedBox(
                width: 34,
                child: Text('$value', textAlign: TextAlign.right, style: AppTheme.mono(12.5, weight: FontWeight.w700)),
              ),
            ]);
          }

          return AlertDialog(
            title: const Text('カスタムカラー'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  ),
                  const SizedBox(height: 16),
                  channelSlider('レッド', r, const Color(0xFFE0463F), (v) => r = v),
                  channelSlider('グリーン', g, const Color(0xFF3FA85B), (v) => g = v),
                  channelSlider('ブルー', b, const Color(0xFF3F7FE0), (v) => b = v),
                  const SizedBox(height: 10),
                  TextField(
                    controller: hexCtrl,
                    decoration: const InputDecoration(labelText: 'HEXコードで指定（任意）', hintText: '#423E99'),
                    onSubmitted: (text) {
                      final cleaned = text.trim().replaceFirst('#', '');
                      if (cleaned.length == 6) {
                        final value = int.tryParse(cleaned, radix: 16);
                        if (value != null) {
                          setStateDialog(() {
                            r = (value >> 16) & 0xFF;
                            g = (value >> 8) & 0xFF;
                            b = value & 0xFF;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
              TextButton(onPressed: () => Navigator.pop(ctx, color), child: const Text('この色にする')),
            ],
          );
        },
      );
    },
  );
}

String _toHex(Color c) =>
    '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
