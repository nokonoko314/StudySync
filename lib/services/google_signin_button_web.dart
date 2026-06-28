import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;

/// Web版だけ、Google公式の「Googleでログイン」ボタンをそのまま描画する。
/// 以前使っていたポップアップ方式（GoogleSignIn().signIn()）は、ブラウザの
/// Cross-Origin-Opener-Policy（COOP）と相性が悪く、稀に popup_closed と
/// いう不安定な失敗をすることがあったため、Googleが公式に推奨している
/// この方式に切り替えている。
///
/// このボタンがクリックされてサインインが完了すると、結果は
/// GoogleSignIn.instance（lib/services/google_signin_config.dartで
/// 共有しているインスタンス）の onCurrentUserChanged ストリームに
/// 流れてくる（settings_sheets.dart側でlistenしている）。
Widget buildGoogleSignInButton() => web_only.renderButton();
