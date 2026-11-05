import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/db.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _business = TextEditingController();
  final _whatsapp = TextEditingController();
  final _name = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final row =
        await db.from('profiles').select().eq('id', uid).maybeSingle();
    if (row != null) {
      _name.text = (row['display_name'] as String?) ?? '';
      _business.text = (row['business_name'] as String?) ?? '';
      _whatsapp.text = (row['whatsapp_number'] as String?) ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    await db.from('profiles').upsert({
      'id': uid,
      'display_name': _name.text.trim(),
      'business_name': _business.text.trim(),
      'whatsapp_number': _whatsapp.text.trim(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Signed in as ${db.auth.currentUser?.email ?? ''}',
            style: TextStyle(color: Colors.grey.shade400)),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Your name'),
        ),
        TextField(
          controller: _business,
          decoration: const InputDecoration(labelText: 'Business name'),
        ),
        TextField(
          controller: _whatsapp,
          keyboardType: TextInputType.phone,
          decoration:
              const InputDecoration(labelText: 'Your WhatsApp number'),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: _save, child: const Text('Save profile')),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Supabase.instance.client.auth.signOut(),
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
