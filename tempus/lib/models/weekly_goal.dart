import 'dart:convert';

/// Possible statuses for a weekly goal.
enum GoalStatus {
  pending,
  complete,
  incomplete,
  inProgress;

  String get label {
    switch (this) {
      case GoalStatus.pending:
        return 'Pending';
      case GoalStatus.complete:
        return 'Completed';
      case GoalStatus.incomplete:
        return "Didn't Complete";
      case GoalStatus.inProgress:
        return 'In Progress';
    }
  }
}

class WeeklyGoal {
  final String id;
  final String goalText;
  final DateTime weekStart; // Always a Monday (start of the goal week).
  final DateTime createdAt;
  final GoalStatus status;
  final DateTime? statusChangedAt;

  WeeklyGoal({
    required this.id,
    required this.goalText,
    required this.weekStart,
    required this.createdAt,
    this.status = GoalStatus.pending,
    this.statusChangedAt,
  });

  /// Whether this goal has been finalised (complete / incomplete / inProgress).
  bool get isResolved => status != GoalStatus.pending;

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalText': goalText,
        'weekStart': weekStart.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'statusChangedAt': statusChangedAt?.toIso8601String(),
      };

  factory WeeklyGoal.fromJson(Map<String, dynamic> json) => WeeklyGoal(
        id: json['id'] as String,
        goalText: json['goalText'] as String,
        weekStart: DateTime.parse(json['weekStart'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: GoalStatus.values.byName(json['status'] as String),
        statusChangedAt: json['statusChangedAt'] != null
            ? DateTime.parse(json['statusChangedAt'] as String)
            : null,
      );

  String encode() => jsonEncode(toJson());

  factory WeeklyGoal.decode(String source) =>
      WeeklyGoal.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Creates a copy of this goal with optional field overrides.
  /// To explicitly set [statusChangedAt] to null, pass a function returning null:
  /// `goal.copyWith(statusChangedAt: () => null)`
  WeeklyGoal copyWith({
    String? id,
    String? goalText,
    DateTime? weekStart,
    DateTime? createdAt,
    GoalStatus? status,
    DateTime? Function()? statusChangedAt,
  }) {
    return WeeklyGoal(
      id: id ?? this.id,
      goalText: goalText ?? this.goalText,
      weekStart: weekStart ?? this.weekStart,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      statusChangedAt:
          statusChangedAt != null ? statusChangedAt() : this.statusChangedAt,
    );
  }
}
