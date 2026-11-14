import 'package:flutter_test/flutter_test.dart';
import 'package:leadloop/duplicates.dart';
import 'package:leadloop/export_csv.dart';
import 'package:leadloop/ladder.dart';
import 'package:leadloop/lead_filters.dart';
import 'package:leadloop/models.dart';
import 'package:leadloop/payments_summary.dart';
import 'package:leadloop/validation.dart';

Lead _lead({
  String id = '1',
  String name = 'Rahim',
  String? phone = '+8801712345678',
  String? source = 'Facebook',
  String status = 'new',
  double? value = 5000,
  String currency = 'BDT',
  DateTime? createdAt,
  DateTime? lastContactedAt,
  DateTime? nextFollowUpAt,
}) =>
    Lead(
      id: id,
      owner: 'owner',
      name: name,
      phone: phone,
      source: source,
      notes: null,
      status: status,
      value: value,
      currency: currency,
      createdAt: createdAt ?? DateTime(2026, 11, 1, 10),
      lastContactedAt: lastContactedAt,
      nextFollowUpAt: nextFollowUpAt ?? DateTime(2026, 11, 2, 10),
    );

LeadPayment _payment({
  String id = 'p1',
  double amount = 1000,
  String currency = 'BDT',
  DateTime? dueDate,
  DateTime? paidAt,
}) =>
    LeadPayment(
      id: id,
      leadId: '1',
      owner: 'owner',
      amount: amount,
      currency: currency,
      dueDate: dueDate ?? DateTime(2026, 11, 10),
      paidAt: paidAt,
      note: null,
    );

void main() {
  group('ladder anchored at last contact', () {
    test('contact on day 2 restarts the ladder at day 3', () {
      final created = DateTime(2026, 11, 1, 10);
      final contact = DateTime(2026, 11, 3, 11);
      expect(Ladder.nextDue(contact, contact), DateTime(2026, 11, 4, 11));
      expect(Ladder.stageFor(contact, DateTime(2026, 11, 4, 11)), 'Day 1');
      // Old creation-anchored answer would have been day 3 from creation.
      expect(Ladder.nextDue(created, contact), DateTime(2026, 11, 4, 10));
    });

    test('weekly roll still works from a late contact', () {
      final contact = DateTime(2026, 10, 1, 10);
      final next = Ladder.nextDue(contact, DateTime(2026, 11, 20));
      expect(next, DateTime(2026, 11, 26, 10));
      expect(Ladder.stageFor(contact, next), 'Weekly');
    });
  });

  group('lead stage label follows the anchor', () {
    test('uses last contact, not creation', () {
      final lead = _lead(
        createdAt: DateTime(2026, 11, 1, 10),
        lastContactedAt: DateTime(2026, 11, 10, 10),
        nextFollowUpAt: DateTime(2026, 11, 11, 10),
      );
      expect(lead.ladderAnchor, DateTime(2026, 11, 10, 10));
      expect(lead.stageLabel, 'Day 1 follow-up');
    });

    test('falls back to creation when never contacted', () {
      final lead = _lead();
      expect(lead.ladderAnchor, lead.createdAt);
      expect(lead.stageLabel, 'Day 1 follow-up');
    });
  });

  group('validation', () {
    test('phone accepts formatted numbers, rejects short and long', () {
      expect(validatePhone(null), isNull);
      expect(validatePhone(''), isNull);
      expect(validatePhone('+880 1712-345678'), isNull);
      expect(validatePhone('123'), isNotNull);
      expect(validatePhone('1' * 16), isNotNull);
    });

    test('deal value must be a positive number', () {
      expect(validateDealValue(null), isNull);
      expect(validateDealValue('5000'), isNull);
      expect(validateDealValue('abc'), isNotNull);
      expect(validateDealValue('0'), isNotNull);
      expect(validateDealValue('-5'), isNotNull);
    });

    test('name required and capped', () {
      expect(validateName(''), isNotNull);
      expect(validateName('Rahim'), isNull);
      expect(validateName('x' * 81), isNotNull);
    });
  });

  group('duplicate detection', () {
    final existing = [_lead(), _lead(id: '2', name: 'Karim', phone: null, source: 'Walk-in')];

    test('same phone with different formatting matches', () {
      final dupe = findDuplicate(existing,
          name: 'Someone Else', phone: '8801712345678');
      expect(dupe?.id, '1');
    });

    test('same name and source matches', () {
      final dupe = findDuplicate(existing,
          name: 'karim', phone: null, source: ' walk-in ');
      expect(dupe?.id, '2');
    });

    test('same name alone does not match', () {
      final dupe = findDuplicate(existing,
          name: 'Karim', phone: null, source: 'Facebook');
      expect(dupe, isNull);
    });

    test('no match returns null', () {
      expect(
          findDuplicate(existing,
              name: 'New Person', phone: '+8801911111111'),
          isNull);
    });
  });

  group('search, sort and pipeline summary', () {
    final leads = [
      _lead(id: '1', name: 'Rahim', phone: '+8801712345678', source: 'Facebook', value: 5000, nextFollowUpAt: DateTime(2026, 11, 3, 10)),
      _lead(id: '2', name: 'Karim', phone: '+8801911111111', source: 'Referral', status: 'won', value: 2000, nextFollowUpAt: DateTime(2026, 11, 2, 10)),
      _lead(id: '3', name: 'Sakib', phone: null, source: 'Walk-in', status: 'lost', value: 9000, currency: 'USD', nextFollowUpAt: DateTime(2026, 11, 5, 10)),
    ];

    test('search matches name, source and phone digits', () {
      expect(filterLeads(leads, 'rah').length, 1);
      expect(filterLeads(leads, 'referral').length, 1);
      expect(filterLeads(leads, '8801911111111').length, 1);
      expect(filterLeads(leads, '1712345678').length, 1);
      expect(filterLeads(leads, '').length, 3);
    });

    test('sort by next due, newest and value', () {
      expect(sortLeads(leads, LeadSort.nextDue).first.id, '2');
      expect(sortLeads(leads, LeadSort.valueHigh).first.id, '3');
      expect(sortLeads(leads, LeadSort.newest).length, 3);
    });

    test('summary counts, open value per currency and win rate', () {
      final s = pipelineSummary(leads);
      expect(s.byStatus['new'], 1);
      expect(s.byStatus['won'], 1);
      expect(s.byStatus['lost'], 1);
      // Open value excludes won and lost leads.
      expect(s.openValueByCurrency, {'BDT': 5000});
      expect(s.winRate, 0.5);
    });

    test('win rate is null with no decided leads', () {
      expect(pipelineSummary([_lead()]).winRate, isNull);
    });
  });

  group('payment summary', () {
    test('totals stay per currency and month buckets work', () {
      final now = DateTime(2026, 11, 14);
      final payments = [
        _payment(amount: 1000, dueDate: DateTime(2026, 11, 5)),
        _payment(id: 'p2', amount: 50, currency: 'USD', dueDate: DateTime(2026, 11, 20)),
        _payment(id: 'p3', amount: 2000, dueDate: DateTime(2026, 11, 10), paidAt: DateTime(2026, 11, 12)),
        _payment(id: 'p4', amount: 300, dueDate: DateTime(2026, 12, 1)),
      ];
      final s = paymentSummary(payments, now);
      expect(s.outstandingByCurrency, {'BDT': 1300, 'USD': 50});
      expect(s.overdueByCurrency, {'BDT': 1000});
      expect(s.paidThisMonthByCurrency, {'BDT': 2000});
      expect(s.dueThisMonthByCurrency, {'BDT': 1000, 'USD': 50});
    });
  });

  group('CSV export', () {
    test('header and rows, with quoting for commas and quotes', () {
      final csv = leadsToCsv([
        _lead(name: 'Rahim, Jr.', source: 'Face"book'),
      ]);
      final lines = csv.trim().split('\n');
      expect(lines.first,
          'name,phone,source,status,value,currency,created,last_contacted,next_follow_up');
      expect(lines[1], contains('"Rahim, Jr."'));
      expect(lines[1], contains('"Face""book"'));
    });

    test('payments csv has one row per payment', () {
      final csv = paymentsToCsv([_payment(), _payment(id: 'p2')]);
      expect(csv.trim().split('\n').length, 3);
    });
  });
}
