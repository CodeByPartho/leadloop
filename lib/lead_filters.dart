import 'models.dart';

/// Search, sort and pipeline summary for the leads list.
/// All pure functions, unit tested.

enum LeadSort { nextDue, newest, valueHigh }

/// Match on name, phone (digits, so "+880..." matches "880...") or
/// source. Empty query matches everything.
List<Lead> filterLeads(List<Lead> leads, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return List.of(leads);
  final digits = q.replaceAll(RegExp(r'[^0-9]'), '');
  return leads.where((l) {
    if (l.name.toLowerCase().contains(q)) return true;
    if ((l.source ?? '').toLowerCase().contains(q)) return true;
    if (digits.isNotEmpty &&
        (l.phone ?? '').replaceAll(RegExp(r'[^0-9]'), '').contains(digits)) {
      return true;
    }
    return false;
  }).toList();
}

List<Lead> sortLeads(List<Lead> leads, LeadSort sort) {
  final out = List<Lead>.of(leads);
  switch (sort) {
    case LeadSort.nextDue:
      out.sort((a, b) => a.nextFollowUpAt.compareTo(b.nextFollowUpAt));
    case LeadSort.newest:
      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case LeadSort.valueHigh:
      out.sort((a, b) => (b.value ?? 0).compareTo(a.value ?? 0));
  }
  return out;
}

/// Pipeline snapshot: counts per status, open pipeline value grouped
/// by currency (currencies are never added together), and win rate
/// over decided leads only.
class PipelineSummary {
  final Map<String, int> byStatus;
  final Map<String, double> openValueByCurrency;
  final double? winRate;

  const PipelineSummary({
    required this.byStatus,
    required this.openValueByCurrency,
    required this.winRate,
  });
}

PipelineSummary pipelineSummary(List<Lead> leads) {
  final byStatus = <String, int>{};
  final openValue = <String, double>{};
  var won = 0;
  var lost = 0;
  for (final l in leads) {
    byStatus[l.status] = (byStatus[l.status] ?? 0) + 1;
    if (l.status == 'won') won++;
    if (l.status == 'lost') lost++;
    if (!l.isClosed && l.value != null) {
      openValue[l.currency] = (openValue[l.currency] ?? 0) + l.value!;
    }
  }
  final decided = won + lost;
  return PipelineSummary(
    byStatus: byStatus,
    openValueByCurrency: openValue,
    winRate: decided == 0 ? null : won / decided,
  );
}
