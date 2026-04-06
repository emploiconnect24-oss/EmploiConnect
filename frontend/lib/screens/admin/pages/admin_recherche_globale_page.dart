import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/admin_service.dart';
import '../widgets/admin_search_delegate.dart';

/// Recherche globale admin (GET `/admin/recherche`) — sections par type.
class AdminRechercheGlobalePage extends StatefulWidget {
  const AdminRechercheGlobalePage({super.key});

  @override
  State<AdminRechercheGlobalePage> createState() => _AdminRechercheGlobalePageState();
}

class _AdminRechercheGlobalePageState extends State<AdminRechercheGlobalePage> {
  final _ctrl = TextEditingController();
  final _admin = AdminService();
  Timer? _debounce;
  List<Map<String, dynamic>> _resultats = const [];
  bool _loading = false;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _scheduleSearch(String q) {
    _debounce?.cancel();
    final t = q.trim();
    if (t.length < 2) {
      setState(() {
        _resultats = const [];
        _query = '';
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted || _ctrl.text.trim() != t) return;
      try {
        final body = await _admin.rechercheGlobale(t);
        final data = body['data'];
        final raw = (data is Map ? data['resultats'] : null) as List<dynamic>? ?? const [];
        final list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (!mounted) return;
        setState(() {
          _resultats = list;
          _query = t;
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _resultats = const [];
          _loading = false;
        });
      }
    });
  }

  void _applySuggestion(String s) {
    _ctrl.text = s;
    _scheduleSearch(s);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final users = _resultats.where((r) => r['type'] == 'utilisateur').toList();
    final offres = _resultats.where((r) => r['type'] == 'offre').toList();
    final entrs = _resultats.where((r) => r['type'] == 'entreprise').toList();
    final total = _resultats.length;
    final q = _ctrl.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recherche globale',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Utilisateurs, offres et entreprises',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x30000000),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _ctrl,
                  autofocus: false,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nom, email, entreprise, offre…',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFFCBD5E1),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1A56DB), size: 24),
                    suffixIcon: _ctrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _ctrl.clear();
                              _debounce?.cancel();
                              setState(() {
                                _resultats = const [];
                                _query = '';
                                _loading = false;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                  onChanged: (v) {
                    setState(() {});
                    _scheduleSearch(v);
                  },
                ),
              ),
              if (q.isNotEmpty && q.length < 2) ...[
                const SizedBox(height: 10),
                Text(
                  'Saisir au moins 2 caractères',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A56DB)))
              : q.length < 2
                  ? _buildAccueil()
                  : total == 0
                      ? _buildEmpty()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                margin: const EdgeInsets.only(bottom: 18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search_rounded, color: Color(0xFF1A56DB), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$total résultat(s) pour « $_query »',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF1E40AF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (users.isNotEmpty) ...[
                                _SectionTitle(
                                  titre: 'Utilisateurs',
                                  count: users.length,
                                  couleur: const Color(0xFF10B981),
                                ),
                                ...users.map((u) => _ResultTile(
                                      icon: Icons.person_outlined,
                                      iconColor: const Color(0xFF10B981),
                                      titre: u['titre']?.toString() ?? '—',
                                      sous: u['sous_titre']?.toString() ?? '',
                                      onTap: () => AdminSearchDelegate.openResult(context, u),
                                    )),
                                const SizedBox(height: 16),
                              ],
                              if (offres.isNotEmpty) ...[
                                _SectionTitle(
                                  titre: 'Offres d’emploi',
                                  count: offres.length,
                                  couleur: const Color(0xFF1A56DB),
                                ),
                                ...offres.map((o) => _ResultTile(
                                      icon: Icons.work_outline_rounded,
                                      iconColor: const Color(0xFF1A56DB),
                                      titre: o['titre']?.toString() ?? '—',
                                      sous: o['sous_titre']?.toString() ?? '',
                                      onTap: () => AdminSearchDelegate.openResult(context, o),
                                    )),
                                const SizedBox(height: 16),
                              ],
                              if (entrs.isNotEmpty) ...[
                                _SectionTitle(
                                  titre: 'Entreprises',
                                  count: entrs.length,
                                  couleur: const Color(0xFF8B5CF6),
                                ),
                                ...entrs.map((e) => _ResultTile(
                                      icon: Icons.business_outlined,
                                      iconColor: const Color(0xFF8B5CF6),
                                      titre: e['titre']?.toString() ?? '—',
                                      sous: e['sous_titre']?.toString() ?? '',
                                      onTap: () => AdminSearchDelegate.openResult(context, e),
                                    )),
                              ],
                            ],
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildAccueil() {
    final token = context.read<AuthProvider>().token;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded, color: Color(0xFF1A56DB), size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Recherche globale',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tapez au moins 2 caractères dans la barre ci-dessus.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (token == null || token.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Session expirée : reconnectez-vous pour lancer une recherche.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFEF4444)),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip('Développeur', () => _applySuggestion('Développeur')),
                _SuggestionChip('Conakry', () => _applySuggestion('Conakry')),
                _SuggestionChip('CDI', () => _applySuggestion('CDI')),
                _SuggestionChip('Stage', () => _applySuggestion('Stage')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, color: Color(0xFF94A3B8), size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun résultat',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun résultat pour « $_query »',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.titre,
    required this.count,
    required this.couleur,
  });

  final String titre;
  final int count;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: couleur,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            titre,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: couleur,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.icon,
    required this.iconColor,
    required this.titre,
    required this.sous,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String titre;
  final String sous;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          titre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          sous,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
        onTap: onTap,
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF374151)),
          ),
        ),
      ),
    );
  }
}
