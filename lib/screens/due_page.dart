import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../services/db.dart';
import '../services/notifications.dart';
import 'lead_card.dart';
import 'lead_detail_page.dart';

class DuePage extends StatefulWidget {
  const DuePage({super.key});

  @override
  State<DuePage> createState() => _DuePageState();
}

class _DuePageState extends State<DuePage> {
  final _svc = LeadsService();
  late Future<(List<Lead>, List<LeadPayment>)> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<(List<Lead>, List<LeadPayment>)> _load() async {
    final leads = await _svc.fetchDue();
    final payments = (await _svc.fetchPayments(unpaidOnly: true))
        .where((p) => !p.dueDate.isAfter(DateTime.now()))
        .toList();
    for (final l in leads) {
      await NotificationService.scheduleForLead(l);
    }
    return (leads, payments);
  }

  void _reload() => setState(() => _data = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(List<Lead>, List<LeadPayment>)>(
      future: _data,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Could not load: ${snap.error}'));
        }
        final (leads, payments) = snap.data!;
        if (leads.isEmpty && payments.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nothing due today. New follow-ups will land here on day 1, 3 and 7.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            children: [
              if (payments.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Payments due',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                for (final p in payments)
                  ListTile(
                    leading: Icon(Icons.payments,
                        color: p.isOverdue ? Colors.redAccent : Colors.amber),
                    title: Text(money(p.currency, p.amount)),
                    subtitle: Text(
                        'Due ${DateFormat.yMMMd().format(p.dueDate)}${p.note != null ? ' · ${p.note}' : ''}'),
                    trailing: TextButton(
                      onPressed: () async {
                        await _svc.markPaid(p);
                        _reload();
                      },
                      child: const Text('Mark paid'),
                    ),
                  ),
              ],
              if (leads.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Follow-ups due',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                for (final l in leads)
                  LeadCard(
                    lead: l,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LeadDetailPage(lead: l),
                        ),
                      );
                      _reload();
                    },
                    onChanged: _reload,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
