/// The follow-up ladder, anchored at the lead's LAST CONTACT time
/// (creation counts as the first anchor when nobody has been contacted
/// yet). Due points: day 1, day 3, day 7 after the anchor, then a
/// rolling weekly nudge until the lead is won or lost.
///
/// v0.2.0 fix: earlier versions anchored the ladder at creation only,
/// so contacting a lead never moved the next due date even though the
/// schema comment said the ladder runs "after the last contact".
/// Every contact now restarts the ladder from that contact.
class Ladder {
  static const points = [1, 3, 7];

  /// The next due time strictly after [now], counting from [anchor].
  static DateTime nextDue(DateTime anchor, DateTime now) {
    for (final d in points) {
      final p = anchor.add(Duration(days: d));
      if (p.isAfter(now)) return p;
    }
    var p = anchor.add(const Duration(days: 7));
    while (!p.isAfter(now)) {
      p = p.add(const Duration(days: 7));
    }
    return p;
  }

  /// All upcoming due times after [now], up to [count] of them.
  /// Used to schedule local notifications ahead of time.
  static List<DateTime> upcoming(DateTime anchor, DateTime now,
      {int count = 4}) {
    final out = <DateTime>[];
    var cursor = now;
    while (out.length < count) {
      final n = nextDue(anchor, cursor);
      out.add(n);
      cursor = n;
    }
    return out;
  }

  /// Human label for the step that falls due at [due].
  static String stageFor(DateTime anchor, DateTime due) {
    final days = due.difference(anchor).inDays;
    if (days <= 1) return 'Day 1';
    if (days <= 3) return 'Day 3';
    if (days <= 7) return 'Day 7';
    return 'Weekly';
  }
}
