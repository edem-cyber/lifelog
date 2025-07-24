class JournalEntryModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final int mood; // 1-5 rating
  final DateTime date; // Date of the entry (without time for grouping)
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntryModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.mood,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) {
    return JournalEntryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      mood: json['mood'] as int,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'mood': mood,
      'date': date.toIso8601String().split('T')[0], // Date only (YYYY-MM-DD)
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  JournalEntryModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    int? mood,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      mood: mood ?? this.mood,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get mood emoji
  String get moodEmoji {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '😔';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  // Helper method to get mood description
  String get moodDescription {
    switch (mood) {
      case 1:
        return 'Very Sad';
      case 2:
        return 'Sad';
      case 3:
        return 'Neutral';
      case 4:
        return 'Happy';
      case 5:
        return 'Very Happy';
      default:
        return 'Neutral';
    }
  }

  // Static helper methods for analytics
  static String getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '😔';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  static String getMoodDescription(int mood) {
    switch (mood) {
      case 1:
        return 'Very Sad';
      case 2:
        return 'Sad';
      case 3:
        return 'Neutral';
      case 4:
        return 'Happy';
      case 5:
        return 'Very Happy';
      default:
        return 'Neutral';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JournalEntryModel &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.body == body &&
        other.mood == mood &&
        other.date == date &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      title,
      body,
      mood,
      date,
      createdAt,
      updatedAt,
    );
  }
}
