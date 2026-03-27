import 'package:flutter/material.dart';

import '../../widgets/responsive_container.dart';
import 'widgets/matching_score_badge.dart';

class RecruteurTalentsScreen extends StatefulWidget {
  const RecruteurTalentsScreen({super.key});

  @override
  State<RecruteurTalentsScreen> createState() => _RecruteurTalentsScreenState();
}

class _RecruteurTalentsScreenState extends State<RecruteurTalentsScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _allTalents = _seedTalents();
  final List<Map<String, dynamic>> _displayed = [];
  final Set<String> _saved = {};

  bool _loadingMore = false;
  int _take = 8;
  String _exp = 'tous';
  String _city = 'toutes';
  String _edu = 'tous';
  String _dispo = 'tous';
  String _lang = 'toutes';
  String _sort = 'score_desc';

  static const _expOptions = ['tous', 'sans', '1-2', '3-5', '5+'];
  static const _cityOptions = ['toutes', 'Conakry', 'Kindia', 'Boké', 'Kankan', 'Labé'];
  static const _eduOptions = ['tous', 'Licence', 'Master', 'Doctorat', 'Bac'];
  static const _dispoOptions = ['tous', 'immédiate', '1 mois', '2+ mois'];
  static const _langOptions = ['toutes', 'Français', 'Anglais', 'Pular', 'Malinké', 'Soussou'];

  @override
  void initState() {
    super.initState();
    _rebuild();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels < _scrollCtrl.position.maxScrollExtent - 300) return;
    if (_loadingMore) return;
    final total = _filteredSorted.length;
    if (_take >= total) return;
    setState(() => _loadingMore = true);
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _take = (_take + 8).clamp(0, total);
        _rebuild();
        _loadingMore = false;
      });
    });
  }

  List<Map<String, dynamic>> get _filteredSorted {
    final q = _searchCtrl.text.trim().toLowerCase();
    final list = _allTalents.where((t) {
      final title = (t['title'] as String).toLowerCase();
      final name = (t['name'] as String).toLowerCase();
      final city = (t['city'] as String);
      final exp = (t['experience'] as String);
      final edu = (t['education'] as String);
      final dispo = (t['availability'] as String);
      final langs = (t['languages'] as List<String>);
      final skills = (t['skills'] as List<String>);

      final matchQuery = q.isEmpty ||
          name.contains(q) ||
          title.contains(q) ||
          skills.any((s) => s.toLowerCase().contains(q));
      if (!matchQuery) return false;
      if (_city != 'toutes' && city != _city) return false;
      if (_exp != 'tous' && exp != _exp) return false;
      if (_edu != 'tous' && edu != _edu) return false;
      if (_dispo != 'tous' && dispo != _dispo) return false;
      if (_lang != 'toutes' && !langs.contains(_lang)) return false;
      return true;
    }).toList();

    list.sort((a, b) {
      if (_sort == 'score_desc') {
        return (b['score'] as int).compareTo(a['score'] as int);
      }
      return (a['name'] as String).compareTo(b['name'] as String);
    });
    return list;
  }

  void _rebuild() {
    final src = _filteredSorted;
    final end = _take.clamp(0, src.length);
    _displayed
      ..clear()
      ..addAll(src.take(end));
  }

  void _onFilterChanged() {
    setState(() {
      _take = 8;
      _rebuild();
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _filteredSorted.length;
    return ResponsiveContainer(
      child: LayoutBuilder(
        builder: (context, c) {
          final isMobile = c.maxWidth < 980;
          return Column(
            children: [
              _header(total),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMobile) SizedBox(width: 280, child: _filtersPanel()),
                  if (!isMobile) const SizedBox(width: 12),
                  Expanded(child: _resultsPanel(isMobile: isMobile)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(int total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recherche de talents par IA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('Trouvez le profil idéal parmi les candidats inscrits.'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => _onFilterChanged(),
                    decoration: const InputDecoration(
                      hintText: 'Titre du poste ou compétences...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 210,
                  child: DropdownButtonFormField<String>(
                    initialValue: _sort,
                    decoration: const InputDecoration(labelText: 'Tri', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'score_desc', child: Text('Score IA (desc)')),
                      DropdownMenuItem(value: 'name_asc', child: Text('Nom (A-Z)')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _sort = v;
                        _rebuild();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Text('$total résultats'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filtersPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtres', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _dropdown('Expérience', _exp, _expOptions, (v) => setState(() {
                  _exp = v;
                  _onFilterChanged();
                })),
            const SizedBox(height: 10),
            _dropdown('Ville', _city, _cityOptions, (v) => setState(() {
                  _city = v;
                  _onFilterChanged();
                })),
            const SizedBox(height: 10),
            _dropdown('Études', _edu, _eduOptions, (v) => setState(() {
                  _edu = v;
                  _onFilterChanged();
                })),
            const SizedBox(height: 10),
            _dropdown('Disponibilité', _dispo, _dispoOptions, (v) => setState(() {
                  _dispo = v;
                  _onFilterChanged();
                })),
            const SizedBox(height: 10),
            _dropdown('Langue', _lang, _langOptions, (v) => setState(() {
                  _lang = v;
                  _onFilterChanged();
                })),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => setState(() {
                _exp = 'tous';
                _city = 'toutes';
                _edu = 'tous';
                _dispo = 'tous';
                _lang = 'toutes';
                _onFilterChanged();
              }),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Réinitialiser'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: (v) {
        if (v == null) return;
        onChanged(v);
      },
    );
  }

  Widget _resultsPanel({required bool isMobile}) {
    final results = _displayed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) _mobileFiltersBar(),
            if (isMobile) const SizedBox(height: 8),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Aucun talent trouvé avec ces critères.')),
              )
            else
              SizedBox(
                height: 560,
                child: ListView.builder(
                  controller: _scrollCtrl,
                  itemCount: results.length + (_loadingMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= results.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final t = results[i];
                    return _talentCard(t);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mobileFiltersBar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _miniFilter('Exp', _exp, _expOptions, (v) => setState(() {
              _exp = v;
              _onFilterChanged();
            })),
        _miniFilter('Ville', _city, _cityOptions, (v) => setState(() {
              _city = v;
              _onFilterChanged();
            })),
        _miniFilter('Études', _edu, _eduOptions, (v) => setState(() {
              _edu = v;
              _onFilterChanged();
            })),
      ],
    );
  }

  Widget _miniFilter(String title, String value, List<String> options, ValueChanged<String> onChanged) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (_) => options.map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
      child: Chip(label: Text('$title: $value')),
    );
  }

  Widget _talentCard(Map<String, dynamic> t) {
    final name = t['name'] as String;
    final title = t['title'] as String;
    final city = t['city'] as String;
    final exp = t['experience'] as String;
    final dispo = t['availability'] as String;
    final score = t['score'] as int;
    final skills = (t['skills'] as List<String>);
    final id = t['id'] as String;
    final isSaved = _saved.contains(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFDBEAFE),
                child: Text(name.isEmpty ? '?' : name[0], style: const TextStyle(color: Color(0xFF1D4ED8))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(title),
                  ],
                ),
              ),
              MatchingScoreBadge(score: score),
            ],
          ),
          const SizedBox(height: 8),
          Text('$city · $exp ans · Disponible: $dispo'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...skills.take(4).map((s) => Chip(label: Text(s), visualDensity: VisualDensity.compact)),
              if (skills.length > 4) Chip(label: Text('+${skills.length - 4}')),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showTalentDialog(t),
                icon: const Icon(Icons.person_outline),
                label: const Text('Voir profil'),
              ),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Messagerie à connecter pour $name (section 14)')),
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Contacter'),
              ),
              FilledButton.icon(
                onPressed: () => setState(() {
                  if (isSaved) {
                    _saved.remove(id);
                  } else {
                    _saved.add(id);
                  }
                }),
                icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border),
                label: Text(isSaved ? 'Sauvegardé' : 'Sauvegarder'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTalentDialog(Map<String, dynamic> t) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t['name'] as String),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t['title'] as String),
              const SizedBox(height: 8),
              MatchingScoreBadge(score: t['score'] as int),
              const SizedBox(height: 8),
              Text('Ville: ${t['city']}'),
              Text('Expérience: ${t['experience']} ans'),
              Text('Études: ${t['education']}'),
              Text('Disponibilité: ${t['availability']}'),
              const SizedBox(height: 8),
              const Text('Compétences', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (t['skills'] as List<String>).map((s) => Chip(label: Text(s))).toList(),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
      ),
    );
  }
}

List<Map<String, dynamic>> _seedTalents() {
  return [
    {
      'id': 't1',
      'name': 'Mamadou Barry',
      'title': 'Développeur Flutter',
      'score': 94,
      'city': 'Conakry',
      'experience': '3-5',
      'education': 'Master',
      'availability': 'immédiate',
      'languages': ['Français', 'Anglais'],
      'skills': ['Flutter', 'Dart', 'Firebase', 'REST', 'Git'],
    },
    {
      'id': 't2',
      'name': 'Aissatou Diallo',
      'title': 'UX/UI Designer',
      'score': 91,
      'city': 'Conakry',
      'experience': '3-5',
      'education': 'Master',
      'availability': '1 mois',
      'languages': ['Français', 'Soussou'],
      'skills': ['Figma', 'Design System', 'Prototypage', 'UX Research'],
    },
    {
      'id': 't3',
      'name': 'Ibrahima Bah',
      'title': 'Data Analyst',
      'score': 86,
      'city': 'Kindia',
      'experience': '1-2',
      'education': 'Licence',
      'availability': 'immédiate',
      'languages': ['Français', 'Pular'],
      'skills': ['SQL', 'Power BI', 'Python', 'Excel'],
    },
    {
      'id': 't4',
      'name': 'Mohamed Kaba',
      'title': 'Data Engineer',
      'score': 89,
      'city': 'Boké',
      'experience': '5+',
      'education': 'Master',
      'availability': '2+ mois',
      'languages': ['Français', 'Anglais'],
      'skills': ['Airflow', 'Spark', 'Python', 'PostgreSQL', 'ETL'],
    },
    {
      'id': 't5',
      'name': 'Mariama Camara',
      'title': 'Assistante RH',
      'score': 73,
      'city': 'Labé',
      'experience': '1-2',
      'education': 'Licence',
      'availability': 'immédiate',
      'languages': ['Français', 'Malinké'],
      'skills': ['Recrutement', 'Communication', 'Excel'],
    },
    {
      'id': 't6',
      'name': 'Abdoulaye Touré',
      'title': 'Développeur Backend Node.js',
      'score': 82,
      'city': 'Conakry',
      'experience': '3-5',
      'education': 'Licence',
      'availability': '1 mois',
      'languages': ['Français', 'Anglais'],
      'skills': ['Node.js', 'Express', 'PostgreSQL', 'Docker', 'JWT'],
    },
    {
      'id': 't7',
      'name': 'Fatoumata Sylla',
      'title': 'Comptable',
      'score': 68,
      'city': 'Kankan',
      'experience': '5+',
      'education': 'Master',
      'availability': 'immédiate',
      'languages': ['Français'],
      'skills': ['Sage', 'Fiscalité', 'Reporting'],
    },
    {
      'id': 't8',
      'name': 'Ousmane Diallo',
      'title': 'Technicien Réseau',
      'score': 64,
      'city': 'Kindia',
      'experience': '1-2',
      'education': 'Bac',
      'availability': '2+ mois',
      'languages': ['Français', 'Pular'],
      'skills': ['Cisco', 'Maintenance', 'Support IT'],
    },
    {
      'id': 't9',
      'name': 'Naby Keita',
      'title': 'Chef de Projet',
      'score': 77,
      'city': 'Conakry',
      'experience': '5+',
      'education': 'Master',
      'availability': '1 mois',
      'languages': ['Français', 'Anglais'],
      'skills': ['Agile', 'Scrum', 'Pilotage', 'Communication'],
    },
    {
      'id': 't10',
      'name': 'Saran Fofana',
      'title': 'Développeuse Frontend',
      'score': 84,
      'city': 'Conakry',
      'experience': '3-5',
      'education': 'Licence',
      'availability': 'immédiate',
      'languages': ['Français', 'Anglais'],
      'skills': ['Flutter', 'React', 'TypeScript', 'UI/UX'],
    },
    {
      'id': 't11',
      'name': 'Alpha Bah',
      'title': 'Commercial B2B',
      'score': 71,
      'city': 'Boké',
      'experience': '1-2',
      'education': 'Bac',
      'availability': 'immédiate',
      'languages': ['Français', 'Soussou'],
      'skills': ['Prospection', 'Négociation', 'CRM'],
    },
    {
      'id': 't12',
      'name': 'Kadiatou Condé',
      'title': 'Community Manager',
      'score': 66,
      'city': 'Labé',
      'experience': 'sans',
      'education': 'Licence',
      'availability': '1 mois',
      'languages': ['Français', 'Anglais'],
      'skills': ['Meta Ads', 'Copywriting', 'Canva'],
    },
  ];
}
