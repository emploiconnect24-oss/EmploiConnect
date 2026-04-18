import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/candidat_parcours_service.dart';
import '../../../utils/speech_service.dart';

class SimulationEntretienPage extends StatefulWidget {
  const SimulationEntretienPage({super.key, this.onExit});
  final VoidCallback? onExit;
  @override
  State<SimulationEntretienPage> createState() => _SimulationEntretienPageState();
}

class _SimulationEntretienPageState extends State<SimulationEntretienPage> with TickerProviderStateMixin {
  static const _etapeConfig = 0;
  static const _etapeEntretien = 1;
  static const _etapeRapport = 2;

  final _svc = CandidatParcoursService();
  final _posteCtrl = TextEditingController();
  final _reponseCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  static const _recruteurs = [
    {
      'nom': 'Mamadou Diallo',
      'genre': 'homme',
      'titre': 'Directeur des Ressources Humaines',
      'photo': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
    },
    {
      'nom': 'Aminata Camara',
      'genre': 'femme',
      'titre': 'Responsable Recrutement',
      'photo': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&q=80',
    },
    {
      'nom': 'Ibrahima Sow',
      'genre': 'homme',
      'titre': 'Chef du Personnel',
      'photo': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&q=80',
    },
    {
      'nom': 'Fatoumata Barry',
      'genre': 'femme',
      'titre': 'DRH Senior',
      'photo': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&q=80',
    },
    {
      'nom': 'Oumar Kouyate',
      'genre': 'homme',
      'titre': 'Manager Talent Acquisition',
      'photo': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&q=80',
    },
    {
      'nom': 'Kadiatou Bah',
      'genre': 'femme',
      'titre': 'Responsable RH',
      'photo': 'https://images.unsplash.com/photo-1614644147798-f8c0fc9da7f6?w=400&q=80',
    },
  ];

  int _etape = _etapeConfig;
  String _niveauChoisi = 'junior';
  String? _sessionId;
  bool _isLoading = false;
  bool _estFin = false;
  bool _micActif = false;
  bool _recruteurParle = false;
  bool _candidatParle = false;
  int _nbQuestions = 0;
  String _texteRecruteurEnCours = '';
  bool _texteEstComplet = true;
  String _texteCandidat = '';
  Map<String, dynamic>? _rapport;
  late Map<String, String> _recruteur;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    final rand = Random();
    _recruteur = Map<String, String>.from(_recruteurs[rand.nextInt(_recruteurs.length)]);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scrollCtrl.dispose();
    _posteCtrl.dispose();
    _reponseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: switch (_etape) {
          _etapeConfig => _buildConfig(),
          _etapeEntretien => _buildEntretien(),
          _ => _buildRapport(),
        },
      ),
    );
  }

  Widget _buildConfig() => LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Simulation d\'entretien',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Repondez par texte ou par voix a un recruteur virtuel.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _posteCtrl,
                        style: GoogleFonts.inter(color: const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          labelText: 'Poste vise',
                          labelStyle: GoogleFonts.inter(color: const Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1A56DB)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: ['junior', 'senior', 'manager'].map((n) {
                          final selected = _niveauChoisi == n;
                          return ChoiceChip(
                            label: Text(n),
                            selected: selected,
                            onSelected: (_) => setState(() => _niveauChoisi = n),
                            selectedColor: const Color(0xFF1A56DB),
                            backgroundColor: const Color(0xFFF0F7FF),
                            visualDensity: VisualDensity.compact,
                            labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF1A56DB)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _demarrer,
                          icon: _isLoading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.play_arrow_rounded),
                          label: Text(_isLoading ? 'Preparation...' : 'Demarrer l\'entretien'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

  Widget _buildEntretien() => Scaffold(
        backgroundColor: const Color(0xFFF0F7FF),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final isWide = constraints.maxWidth > 720;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isWide)
                          Container(
                            width: 200,
                            color: const Color(0xFFF8FAFC),
                            child: _buildPanneauRecruteur(),
                          ),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(child: _buildMessages()),
                              if (!_estFin) _buildInputZone(),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _confirmerAbandon,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFF0F7FF), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 16),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_posteCtrl.text.isEmpty ? 'Entretien' : _posteCtrl.text, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('$_nbQuestions questions', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(value: (_nbQuestions / 10).clamp(0.0, 1.0), backgroundColor: const Color(0xFFE2E8F0), color: const Color(0xFF1A56DB), minHeight: 3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildPanneauRecruteur() {
    if (_recruteur.isEmpty) return const SizedBox();
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(scale: _recruteurParle ? _pulseAnim.value : 1.0, child: child),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _recruteurParle ? const Color(0xFF10B981) : const Color(0xFF1A56DB), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: (_recruteurParle ? const Color(0xFF10B981) : const Color(0xFF1A56DB)).withValues(alpha: 0.35),
                      blurRadius: _recruteurParle ? 20 : 8,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    _recruteur['photo'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) => _avatarInitiales(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _recruteur['nom'] ?? 'Recruteur',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _recruteur['titre'] ?? 'Responsable Recrutement',
                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatutRecruteur(),
          ],
        ),
      );
  }

  Widget _buildStatutRecruteur() => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _recruteurParle
              ? const Color(0xFF10B981).withValues(alpha: 0.15)
              : _candidatParle
                  ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                  : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: _recruteurParle
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : _candidatParle
                    ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                    : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _recruteurParle
                    ? const Color(0xFF10B981)
                    : _candidatParle
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _recruteurParle
                  ? 'Parle'
                  : _candidatParle
                      ? 'Ecoute'
                      : 'Attente',
              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      );

  Widget _avatarInitiales() => Container(
        color: const Color(0xFF1A56DB),
        child: Center(child: Text((_recruteur['nom'] ?? 'R')[0], style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900))),
      );

  Widget _buildMessages() => _messages.isEmpty
      ? const Center(
          child: Text(
            'Demarrez l\'entretien...',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        )
      : ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: _messages.length,
        itemBuilder: (_, i) {
          if (i >= _messages.length) return const SizedBox();
          final m = _messages[i];
          final recruteur = m['role'] == 'recruteur';
          final estDernier = i == _messages.length - 1;
          final texte = recruteur && estDernier && !_texteEstComplet ? _texteRecruteurEnCours : (m['contenu']?.toString() ?? '');
          return Align(
            alignment: recruteur ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                color: recruteur ? Colors.white : const Color(0xFF1A56DB),
                borderRadius: BorderRadius.circular(12),
                boxShadow: recruteur
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : const [],
              ),
              child: Text(
                texte,
                style: GoogleFonts.inter(
                  color: recruteur ? const Color(0xFF0F172A) : Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          );
        },
      );

  Widget _buildInputZone() => LayoutBuilder(
        builder: (context, constraints) {
          final maxH = constraints.maxHeight;
          final bounded = maxH.isFinite && maxH > 0 && maxH < double.infinity;
          final body = DecoratedBox(
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _reponseCtrl,
                          style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 14),
                          maxLines: 4,
                          minLines: 1,
                          scrollPhysics: const ClampingScrollPhysics(),
                          decoration: InputDecoration(
                            hintText: _micActif ? 'Parlez...' : 'Votre reponse...',
                            hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1A56DB))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BoutonRond(
                            icone: _micActif ? Icons.mic_rounded : Icons.mic_none_rounded,
                            couleur: _micActif ? const Color(0xFFEF4444) : const Color(0xFFF0F7FF),
                            bordure: _micActif ? const Color(0xFFEF4444) : const Color(0xFF1A56DB),
                            onTap: _toggleMic,
                            label: _micActif ? 'Stop' : 'Micro',
                            iconeColor: _micActif ? Colors.white : const Color(0xFF1A56DB),
                          ),
                          const SizedBox(height: 6),
                          _BoutonRond(
                            icone: Icons.send_rounded,
                            couleur: _isLoading ? const Color(0xFF94A3B8) : const Color(0xFF1A56DB),
                            bordure: Colors.transparent,
                            onTap: _isLoading ? null : _envoyerReponse,
                            label: 'Envoyer',
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );

          if (!bounded) {
            return body;
          }
          return ClipRect(
            child: SizedBox(
              height: maxH,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: body,
                ),
              ),
            ),
          );
        },
      );

  Widget _buildRapport() {
    if (_rapport == null) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A56DB)));
    final score = (_rapport!['score_global'] as num?)?.toInt() ?? 0;
    final forts = List<String>.from(_rapport!['points_forts'] ?? const []);
    final faibles = List<String>.from(_rapport!['points_ameliorer'] ?? const []);
    final conseils = List<String>.from(_rapport!['conseils'] ?? const []);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text('Rapport final', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          const SizedBox(height: 14),
          CircularProgressIndicator(value: score / 100, strokeWidth: 10, color: const Color(0xFF1A56DB), backgroundColor: const Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          Text('$score / 100', style: GoogleFonts.poppins(fontSize: 32, color: const Color(0xFF0F172A), fontWeight: FontWeight.w900)),
          Text(_rapport!['verdict']?.toString() ?? '', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          const SizedBox(height: 14),
          _blocListe('Points forts', forts, const Color(0xFF10B981)),
          _blocListe('Points a ameliorer', faibles, const Color(0xFFF59E0B)),
          _blocListe('Conseils', conseils, const Color(0xFF1A56DB)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _etape = _etapeConfig;
                    _sessionId = null;
                    _messages.clear();
                    _rapport = null;
                    _nbQuestions = 0;
                    _estFin = false;
                    _texteCandidat = '';
                  }),
                  child: const Text('Recommencer'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
                  },
                  child: const Text('Tableau de bord'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blocListe(String titre, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...items.map((e) => Text('• $e', style: GoogleFonts.inter(color: const Color(0xFF334155)))),
        ],
      ),
    );
  }

  Future<void> _afficherTexteProgressif(String texte) async {
    if (!mounted) return;
    setState(() {
      _texteRecruteurEnCours = '';
      _texteEstComplet = false;
    });
    for (int i = 0; i < texte.length; i++) {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (!mounted) return;
      setState(() => _texteRecruteurEnCours = texte.substring(0, i + 1));
      _scrollBas();
    }
    if (!mounted) return;
    setState(() => _texteEstComplet = true);
  }

  Future<void> _parlerRecruteur(String texte) async {
    if (!mounted) return;
    setState(() => _recruteurParle = true);
    try {
      SpeechService.parler(
        texte,
        genre: _recruteur['genre'] ?? 'homme',
      );
    } catch (_) {}
    final duree = Duration(milliseconds: (texte.length * 55).clamp(1500, 10000));
    await Future<void>.delayed(duree);
    if (!mounted) return;
    setState(() => _recruteurParle = false);
  }

  void _scrollBas() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _demarrer() async {
    if (_posteCtrl.text.trim().isEmpty) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final body = await _svc.demarrerSimulationEntretien({
        'poste_vise': _posteCtrl.text.trim(),
        'niveau': _niveauChoisi,
        'recruteur': _recruteur,
      });
      if (!mounted) return;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final msg = data['message_accueil']?.toString() ?? '';
      setState(() {
        _sessionId = data['session_id']?.toString();
        _messages..clear()..add({'role': 'recruteur', 'contenu': msg});
        _etape = _etapeEntretien;
        _nbQuestions = 0;
      });
      _scrollBas();
      await _afficherTexteProgressif(msg);
      await _parlerRecruteur(msg);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _envoyerReponse() async {
    final texte = _reponseCtrl.text.trim();
    if (texte.isEmpty || _sessionId == null) return;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _messages.add({'role': 'candidat', 'contenu': texte});
      _reponseCtrl.clear();
      _texteCandidat = '';
      _candidatParle = false;
      _micActif = false;
    });
    SpeechService.arreterMicro();
    _scrollBas();
    try {
      final body = await _svc.repondreSimulationEntretien(_sessionId!, texte, recruteur: _recruteur);
      if (!mounted) return;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final msg = data['message_recruteur']?.toString() ?? '';
      final estFin = data['est_fin'] == true;
      setState(() {
        _messages.add({'role': 'recruteur', 'contenu': msg});
        _nbQuestions = (data['nb_questions'] as num?)?.toInt() ?? _nbQuestions;
        _estFin = estFin;
      });
      _scrollBas();
      await _afficherTexteProgressif(msg);
      await _parlerRecruteur(msg);
      if (estFin) {
        if (!mounted) return;
        setState(() => _rapport = Map<String, dynamic>.from(data['rapport'] as Map? ?? {}));
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        setState(() => _etape = _etapeRapport);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleMic() {
    try {
      if (!_micActif) {
        if (!SpeechService.estDisponible()) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Micro non disponible, vous pouvez taper votre reponse.')));
          return;
        }
        if (!mounted) return;
        setState(() {
          _micActif = true;
          _candidatParle = true;
          _texteCandidat = '';
        });
        SpeechService.demarrerMicro((texte) {
          if (!mounted) return;
          setState(() {
            _texteCandidat = texte;
            _reponseCtrl.text = texte;
            _reponseCtrl.selection = TextSelection.collapsed(offset: _reponseCtrl.text.length);
          });
        });
      } else {
        if (!mounted) return;
        setState(() {
          _micActif = false;
          _candidatParle = false;
          if (_texteCandidat.isNotEmpty) _reponseCtrl.text = _texteCandidat;
        });
        SpeechService.arreterMicro();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _micActif = false;
        _candidatParle = false;
      });
    }
  }

  void _confirmerAbandon() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandonner l\'entretien ?'),
        content: const Text('Votre progression sera perdue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continuer')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.onExit != null) {
                widget.onExit!();
              } else {
                setState(() => _etape = _etapeConfig);
              }
            },
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
  }
}

class _PointsAnimes extends StatefulWidget {
  const _PointsAnimes({required this.couleur});
  final Color couleur;
  @override
  State<_PointsAnimes> createState() => _PointsAnimesState();
}

class _PointsAnimesState extends State<_PointsAnimes> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.3;
            final val = ((_ctrl.value + delay) % 1.0);
            final scale = val < 0.5 ? val * 2 : (1 - val) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Transform.scale(
                scale: 0.5 + scale * 0.5,
                child: Container(width: 5, height: 5, decoration: BoxDecoration(color: widget.couleur, shape: BoxShape.circle)),
              ),
            );
          }),
        ),
      );
}

class _BoutonRond extends StatelessWidget {
  const _BoutonRond({
    required this.icone,
    required this.couleur,
    required this.bordure,
    required this.onTap,
    required this.label,
    this.isLoading = false,
    this.iconeColor = Colors.white,
  });

  final IconData icone;
  final Color couleur;
  final Color bordure;
  final VoidCallback? onTap;
  final String label;
  final bool isLoading;
  final Color iconeColor;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: couleur,
                border: Border.all(color: bordure, width: 1.5),
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  : Icon(icone, color: iconeColor, size: 18),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF64748B))),
        ],
      );
}
