import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../export_csv.dart';
import '../lead_filters.dart';
import '../models.dart';
import '../services/db.dart';
import 'lead_card.dart';
import 'lead_detail_page.dart';
import 'lead_form_page.dart';

class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> {
  final _svc = LeadsService();
  String? _status;
  String _query = '';
  LeadSort _sort = LeadSort.nextDue;
  late Future<List<Lead>> _data;

  static const _filters = <String?, String>{
    null: 'All',
    'new': 'New',
    'contacted': 'Contacted',
    'interested': 'Interested',
    'won': 'Won',
    'lost': 'Lost',
  };

  static const _sortLabels = {
    LeadSort.nextDue: 'Next due',
    LeadSort.newest: 'Newest',
    LeadSort.valueHigh: 'Highest value',
  };

  @override
  void initState() {
    super.initState();
    _data = _svc.fetchLeads(status: _status);
  }

  void _reload() =>
      setState(() => _data = _svc.fetchLeads(status: _status));

  Future<void> _export(List<Lead> leads) async {
    final csv = leadsToCsv(leads);
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${leads.length} lead(s) copied as CSV. Paste it into a spreadsheet.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search name, phone or source',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final e in _filters.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _status == e.key,
                      onSelected: (_) {
                        _status = e.key;
                        _reload();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Lead>>(
              future: _data,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Could not load: ${snap.error}'));
                }
                final all = snap.data!;
                final summary = pipelineSummary(all);
                final leads = sortLeads(filterLeads(all, _query), _sort);
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(
                              label: Text(
                                  '${summary.byStatus['new'] ?? 0} new'),
                              visualDensity: VisualDensity.compact,
                            ),
                            Chip(
                              label: Text(
                                  '${summary.byStatus['interested'] ?? 0} interested'),
                              visualDensity: VisualDensity.compact,
                            ),
                            Chip(
                              label: Text(
                                  '${summary.byStatus['won'] ?? 0} won'),
                              visualDensity: VisualDensity.compact,
                            ),
                            if (summary.winRate != null)
                              Chip(
                                label: Text(
                                    'Win rate ${(summary.winRate! * 100).round()}%'),
                                visualDensity: VisualDensity.compact,
                              ),
                            for (final e
                                in summary.openValueByCurrency.entries)
                              Chip(
                                label: Text(
                                    'Open ${money(e.key, e.value)}'),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                        child: Row(
                          children: [
                            const Text('Sort: '),
                            DropdownButton<LeadSort>(
                              value: _sort,
                              items: [
                                for (final e in _sortLabels.entries)
                                  DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _sort = v ?? _sort),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: leads.isEmpty
                                  ? null
                                  : () => _export(leads),
                              icon: const Icon(Icons.file_download, size: 18),
                              label: const Text('Export CSV'),
                            ),
                          ],
                        ),
                      ),
                      if (leads.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                              child: Text('No leads here yet.')),
                        ),
                      for (final lead in leads)
                        LeadCard(
                          lead: lead,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LeadDetailPage(lead: lead),
                              ),
                            );
                            _reload();
                          },
                          onChanged: _reload,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const LeadFormPage()),
          );
          if (created == true) _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add lead'),
      ),
    );
  }
}
