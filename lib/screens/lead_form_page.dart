import 'package:flutter/material.dart';

import '../duplicates.dart';
import '../validation.dart';
import '../services/db.dart';
import '../services/notifications.dart';

class LeadFormPage extends StatefulWidget {
  const LeadFormPage({super.key});

  @override
  State<LeadFormPage> createState() => _LeadFormPageState();
}

class _LeadFormPageState extends State<LeadFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _source = TextEditingController();
  final _value = TextEditingController();
  final _notes = TextEditingController();
  String _currency = 'BDT';
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _source, _value, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      final phone =
          _phone.text.trim().isEmpty ? null : _phone.text.trim();
      final source =
          _source.text.trim().isEmpty ? null : _source.text.trim();
      // Warn before adding a lead that already exists by phone or by
      // matching name and source. The user can still save it.
      final existing = await LeadsService().fetchLeads();
      final dupe = findDuplicate(existing,
          name: name, phone: phone, source: source);
      if (dupe != null && mounted) {
        final keep = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Possible duplicate'),
            content: Text(
                'A lead already exists for ${dupe.name}'
                '${dupe.phone != null ? ' (${dupe.phone})' : ''}'
                ', status ${dupe.status}. Save a second copy anyway?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save anyway'),
              ),
            ],
          ),
        );
        if (keep != true) {
          if (mounted) setState(() => _saving = false);
          return;
        }
      }
      final lead = await LeadsService().createLead(
        name: name,
        phone: phone,
        source: source,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        value: _value.text.trim().isEmpty
            ? null
            : double.tryParse(_value.text.trim()),
        currency: _currency,
      );
      await NotificationService.scheduleForLead(lead);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add lead')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: validateName,
            ),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp number',
                hintText: '+8801XXXXXXXXX',
              ),
              validator: validatePhone,
            ),
            TextFormField(
              controller: _source,
              decoration: const InputDecoration(
                labelText: 'Source',
                hintText: 'Facebook, referral, walk-in...',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _value,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Deal value'),
                    validator: validateDealValue,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _currency,
                  items: const [
                    DropdownMenuItem(value: 'BDT', child: Text('BDT')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                  ],
                  onChanged: (v) => setState(() => _currency = v ?? 'BDT'),
                ),
              ],
            ),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save lead'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Follow-up reminders are set for day 1, day 3 and day 7 after your last contact.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
