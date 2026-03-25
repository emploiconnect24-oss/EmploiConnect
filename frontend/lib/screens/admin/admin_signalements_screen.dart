import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/status_chip.dart';

class AdminSignalementsScreen extends StatefulWidget {
  const AdminSignalementsScreen({super.key});

  @override
  State<AdminSignalementsScreen> createState() => _AdminSignalementsScreenState();
}

class _AdminSignalementsScreenState extends State<AdminSignalementsScreen> {
  final _admin = AdminService();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _admin.getSignalements(limit: 100);
      setState(() {
        _list = r.signalements;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _traiter(String id, String statut) async {
    try {
      await _admin.traiterSignalement(id, statut);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signalement : $statut')),
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

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        child: _list.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('Aucun signalement')),
                ],
              )
            : ListView.separated(
                itemCount: _list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final s = _list[i];
                  final id = s['id']?.toString() ?? '';
                  final type = s['type_objet']?.toString() ?? '';
                  final raison = s['raison']?.toString() ?? '';
                  final statut = s['statut']?.toString() ?? '';
                  return Card(
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(type)),
                          StatusChip(value: statut),
                        ],
                      ),
                      subtitle: Text(raison, maxLines: 2, overflow: TextOverflow.ellipsis),
                      children: [
                        if (statut == 'en_attente')
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _traiter(id, 'rejete'),
                                  child: const Text('Rejeter'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () => _traiter(id, 'traite'),
                                  child: const Text('Traité'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
