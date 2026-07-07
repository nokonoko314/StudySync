/// 「プロジェクト」（旧グループ）のチャンネル情報。
///
/// 名前だけでなく「期間」（開始日・終了日、任意）を持たせることで、
/// 「前期中間テスト」のような期間限定のプロジェクトを、終わったあとも
/// 一覧から選んで振り返れるようにする。
class GroupProject {
  String name;
  DateTime? startDate;
  DateTime? endDate;

  GroupProject({required this.name, this.startDate, this.endDate});

  /// 期間が設定されていて、かつ終了日が過去（＝終わったプロジェクト）かどうか。
  bool get isPast => endDate != null && endDate!.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

  bool get hasPeriod => startDate != null || endDate != null;

  Map<String, dynamic> toJson() => {
        'name': name,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };

  factory GroupProject.fromJson(Map<String, dynamic> json) => GroupProject(
        name: json['name'] as String,
        startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'] as String) : null,
        endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'] as String) : null,
      );
}
