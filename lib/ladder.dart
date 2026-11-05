/// The follow-up ladder, anchored at the lead's creation time.
/// Due points: day 1, day 3, day 7, then a rolling weekly nudge
/// until the lead is won or lost.
class Ladder {
  static const points = [1, 3, 7];

  /// The next due time strictly after [now].
  static DateTime nextDue(DateTime createdAt, DateTime now) {
    for (final d in points) {
      final p = createdAt.add(Duration(days: d));
      if (p.isAfter(now)) return p;
    }
    var p = createdAt.add(const Duration(days: 7));
    while (!p.isAfter(now)) {
      p = p.add(const Duration(days: 7));
    }
    return p;
  }

  /// All upcoming due times after [now], up to [count] of them.
  /// Used to schedule local notifications ahead of time.
  static List<DateTime> upcoming(DateTime createdAt, DateTime now,
      {int count = 4}) {
    final out = <DateTime>[];
    var cursor = now;
    while (out.length < count) {
      final n = nextDue(createdAt, cursor);
      out.add(n);
      cursor = n;
    }
    return out;
  }

  /// Human label for the step that falls due at [due].
  static String stageFor(DateTime createdAt, DateTime due) {
    final days = due.difference(createdAt).inDays;
    if (days <= 1) return 'Day 1';
    if (days <= 3) return 'Day 3';
    if (days <= 7) return 'Day 7';
    return 'Weekly';
  }
}
