import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/users_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = UsersService();
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _adrCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _profil;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telCtrl.dispose();
    _adrCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _service.getMe();
      _user = r.user;
      _profil = r.profil;
      _nomCtrl.text = r.user['nom']?.toString() ?? '';
      _telCtrl.text = r.user['telephone']?.toString() ?? '';
      _adrCtrl.text = r.user['adresse']?.toString() ?? '';
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    try {
      final updated = await _service.updateMe({
        'nom': _nomCtrl.text.trim(),
        'telephone': _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
        'adresse': _adrCtrl.text.trim().isEmpty ? null : _adrCtrl.text.trim(),
      });
      if (!mounted) return;
      await context.read<AuthProvider>().loadSession();
      setState(() => _user = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final role = _user?['role']?.toString() ?? '';
    final email = _user?['email']?.toString() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Email : $email', style: Theme.of(context).textTheme.bodyLarge),
          Text('Rôle : $role'),
          const SizedBox(height: 16),
          TextField(
            controller: _nomCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _telCtrl,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adrCtrl,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          if (_profil != null) ...[
            const SizedBox(height: 16),
            Text(
              'Profil détaillé',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_profil.toString(), style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
