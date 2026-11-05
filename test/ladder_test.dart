import 'package:flutter_test/flutter_test.dart';
import 'package:leadloop/ladder.dart';

void main() {
  final created = DateTime(2026, 11, 1, 10);

  test('day 1 is the first due point', () {
    expect(Ladder.nextDue(created, DateTime(2026, 11, 1, 12)),
        DateTime(2026, 11, 2, 10));
    expect(Ladder.stageFor(created, DateTime(2026, 11, 2, 10)), 'Day 1');
  });

  test('after day 1 passes, day 3 is next', () {
    expect(Ladder.nextDue(created, DateTime(2026, 11, 2, 11)),
        DateTime(2026, 11, 3 + 1, 10));
    expect(Ladder.stageFor(created, DateTime(2026, 11, 4, 10)), 'Day 3');
  });

  test('after day 7 it rolls weekly', () {
    final next = Ladder.nextDue(created, DateTime(2026, 11, 20));
    expect(next, DateTime(2026, 11, 22, 10));
    expect(Ladder.stageFor(created, next), 'Weekly');
  });

  test('upcoming returns future points in order', () {
    final ups = Ladder.upcoming(created, DateTime(2026, 11, 1, 12), count: 3);
    expect(ups.length, 3);
    expect(ups[0].isBefore(ups[1]), isTrue);
    expect(ups[1].isBefore(ups[2]), isTrue);
  });
}
