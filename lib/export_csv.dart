import 'models.dart';

/// CSV export for leads and payments. Plain text output so the user
/// can paste it into a spreadsheet or save it anywhere; no extra
/// dependency and no server involved. Pure functions, unit tested.

String _cell(Object? value) {
  final text = (value ?? '').toString();
  if (text.contains(',') ||
      text.contains('"') ||
      text.contains('\n')) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

String _date(DateTime? value) =>
    value == null ? '' : value.toIso8601String().substring(0, 10);

String leadsToCsv(List<Lead> leads) {
  final buf = StringBuffer();
  buf.writeln(
      'name,phone,source,status,value,currency,created,last_contacted,next_follow_up');
  for (final l in leads) {
    buf.writeln([
      _cell(l.name),
      _cell(l.phone),
      _cell(l.source),
      _cell(l.status),
      _cell(l.value),
      _cell(l.currency),
      _cell(_date(l.createdAt)),
      _cell(_date(l.lastContactedAt)),
      _cell(_date(l.nextFollowUpAt)),
    ].join(','));
  }
  return buf.toString();
}

String paymentsToCsv(List<LeadPayment> payments) {
  final buf = StringBuffer();
  buf.writeln('amount,currency,due_date,paid_at,note');
  for (final p in payments) {
    buf.writeln([
      _cell(p.amount),
      _cell(p.currency),
      _cell(_date(p.dueDate)),
      _cell(_date(p.paidAt)),
      _cell(p.note),
    ].join(','));
  }
  return buf.toString();
}
