import 'package:flutter/material.dart';

/// Android/iOSではこの実装が使われる（renderButton自体はWeb専用のため、
/// ここでは何も表示しない空のWidgetを返すだけ）。
Widget buildGoogleSignInButton() => const SizedBox.shrink();
