import 'package:supabase_flutter/supabase_flutter.dart';

import '../ladder.dart';
import '../models.dart';

SupabaseClient get db => Supabase.instance.client;
String get uid => db.auth.currentUser!.id;

class LeadsService {
  Future<List<Lead>> fetchLeads({String? status}) async {
    var q = db.from('leads').select().eq('owner', uid);
    if (status != null) q = q.eq('status', status);
    final rows = await q.order('next_follow_up_at', ascending: true);
    return rows.map((r) => Lead.fromJson(r)).toList();
  }

  /// Leads whose follow-up is due now or overdue, plus anything due today.
  Future<List<Lead>> fetchDue() async {
    final endOfToday = DateTime.now().copyWith(
      hour: 23,
      minute: 59,
      second: 59,
    );
    final rows = await db
        .from('leads')
        .select()
        .eq('owner', uid)
        .not('status', 'in', '(won,lost)')
        .lte('next_follow_up_at', endOfToday.toIso8601String())
        .order('next_follow_up_at', ascending: true);
    return rows.map((r) => Lead.fromJson(r)).toList();
  }

  Future<Lead> createLead({
    required String name,
    String? phone,
    String? source,
    String? notes,
    double? value,
    String currency = 'BDT',
  }) async {
    final now = DateTime.now();
    final row = await db
        .from('leads')
        .insert({
          'owner': uid,
          'name': name,
          'phone': phone,
          'source': source,
          'notes': notes,
          'value': value,
          'currency': currency,
          'next_follow_up_at':
              Ladder.nextDue(now, now).toIso8601String(),
        })
        .select()
        .single();
    return Lead.fromJson(row);
  }

  Future<Lead> setStatus(Lead lead, String status) async {
    final row = await db
        .from('leads')
        .update({'status': status})
        .eq('id', lead.id)
        .select()
        .single();
    await logEvent(lead.id, 'status_change', 'Status set to $status');
    return Lead.fromJson(row);
  }

  /// Record that the owner reached out. v0.2.0: the contact restarts
  /// the follow-up ladder from now, so the next nudge is day 1 after
  /// this contact, then day 3 and day 7. The timeline is stamped too.
  Future<Lead> markContacted(Lead lead, String kind) async {
    final now = DateTime.now();
    final row = await db
        .from('leads')
        .update({
          'last_contacted_at': now.toIso8601String(),
          'next_follow_up_at': Ladder.nextDue(now, now).toIso8601String(),
        })
        .eq('id', lead.id)
        .select()
        .single();
    await logEvent(lead.id, kind, null);
    return Lead.fromJson(row);
  }

  /// Push the next follow-up out by [days] without logging a contact.
  /// Used by the snooze action on the lead page.
  Future<Lead> snooze(Lead lead, int days) async {
    final next = DateTime.now().add(Duration(days: days));
    final row = await db
        .from('leads')
        .update({'next_follow_up_at': next.toIso8601String()})
        .eq('id', lead.id)
        .select()
        .single();
    await logEvent(lead.id, 'note', 'Follow-up snoozed $days day(s)');
    return Lead.fromJson(row);
  }

  /// Edit a lead's details. Only the fields given are changed.
  Future<Lead> updateLead(
    Lead lead, {
    String? name,
    String? phone,
    String? source,
    String? notes,
    double? value,
  }) async {
    final patch = <String, dynamic>{};
    if (name != null) patch['name'] = name;
    if (phone != null) patch['phone'] = phone;
    if (source != null) patch['source'] = source;
    if (notes != null) patch['notes'] = notes;
    if (value != null) patch['value'] = value;
    if (patch.isEmpty) return lead;
    final row = await db
        .from('leads')
        .update(patch)
        .eq('id', lead.id)
        .select()
        .single();
    await logEvent(lead.id, 'note', 'Lead details updated');
    return Lead.fromJson(row);
  }

  Future<void> deleteLead(Lead lead) async {
    await db.from('leads').delete().eq('id', lead.id);
  }

  Future<void> logEvent(String leadId, String kind, String? body) async {
    await db.from('follow_up_events').insert({
      'lead_id': leadId,
      'owner': uid,
      'kind': kind,
      'body': body,
    });
  }

  Future<List<FollowUpEvent>> fetchEvents(String leadId) async {
    final rows = await db
        .from('follow_up_events')
        .select()
        .eq('lead_id', leadId)
        .order('created_at', ascending: false);
    return rows.map((r) => FollowUpEvent.fromJson(r)).toList();
  }

  Future<List<LeadPayment>> fetchPayments({bool unpaidOnly = false}) async {
    var q = db.from('payments').select().eq('owner', uid);
    if (unpaidOnly) q = q.isFilter('paid_at', null);
    final rows = await q.order('due_date', ascending: true);
    return rows.map((r) => LeadPayment.fromJson(r)).toList();
  }

  Future<List<LeadPayment>> fetchPaymentsForLead(String leadId) async {
    final rows = await db
        .from('payments')
        .select()
        .eq('lead_id', leadId)
        .order('due_date', ascending: true);
    return rows.map((r) => LeadPayment.fromJson(r)).toList();
  }

  Future<LeadPayment> addPayment({
    required String leadId,
    required double amount,
    required DateTime dueDate,
    String currency = 'BDT',
    String? note,
  }) async {
    final row = await db
        .from('payments')
        .insert({
          'lead_id': leadId,
          'owner': uid,
          'amount': amount,
          'due_date': dueDate.toIso8601String().substring(0, 10),
          'currency': currency,
          'note': note,
        })
        .select()
        .single();
    await logEvent(leadId, 'payment',
        'Payment of $currency $amount due ${dueDate.toIso8601String().substring(0, 10)}');
    return LeadPayment.fromJson(row);
  }

  Future<void> markPaid(LeadPayment p) async {
    await db
        .from('payments')
        .update({'paid_at': DateTime.now().toIso8601String()})
        .eq('id', p.id);
    await logEvent(p.leadId, 'payment', 'Payment received: ${p.currency} ${p.amount}');
  }
}
