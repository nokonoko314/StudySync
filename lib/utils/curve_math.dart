import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 忘却曲線プレビューの1点（横軸=完了からの日数、縦軸=推定の記憶定着率0-100）。
class CurveMarker {
  final double day;
  final double value;
  CurveMarker(this.day, this.value);
}

class CurveData {
  final List<Offset> points; // (day, value) のリスト
  final List<CurveMarker> markers; // 復習日のマーカー
  final double totalDays;
  CurveData(
      {required this.points, required this.markers, required this.totalDays});
}

/// 復習間隔（日数のリスト）から、忘却曲線（記憶定着率の推移）を計算する。
/// 各復習のタイミングで定着率が跳ね上がり、減衰の速度も少しずつ緩やかになる
/// （＝スペースド・リピティションの効果）という、エビングハウスの忘却曲線の
/// 考え方を簡略化してモデル化したもの。
CurveData? buildForgettingCurve(List<int> intervals) {
  if (intervals.isEmpty) return null;
  final ivs = [...intervals]..sort();
  final boundaries = [0, ...ivs];
  final tail = math.max(4, (ivs.last * 0.4).round());
  final totalDays = (ivs.last + tail).toDouble();

  final peaks = <double>[100];
  final rates = <double>[0.5];
  for (var i = 1; i <= ivs.length; i++) {
    peaks.add(math.min(99, peaks[i - 1] + (100 - peaks[i - 1]) * 0.45));
    rates.add(rates[i - 1] * 0.68);
  }

  final points = <Offset>[];
  for (var seg = 0; seg < boundaries.length; seg++) {
    final startDay = boundaries[seg].toDouble();
    final endDay = seg < boundaries.length - 1
        ? boundaries[seg + 1].toDouble()
        : totalDays;
    final peak = peaks[seg];
    final rate = rates[seg];
    const steps = 14;
    for (var s = 0; s <= steps; s++) {
      final day = startDay + (endDay - startDay) * (s / steps);
      final t = day - startDay;
      final val = 18 + (peak - 18) * math.exp(-rate * t);
      points.add(Offset(day, val));
    }
  }

  final markers = <CurveMarker>[];
  for (var i = 0; i < ivs.length; i++) {
    markers.add(CurveMarker(ivs[i].toDouble(), peaks[i + 1]));
  }

  return CurveData(points: points, markers: markers, totalDays: totalDays);
}
