import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../services/db.dart';
import 'lead_card.dart' show money;

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final _svc = LeadsService();
  late Future<List<LeadPayment>> _data;

  @override
  void initState() {
    super.initState();
    _data = _svc.fetchPayments();
  }

  void _reload() => setState(() => _data = _svc.fetchPayments());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LeadPayment>>(
      future: _data,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Could not load: ${snap.error}'));
        }
        final all = snap.data!;
        final unpaid = all.where((p) => !p.isPaid).toList();
        final paid = all.where((p) => p.isPaid).toList();
        final outstanding =
            unpaid.fold<double>(0, (sum, p) => sum + p.amount);
        if (all.isEmpty) {
          return const Center(
            child: Text('No payments yet. Add one from a lead page.'),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            children: [
              ListTile(
                title: const Text('Outstanding'),
                trailing: Text(
                  money(unpaid.isEmpty ? 'BDT' : unpaid.first.currency,
                      outstanding),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              for (final p in unpaid)
                ListTile(
                  leading: Icon(Icons.schedule,
                      color: p.isOverdue ? Colors.redAccent : Colors.amber),
                  title: Text(money(p.currency, p.amount)),
                  subtitle: Text(
                      'Due ${DateFormat.yMMMd().format(p.dueDate)}${p.isOverdue ? ' · OVERDUE' : ''}${p.note != null ? ' · ${p.note}' : ''}'),
                  trailing: TextButton(
                    onPressed: () async {
                      await _svc.markPaid(p);
                      _reload();
                    },
                    child: const Text('Mark paid'),
                  ),
                ),
              if (paid.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Received',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                for (final p in paid)
                  ListTile(
                    leading: const Icon(Icons.check, color: Colors.green),
                    title: Text(money(p.currency, p.amount)),
                    subtitle: Text(
                        'Paid ${DateFormat.yMMMd().format(p.paidAt!)}'),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
