import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../services/contact_actions.dart';
import '../services/db.dart';

String money(String currency, double? amount) {
  if (amount == null) return '';
  final f = NumberFormat.decimalPattern();
  return '$currency ${f.format(amount)}';
}

class LeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;
  final VoidCallback onChanged;

  const LeadCard({
    super.key,
    required this.lead,
    required this.onTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final svc = LeadsService();
    final dueColor = lead.isOverdue
        ? Colors.redAccent
        : lead.isDue
            ? Colors.amber
            : Colors.grey;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lead.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!lead.isClosed)
                    Chip(
                      label: Text(lead.stageLabel),
                      backgroundColor: dueColor.withValues(alpha: 0.15),
                      labelStyle: TextStyle(color: dueColor, fontSize: 11),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (lead.isClosed)
                    Chip(
                      label: Text(lead.status.toUpperCase()),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (lead.source != null || lead.value != null)
                Text(
                  [
                    if (lead.source != null) lead.source!,
                    if (lead.value != null) money(lead.currency, lead.value),
                  ].join('  ·  '),
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              if (!lead.isClosed)
                Text(
                  lead.isDue
                      ? 'Due ${DateFormat.MMMd().format(lead.nextFollowUpAt)}'
                      : 'Next follow-up ${DateFormat.MMMd().format(lead.nextFollowUpAt)}',
                  style: TextStyle(color: dueColor, fontSize: 12),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final ok = await ContactActions.openWhatsApp(lead);
                      if (ok) {
                        await svc.markContacted(lead, 'whatsapp');
                        onChanged();
                      }
                    },
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Call',
                    onPressed: () => ContactActions.call(lead),
                    icon: const Icon(Icons.call),
                  ),
                  IconButton(
                    tooltip: 'Mark contacted',
                    onPressed: () async {
                      await svc.markContacted(lead, 'call');
                      onChanged();
                    },
                    icon: const Icon(Icons.check_circle_outline),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (s) async {
                      await svc.setStatus(lead, s);
                      onChanged();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'interested', child: Text('Interested')),
                      PopupMenuItem(value: 'won', child: Text('Won')),
                      PopupMenuItem(value: 'lost', child: Text('Lost')),
                      PopupMenuItem(value: 'new', child: Text('Reopen as new')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
