import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'state/app_state.dart';
import 'app_theme.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // firebase_options.dart は `flutterfire configure` を実行すると
  // 自動生成されます（README_FLUTTER.md 参照）。まだ実行していない場合は
  // ここでビルドエラーになります。
  //
  // どちらの初期化も、万が一固まってしまった場合に画面が永遠に真っ黒/
  // 起動中のまま、にならないようタイムアウトを付けている。失敗しても
  // アプリ自体は起動させ、Firebase関連の機能だけが使えない状態で続行する。
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[main] Firebase.initializeApp failed or timed out: $e');
  }
  try {
    await NotificationService.init().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('[main] NotificationService.init failed or timed out: $e');
  }
  runApp(const StudySyncApp());
}

class StudySyncApp extends StatelessWidget {
  const StudySyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..load(),
      child: MaterialApp(
        title: 'StudySync',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('ja'),
        supportedLocales: const [Locale('ja'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // 設定の「文字の大きさ」をアプリ全体に反映する（HTML版の --fs-scale と同じ役割）
        builder: (context, child) {
          final scale = context.watch<AppState>().settings.fontScale;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
