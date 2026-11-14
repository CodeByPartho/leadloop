import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../services/contact_actions.dart';
import '../services/db.dart';
import '../services/notifications.dart';
import '../validation.dart';
import 'lead_card.dart' show money;

class LeadDetailPage extends StatefulWidget {
  final Lead lead;
  const LeadDetailPage({super.key, required this.lead});

  @override
  State<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends State<LeadDetailPage> {
  final _svc = LeadsService();
  late Lead _lead;
  late Future<(List<FollowUpEvent>, List<LeadPayment>)> _data;

  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
    _data = _load();
  }

  Future<(List<FollowUpEvent>, List<LeadPayment>)> _load() async {
    final events = await _svc.fetchEvents(_lead.id);
    final payments = await _svc.fetchPaymentsForLead(_lead.id);
    return (events, payments);
  }

  void _reload() => setState(() => _data = _load());

  Future<void> _editLead() async {
    final name = TextEditingController(text: _lead.name);
    final phone = TextEditingController(text: _lead.phone ?? '');
    final source = TextEditingController(text: _lead.source ?? '');
    final value = TextEditingController(
        text: _lead.value == null ? '' : _lead.value!.toStringAsFixed(0));
    final notes = TextEditingController(text: _lead.notes ?? '');
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit lead'),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                    controller: name,
                    decoration:
                        const InputDecoration(labelText: 'Name *'),
                    validator: validateName),
                TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'WhatsApp number'),
                    validator: validatePhone),
                TextFormField(
                    controller: source,
                    decoration:
                        const InputDecoration(labelText: 'Source')),
                TextFormField(
                    controller: value,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Deal value'),
                    validator: validateDealValue),
                TextFormField(
                    controller: notes,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: 'Notes')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final updated = await _svc.updateLead(
        _lead,
        name: name.text.trim(),
        phone: phone.text.trim(),
        source: source.text.trim(),
        notes: notes.text.trim(),
        value: value.text.trim().isEmpty
            ? null
            : double.tryParse(value.text.trim()),
      );
      setState(() => _lead = updated);
      _reload();
    }
  }

  Future<void> _snooze(int days) async {
    final updated = await _svc.snooze(_lead, days);
    setState(() => _lead = updated);
    await NotificationService.scheduleForLead(updated);
    _reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Follow-up snoozed $days day(s), next due ${DateFormat.yMMMd().format(updated.nextFollowUpAt)}')),
      );
    }
  }

  Future<void> _addNote() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add note'),
        content: TextField(controller: ctrl, maxLines: 3, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await _svc.logEvent(_lead.id, 'note', ctrl.text.trim());
      _reload();
    }
  }

  Future<void> _addPayment() async {
    final amount = TextEditingController();
    final note = TextEditingController();
    DateTime due = DateTime.now().add(const Duration(days: 7));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add payment due'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: 'Amount (${_lead.currency})'),
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Due: '),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime.now().subtract(
                            const Duration(days: 365)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                        initialDate: due,
                      );
                      if (picked != null) setLocal(() => due = picked);
                    },
                    child: Text(DateFormat.yMMMd().format(due)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    final amt = double.tryParse(amount.text.trim());
    if (ok == true && amt != null) {
      await _svc.addPayment(
        leadId: _lead.id,
        amount: amt,
        dueDate: due,
        currency: _lead.currency,
        note: note.text.trim().isEmpty ? null : note.text.trim(),
      );
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lead.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (s) async {
              if (s == 'delete') {
                await NotificationService.cancelForLead(_lead);
                await _svc.deleteLead(_lead);
                if (context.mounted) Navigator.pop(context);
              } else if (s == 'edit') {
                await _editLead();
              } else if (s == 'snooze1') {
                await _snooze(1);
              } else if (s == 'snooze3') {
                await _snooze(3);
              } else {
                final updated = await _svc.setStatus(_lead, s);
                setState(() => _lead = updated);
                await NotificationService.scheduleForLead(updated);
                _reload();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit lead')),
              PopupMenuItem(
                  value: 'contacted', child: Text('Mark contacted')),
              PopupMenuItem(
                  value: 'interested', child: Text('Mark interested')),
              PopupMenuItem(value: 'won', child: Text('Mark won')),
              PopupMenuItem(value: 'lost', child: Text('Mark lost')),
              PopupMenuItem(
                  value: 'snooze1', child: Text('Snooze 1 day')),
              PopupMenuItem(
                  value: 'snooze3', child: Text('Snooze 3 days')),
              PopupMenuItem(value: 'delete', child: Text('Delete lead')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<(List<FollowUpEvent>, List<LeadPayment>)>(
        future: _data,
        builder: (context, snap) {
          final events = snap.data?.$1 ?? [];
          final payments = snap.data?.$2 ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Status: ${_lead.status}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (_lead.phone != null) Text('Phone: ${_lead.phone}'),
              if (_lead.source != null) Text('Source: ${_lead.source}'),
              if (_lead.value != null)
                Text('Value: ${money(_lead.currency, _lead.value)}'),
              if (_lead.notes != null) Text('Notes: ${_lead.notes}'),
              Text(
                  'Added ${DateFormat.yMMMd().format(_lead.createdAt)} · next follow-up ${DateFormat.yMMMd().format(_lead.nextFollowUpAt)} (${_lead.stageLabel})'),
              if (_lead.lastContactedAt != null)
                Text(
                    'Last contact ${DateFormat.yMMMd().format(_lead.lastContactedAt!)} · ladder restarts from each contact'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final ok = await ContactActions.openWhatsApp(_lead);
                      if (ok) {
                        final updated =
                            await _svc.markContacted(_lead, 'whatsapp');
                        setState(() => _lead = updated);
                        await NotificationService.scheduleForLead(updated);
                        _reload();
                      }
                    },
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => ContactActions.call(_lead),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _addNote,
                    icon: const Icon(Icons.note_add, size: 18),
                    label: const Text('Note'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _addPayment,
                    icon: const Icon(Icons.payments, size: 18),
                    label: const Text('Payment'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Payments',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (payments.isEmpty) const Text('No payments tracked.'),
              for (final p in payments)
                ListTile(
                  dense: true,
                  title: Text(money(p.currency, p.amount)),
                  subtitle: Text(
                      '${p.isPaid ? 'Paid' : 'Due'} ${DateFormat.yMMMd().format(p.dueDate)}${p.note != null ? ' · ${p.note}' : ''}'),
                  trailing: p.isPaid
                      ? const Icon(Icons.check, color: Colors.green)
                      : TextButton(
                          onPressed: () async {
                            await _svc.markPaid(p);
                            _reload();
                          },
                          child: const Text('Mark paid'),
                        ),
                ),
              const SizedBox(height: 20),
              const Text('Timeline',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (snap.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
              for (final e in events)
                ListTile(
                  dense: true,
                  leading: Icon(
                    switch (e.kind) {
                      'whatsapp' => Icons.chat,
                      'call' => Icons.call,
                      'payment' => Icons.payments,
                      'status_change' => Icons.flag,
                      _ => Icons.note,
                    },
                    size: 18,
                  ),
                  title: Text(e.body ?? e.kind),
                  subtitle:
                      Text(DateFormat.yMMMd().add_jm().format(e.createdAt)),
                ),
            ],
          );
        },
      ),
    );
  }
}
