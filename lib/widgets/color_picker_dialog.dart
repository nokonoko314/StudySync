import 'package:flutter/material.dart';
import '../app_theme.dart';

/// 9×9のグリッドから選ぶシンプルなカラーピッカー。
/// 1列目はグレースケール、2〜9列目は8色の色相をそれぞれ
/// 明るい〜暗いの9段階で並べている。HEXコードでの直接指定も可能。
/// 教科のカラー・壁紙のカラー、両方の「カスタムカラーを追加」から
/// 共通で呼ばれる。
Future<Color?> showColorPickerDialog(BuildContext context, Color initial) {
  Color selected = initial;
  final hexCtrl = TextEditingController(text: _toHex(initial));

  // 9列 × 9行のグリッドをあらかじめ計算しておく。
  final grid = _buildGrid();

  return showDialog<Color>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setStateDialog) {
          void applyHex(String text) {
            final cleaned = text.trim().replaceFirst('#', '');
            if (cleaned.length == 6) {
              final value = int.tryParse(cleaned, radix: 16);
              if (value != null) {
                setStateDialog(() => selected = Color(0xFF000000 | value));
              }
            }
          }

          return AlertDialog(
            title: const Text('カスタムカラー'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(color: selected, borderRadius: BorderRadius.circular(12)),
                  ),
                  const SizedBox(height: 14),
                  for (final row in grid)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          for (final c in row)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                                child: GestureDetector(
                                  onTap: () => setStateDialog(() {
                                    selected = c;
                                    hexCtrl.text = _toHex(c);
                                  }),
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: c,
                                        borderRadius: BorderRadius.circular(5),
                                        border: _isSameColor(selected, c)
                                            ? Border.all(color: AppColors.ink, width: 2)
                                            : Border.all(color: Colors.black.withOpacity(.06), width: 1),
                                      ),
                                      child: _isSameColor(selected, c)
                                          ? Icon(Icons.check, size: 13, color: _contrastColor(c))
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hexCtrl,
                    decoration: const InputDecoration(labelText: 'HEXコードで指定（任意）', hintText: '#423E99'),
                    onSubmitted: applyHex,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
              TextButton(onPressed: () => Navigator.pop(ctx, selected), child: const Text('この色にする')),
            ],
          );
        },
      );
    },
  );
}

bool _isSameColor(Color a, Color b) => a.value == b.value;

Color _contrastColor(Color c) => (c.computeLuminance() > 0.5) ? Colors.black : Colors.white;

/// 9列×9行のグリッドを作る。1列目はグレースケール、
/// 2〜9列目は8色の色相をそれぞれ明るい→暗いの9段階で並べる。
List<List<Color>> _buildGrid() {
  const rows = 9;
  const hueCols = 8;
  final grid = List.generate(rows, (_) => <Color>[]);

  for (var row = 0; row < rows; row++) {
    // 1列目：白(row=0)〜黒(row=rows-1)のグレースケール
    final gray = 1.0 - row / (rows - 1);
    grid[row].add(Color.fromARGB(255, (gray * 255).round(), (gray * 255).round(), (gray * 255).round()));
  }

  for (var col = 0; col < hueCols; col++) {
    final hue = col * (360 / hueCols);
    for (var row = 0; row < rows; row++) {
      // 上ほど明るく・下ほど暗く。彩度は中間行で最大になるよう緩やかに調整。
      final lightness = 0.92 - row * (0.80 / (rows - 1));
      final saturation = row == 0 ? 0.35 : 0.65;
      grid[row].add(HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor());
    }
  }
  return grid;
}

String _toHex(Color c) =>
    '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
