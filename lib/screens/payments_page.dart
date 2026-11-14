import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../export_csv.dart';
import '../models.dart';
import '../payments_summary.dart';
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

  Future<void> _export(List<LeadPayment> payments) async {
    await Clipboard.setData(
        ClipboardData(text: paymentsToCsv(payments)));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${payments.length} payment(s) copied as CSV. Paste it into a spreadsheet.'),
        ),
      );
    }
  }

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
        final summary = paymentSummary(all, DateTime.now());
        if (all.isEmpty) {
          return const Center(
            child: Text('No payments yet. Add one from a lead page.'),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            children: [
              for (final e in summary.outstandingByCurrency.entries)
                ListTile(
                  title: const Text('Outstanding'),
                  trailing: Text(
                    money(e.key, e.value),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              if (summary.overdueByCurrency.isNotEmpty)
                for (final e in summary.overdueByCurrency.entries)
                  ListTile(
                    title: const Text('Overdue'),
                    trailing: Text(
                      money(e.key, e.value),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
              if (summary.paidThisMonthByCurrency.isNotEmpty)
                for (final e in summary.paidThisMonthByCurrency.entries)
                  ListTile(
                    title: const Text('Received this month'),
                    trailing: Text(
                      money(e.key, e.value),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
              if (summary.dueThisMonthByCurrency.isNotEmpty)
                for (final e in summary.dueThisMonthByCurrency.entries)
                  ListTile(
                    title: const Text('Due this month'),
                    trailing: Text(money(e.key, e.value)),
                  ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _export(all),
                  icon: const Icon(Icons.file_download, size: 18),
                  label: const Text('Export CSV'),
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
