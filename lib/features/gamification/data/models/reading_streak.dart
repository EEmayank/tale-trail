import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kids_stories/core/utils/extensions.dart';

/// Immutable value object tracking a child's daily reading streak.
///
/// A streak increments when the child reads on consecutive calendar days.
/// Reading multiple times on the same day counts only once.
class ReadingStreak {
  const ReadingStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.streakDates,
    this.lastReadDate,
  });

  /// Number of consecutive days read up to and including [lastReadDate].
  final int currentStreak;

  /// All-time longest streak this child has achieved.
  final int longestStreak;

  /// The calendar date of the most recent read, or `null` if never read.
  final DateTime? lastReadDate;

  /// Sorted list of dates (at most 30) on which the child read something.
  ///
  /// Only the calendar date portion is meaningful; time components are ignored
  /// when comparing.
  final List<DateTime> streakDates;

  // ---------------------------------------------------------------------------
  // Derived getters
  // ---------------------------------------------------------------------------

  /// `true` when [lastReadDate] falls on today's calendar date.
  bool get isActiveToday => lastReadDate?.isToday ?? false;

  /// Kid-friendly motivational message based on [currentStreak].
  String get motivationalMessage {
    if (currentStreak == 0) return 'Start your reading journey today!';
    if (currentStreak <= 2) return 'Great start! Come back tomorrow! 🌟';
    if (currentStreak <= 6) return "You're on a roll! Keep it up! 🔥";
    if (currentStreak <= 13) return 'Incredible! A full week! 🎉';
    return 'Legendary reader! 🏆';
  }

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  /// Reconstructs a [ReadingStreak] from a Firestore document map.
  factory ReadingStreak.fromFirestore(Map<String, dynamic> data) {
    final rawDates = data['streakDates'] as List<dynamic>? ?? [];
    final dates = rawDates
        .map((e) {
          if (e is Timestamp) return e.toDate();
          if (e is String) return DateTime.tryParse(e);
          return null;
        })
        .whereType<DateTime>()
        .toList()
      ..sort();

    final lastReadTs = data['lastReadDate'];
    final DateTime? lastRead = lastReadTs is Timestamp
        ? lastReadTs.toDate()
        : lastReadTs is String
            ? DateTime.tryParse(lastReadTs)
            : null;

    return ReadingStreak(
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (data['longestStreak'] as num?)?.toInt() ?? 0,
      lastReadDate: lastRead,
      streakDates: dates,
    );
  }

  /// Converts this object to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastReadDate':
          lastReadDate != null ? Timestamp.fromDate(lastReadDate!) : null,
      'streakDates': streakDates.map(Timestamp.fromDate).toList(),
    };
  }

  // ---------------------------------------------------------------------------
  // Domain mutation — recordRead()
  // ---------------------------------------------------------------------------

  /// Returns a new [ReadingStreak] after recording a read for today.
  ///
  /// Rules:
  /// - If already read today: return `this` unchanged.
  /// - If last read was yesterday: increment [currentStreak].
  /// - Otherwise (first read or gap): reset [currentStreak] to 1.
  /// - Append today to [streakDates] (keeping at most 30 entries).
  /// - Update [longestStreak] if the new streak exceeds the previous record.
  ReadingStreak recordRead() {
    final today = _dateOnly(DateTime.now());

    // Guard: already recorded today.
    if (lastReadDate != null && _dateOnly(lastReadDate!).isAtSameMomentAs(today)) {
      return this;
    }

    // Determine new streak count.
    int newStreak;
    if (lastReadDate != null && _dateOnly(lastReadDate!).isYesterday) {
      newStreak = currentStreak + 1;
    } else {
      newStreak = 1;
    }

    final newLongest =
        newStreak > longestStreak ? newStreak : longestStreak;

    // Build updated date list — keep last 30, deduplicate by calendar day.
    final updatedDates = List<DateTime>.from(streakDates)
      ..removeWhere((d) => _dateOnly(d).isAtSameMomentAs(today))
      ..add(today)
      ..sort();

    if (updatedDates.length > 30) {
      updatedDates.removeRange(0, updatedDates.length - 30);
    }

    return ReadingStreak(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastReadDate: today,
      streakDates: updatedDates,
    );
  }

  // ---------------------------------------------------------------------------
  // CopyWith
  // ---------------------------------------------------------------------------

  ReadingStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastReadDate,
    List<DateTime>? streakDates,
    bool clearLastReadDate = false,
  }) {
    return ReadingStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastReadDate:
          clearLastReadDate ? null : lastReadDate ?? this.lastReadDate,
      streakDates: streakDates ?? this.streakDates,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Strips the time component, returning midnight UTC for a given [DateTime].
  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  // ---------------------------------------------------------------------------
  // Default empty state
  // ---------------------------------------------------------------------------

  /// An empty streak with no history.
  static const ReadingStreak empty = ReadingStreak(
    currentStreak: 0,
    longestStreak: 0,
    streakDates: [],
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingStreak &&
          runtimeType == other.runtimeType &&
          currentStreak == other.currentStreak &&
          longestStreak == other.longestStreak &&
          lastReadDate == other.lastReadDate;

  @override
  int get hashCode =>
      Object.hash(currentStreak, longestStreak, lastReadDate);

  @override
  String toString() =>
      'ReadingStreak(current: $currentStreak, longest: $longestStreak, '
      'lastRead: $lastReadDate)';
}
