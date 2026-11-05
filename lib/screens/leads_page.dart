import 'package:flutter/material.dart';

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
  late Future<List<Lead>> _data;

  static const _filters = <String?, String>{
    null: 'All',
    'new': 'New',
    'contacted': 'Contacted',
    'interested': 'Interested',
    'won': 'Won',
    'lost': 'Lost',
  };

  @override
  void initState() {
    super.initState();
    _data = _svc.fetchLeads(status: _status);
  }

  void _reload() =>
      setState(() => _data = _svc.fetchLeads(status: _status));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search leads',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
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
                final leads = snap.data!
                    .where((l) => l.name.toLowerCase().contains(_query))
                    .toList();
                if (leads.isEmpty) {
                  return const Center(child: Text('No leads here yet.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.builder(
                    itemCount: leads.length,
                    itemBuilder: (_, i) => LeadCard(
                      lead: leads[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LeadDetailPage(lead: leads[i]),
                          ),
                        );
                        _reload();
                      },
                      onChanged: _reload,
                    ),
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
