import 'package:flutter/material.dart';

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
      final lead = await LeadsService().createLead(
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        source: _source.text.trim().isEmpty ? null : _source.text.trim(),
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
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp number',
                hintText: '+8801XXXXXXXXX',
              ),
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
                'Follow-up reminders are set for day 1, day 3 and day 7.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
