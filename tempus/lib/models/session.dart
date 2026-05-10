import 'dart:convert';

class Session {
  final int sessionNumber;
  final String sessionName;
  final String? comment;
  final DateTime startTime;
  final DateTime endTime;
  final Duration totalDuration;
  final DateTime date;

  Session({
    required this.sessionNumber,
    required this.sessionName,
    this.comment,
    required this.startTime,
    required this.endTime,
    required this.totalDuration,
    required this.date,
  });

  /// Returns the formatted total productive time as HH:MM:SS.
  String get formattedDuration {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    final seconds = totalDuration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Returns the productivity level (0-4) based on session duration.
  /// 0 = less than 30 minutes (colorless)
  /// 1 = 30 min - 2 hours (dark green)
  /// 2 = 2 - 5 hours (less bright)
  /// 3 = 5 - 8 hours (slightly bright)
  /// 4 = 8+ hours (bright green)
  int get productivityLevel {
    final minutes = totalDuration.inMinutes;
    if (minutes < 30) return 0;
    if (minutes < 120) return 1;
    if (minutes < 300) return 2;
    if (minutes < 480) return 3;
    return 4;
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionNumber': sessionNumber,
      'sessionName': sessionName,
      'comment': comment,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalDurationSeconds': totalDuration.inSeconds,
      'date': date.toIso8601String(),
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      sessionNumber: json['sessionNumber'] as int,
      sessionName: json['sessionName'] as String,
      comment: json['comment'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      totalDuration: Duration(seconds: json['totalDurationSeconds'] as int),
      date: DateTime.parse(json['date'] as String),
    );
  }

  String encode() => jsonEncode(toJson());

  factory Session.decode(String source) =>
      Session.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Creates a copy with optional field overrides.
  Session copyWith({int? sessionNumber}) {
    return Session(
      sessionNumber: sessionNumber ?? this.sessionNumber,
      sessionName: sessionName,
      comment: comment,
      startTime: startTime,
      endTime: endTime,
      totalDuration: totalDuration,
      date: date,
    );
  }
}
