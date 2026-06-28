import 'package:flutter/material.dart';
import 'google_signin_button_stub.dart'
    if (dart.library.html) 'google_signin_button_web.dart' as impl;

/// Web版ではGoogle公式の描画ボタン、Android/iOSでは空のWidgetを返す。
/// （Android/iOSは今まで通り、ボタンを自前で用意してsignIn()を呼ぶ方式のまま）
Widget buildGoogleSignInButton() => impl.buildGoogleSignInButton();
