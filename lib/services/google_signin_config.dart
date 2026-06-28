import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Web版でGoogleサインインを使うには、Firebase本体の設定とは別に
/// 「Web用のOAuthクライアントID」が必要。
///
/// 取得方法：
/// 1. https://console.cloud.google.com を開く
/// 2. 上部のプロジェクト選択で studysync-73a0f を選ぶ
/// 3. 左メニュー「APIとサービス」→「認証情報」
/// 4. 「OAuth 2.0 クライアント ID」の一覧の中の、種類が
///    「ウェブ アプリケーション」になっているものを開く
/// 5. 「クライアント ID」（〜.apps.googleusercontent.com の文字列）を
///    コピーして、下の '' の中に貼る
const String kGoogleWebClientId = '513488495547-1samdo06q1vcte6ge22rdkn3ifgdv5pv.apps.googleusercontent.com'; // ← ここにWeb用クライアントIDを貼る

/// アプリ全体で共通のGoogleSignInインスタンス。
/// Web版のときだけ kGoogleWebClientId を渡す
/// （Android/iOSでは無視されるので、空文字のままでも動作に影響しない）。
final GoogleSignIn googleSignIn = GoogleSignIn(
  clientId: kIsWeb && kGoogleWebClientId.isNotEmpty ? kGoogleWebClientId : null,
);
