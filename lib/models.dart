class Lead {
  final String id;
  final String owner;
  final String name;
  final String? phone;
  final String? source;
  final String? notes;
  final String status; // new | contacted | interested | won | lost
  final double? value;
  final String currency;
  final DateTime createdAt;
  final DateTime? lastContactedAt;
  final DateTime nextFollowUpAt;

  const Lead({
    required this.id,
    required this.owner,
    required this.name,
    this.phone,
    this.source,
    this.notes,
    required this.status,
    this.value,
    required this.currency,
    required this.createdAt,
    this.lastContactedAt,
    required this.nextFollowUpAt,
  });

  bool get isClosed => status == 'won' || status == 'lost';

  /// Which ladder step falls due at [nextFollowUpAt]:
  /// Day 1, Day 3, Day 7, then a weekly rolling nudge.
  String get stageLabel {
    final days = nextFollowUpAt.difference(createdAt).inDays;
    if (days <= 1) return 'Day 1 follow-up';
    if (days <= 3) return 'Day 3 follow-up';
    if (days <= 7) return 'Day 7 follow-up';
    return 'Weekly nudge';
  }

  bool get isDue =>
      !isClosed && !nextFollowUpAt.isAfter(DateTime.now());

  bool get isOverdue =>
      !isClosed &&
      nextFollowUpAt.isBefore(
        DateTime.now().subtract(const Duration(days: 1)),
      );

  factory Lead.fromJson(Map<String, dynamic> j) => Lead(
        id: j['id'] as String,
        owner: j['owner'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String?,
        source: j['source'] as String?,
        notes: j['notes'] as String?,
        status: j['status'] as String,
        value: (j['value'] as num?)?.toDouble(),
        currency: (j['currency'] as String?) ?? 'BDT',
        createdAt: DateTime.parse(j['created_at'] as String),
        lastContactedAt: j['last_contacted_at'] == null
            ? null
            : DateTime.parse(j['last_contacted_at'] as String),
        nextFollowUpAt: DateTime.parse(j['next_follow_up_at'] as String),
      );
}

class LeadPayment {
  final String id;
  final String leadId;
  final String owner;
  final double amount;
  final String currency;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? note;

  const LeadPayment({
    required this.id,
    required this.leadId,
    required this.owner,
    required this.amount,
    required this.currency,
    required this.dueDate,
    this.paidAt,
    this.note,
  });

  bool get isPaid => paidAt != null;
  bool get isOverdue =>
      !isPaid && dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  factory LeadPayment.fromJson(Map<String, dynamic> j) => LeadPayment(
        id: j['id'] as String,
        leadId: j['lead_id'] as String,
        owner: j['owner'] as String,
        amount: (j['amount'] as num).toDouble(),
        currency: (j['currency'] as String?) ?? 'BDT',
        dueDate: DateTime.parse(j['due_date'] as String),
        paidAt:
            j['paid_at'] == null ? null : DateTime.parse(j['paid_at'] as String),
        note: j['note'] as String?,
      );
}

class FollowUpEvent {
  final String id;
  final String leadId;
  final String kind; // whatsapp | call | note | status_change | payment
  final String? body;
  final DateTime createdAt;

  const FollowUpEvent({
    required this.id,
    required this.leadId,
    required this.kind,
    this.body,
    required this.createdAt,
  });

  factory FollowUpEvent.fromJson(Map<String, dynamic> j) => FollowUpEvent(
        id: j['id'] as String,
        leadId: j['lead_id'] as String,
        kind: j['kind'] as String,
        body: j['body'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
