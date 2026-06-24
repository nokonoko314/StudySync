import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 写真ピッカーで選んだ画像を、再起動後も読み込めるように
/// アプリのドキュメントディレクトリにコピーして保存する。
class WallpaperFileService {
  static Future<String> saveWallpaperImage(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
    final dest = File('${dir.path}/wallpaper.$ext');
    final bytes = await File(sourcePath).readAsBytes();
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  }
}
