/// 1回分の学習記録（タイマーで計測した1セッション）。
class StudySession {
  final DateTime date;
  final int durationSeconds;

  StudySession({required this.date, required this.durationSeconds});

  Map<String, dynamic> toJson() => {
        'date': date.millisecondsSinceEpoch,
        'duration': durationSeconds,
      };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
        durationSeconds: json['duration'] as int,
      );
}

/// タスク（やること）のモデル。
/// 忘却曲線にもとづく「復習タスク」は isReview=true / parentId に
/// 元タスクのidを持つ形で、通常タスクと同じ Task として表現します。
class Task {
  String id;
  String title;
  String projectId;
  String? group;
  DateTime due;
  String notes;
  bool completed;
  DateTime? completedAt;
  bool isReview;
  String? parentId;
  bool autoReview;
  List<int> intervals; // 完了から何日後に復習するか（日数のリスト）
  int timeSpent; // 合計学習時間（秒）
  List<StudySession> sessions;
  bool reviewsGenerated; // 復習タスクをすでに生成したか（二重生成防止）

  Task({
    required this.id,
    required this.title,
    required this.projectId,
    this.group,
    required this.due,
    this.notes = '',
    this.completed = false,
    this.completedAt,
    this.isReview = false,
    this.parentId,
    this.autoReview = true,
    List<int>? intervals,
    this.timeSpent = 0,
    List<StudySession>? sessions,
    this.reviewsGenerated = false,
  })  : intervals = intervals ?? [1, 3, 7, 14, 30],
        sessions = sessions ?? [];

  /// 「未完了」「完了」「期限切れ」のいずれか。
  String get status {
    if (completed) return '完了';
    if (due.isBefore(DateTime.now())) return '期限切れ';
    return '未完了';
  }

  bool get isOverdue => !completed && due.isBefore(DateTime.now());

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'projectId': projectId,
        'group': group,
        'due': due.millisecondsSinceEpoch,
        'notes': notes,
        'completed': completed,
        'completedAt': completedAt?.millisecondsSinceEpoch,
        'isReview': isReview,
        'parentId': parentId,
        'autoReview': autoReview,
        'intervals': intervals,
        'timeSpent': timeSpent,
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'reviewsGenerated': reviewsGenerated,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        projectId: json['projectId'] as String,
        group: json['group'] as String?,
        due: DateTime.fromMillisecondsSinceEpoch(json['due'] as int),
        notes: json['notes'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int)
            : null,
        isReview: json['isReview'] as bool? ?? false,
        parentId: json['parentId'] as String?,
        autoReview: json['autoReview'] as bool? ?? true,
        intervals: (json['intervals'] as List?)
                ?.map((e) => e as int)
                .toList() ??
            [1, 3, 7, 14, 30],
        timeSpent: json['timeSpent'] as int? ?? 0,
        sessions: (json['sessions'] as List?)
                ?.map((e) => StudySession.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        reviewsGenerated: json['reviewsGenerated'] as bool? ?? false,
      );
}
