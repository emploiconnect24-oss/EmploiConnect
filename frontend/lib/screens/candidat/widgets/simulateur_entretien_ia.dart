import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/candidat_parcours_service.dart';

/// Illustration thématique (emoji + couleur + titre) — PRD §2, sans API image.
Map<String, Object> illustrationPourQuestion(String? type, String? theme, String? questionText) {
  final t = '${theme ?? ''} ${type ?? ''} ${questionText ?? ''}'.toLowerCase();

  if (t.contains('code') ||
      t.contains('technique') ||
      t.contains('programm') ||
      t.contains('flutter') ||
      t.contains('développ') ||
      t.contains('developp') ||
      t.contains('informatique')) {
    return {'emoji': '💻', 'titre': 'Question technique', 'couleur': const Color(0xFF1A56DB)};
  }
  if (t.contains('team') || t.contains('équipe') || t.contains('equipe') || t.contains('leader')) {
    return {'emoji': '🤝', 'titre': "Travail d'équipe", 'couleur': const Color(0xFF10B981)};
  }
  if (t.contains('stress') || t.contains('pression') || t.contains('difficulté') || t.contains('defi')) {
    return {'emoji': '🧘', 'titre': 'Gestion du stress', 'couleur': const Color(0xFFF59E0B)};
  }
  if (t.contains('motiv') || t.contains('objectif') || t.contains('ambition') || t.contains('carrière') || t.contains('carriere')) {
    return {'emoji': '🎯', 'titre': 'Motivation', 'couleur': const Color(0xFF8B5CF6)};
  }
  if (t.contains('experience') || t.contains('projet') || t.contains('réalisation') || t.contains('realisation') || t.contains('résultat')) {
    return {'emoji': '🏆', 'titre': "Expérience & résultats", 'couleur': const Color(0xFFF59E0B)};
  }
  if (t.contains('comptab') || t.contains('finance') || t.contains('budget') || t.contains('chiffre')) {
    return {'emoji': '💰', 'titre': 'Finance / comptabilité', 'couleur': const Color(0xFF10B981)};
  }
  if (t.contains('client') || t.contains('vente') || t.contains('commercial') || t.contains('négoci') || t.contains('negoci')) {
    return {'emoji': '🤝', 'titre': 'Relation client / vente', 'couleur': const Color(0xFF0EA5E9)};
  }
  if (t.contains('comportemental') || t.contains('situation')) {
    return {'emoji': '🎭', 'titre': 'Comportement / mise en situation', 'couleur': const Color(0xFF8B5CF6)};
  }
  return {'emoji': '💬', 'titre': "Question d'entretien", 'couleur': const Color(0xFF8B5CF6)};
}

/// Simulateur d’entretien IA (PRD animations v8.8).
class SimulateurEntretienIA extends StatefulWidget {
  const SimulateurEntretienIA({super.key});

  @override
  State<SimulateurEntretienIA> createState() => _SimulateurEntretienIAState();
}

class _SimulateurEntretienIAState extends State<SimulateurEntretienIA> with TickerProviderStateMixin {
  final _svc = CandidatParcoursService();
  late ConfettiController _confettiCtrl;

  String _phase = 'config';
  final _posteCtrl = TextEditingController();
  String _domaine = 'informatique';
  String _niveau = 'junior';
  int _nbQuestions = 5;

  List<Map<String, dynamic>> _questions = [];
  int _questionActuelle = 0;
  bool _isGenerating = false;
  bool _isEvaluating = false;

  final _reponseCtrl = TextEditingController();
  List<Map<String, dynamic>> _reponses = [];

  @override
  void initState() {
    super.initState();
    _posteCtrl.addListener(() => setState(() {}));
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _posteCtrl.dispose();
    _reponseCtrl.dispose();
    super.dispose();
  }

  Color _illusColor(Map<String, Object> illus) => illus['couleur'] as Color;

  @override
  Widget build(BuildContext context) {
    if (_phase == 'resultat') {
      return _buildResultatStack();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _phase == 'config' ? _buildConfig() : _buildSimulation(),
    );
  }

  Widget _buildConfig() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simulateur d\'entretien IA',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      Text(
                        'L’IA vous pose des questions et évalue vos réponses',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _carteConfig(
            titre: 'Poste visé',
            child: TextField(
              controller: _posteCtrl,
              decoration: InputDecoration(
                hintText: 'Ex : Développeur Flutter, Comptable…',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _carteConfig(
            titre: 'Domaine',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chipDomaine('informatique', 'Informatique'),
                _chipDomaine('finance', 'Finance'),
                _chipDomaine('marketing', 'Marketing'),
                _chipDomaine('rh', 'RH'),
                _chipDomaine('commercial', 'Commercial'),
                _chipDomaine('autre', 'Autre'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _carteConfig(
            titre: 'Niveau d\'expérience',
            child: Row(
              children: [
                Expanded(child: _chipNiveau('junior', 'Junior')),
                const SizedBox(width: 8),
                Expanded(child: _chipNiveau('senior', 'Senior')),
                const SizedBox(width: 8),
                Expanded(child: _chipNiveau('expert', 'Expert')),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _carteConfig(
            titre: 'Nombre de questions',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _nbQuestions > 3 ? () => setState(() => _nbQuestions--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '$_nbQuestions',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF8B5CF6)),
                  ),
                ),
                IconButton(
                  onPressed: _nbQuestions < 10 ? () => setState(() => _nbQuestions++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                _isGenerating ? 'Génération en cours…' : 'Démarrer la simulation',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isGenerating || _posteCtrl.text.trim().isEmpty ? null : _demarrerSimulation,
            ),
          ),
          if (_posteCtrl.text.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '* Renseignez le poste visé pour commencer',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFEF4444)),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      );

  Widget _chipDomaine(String val, String label) {
    final sel = _domaine == val;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
      selected: sel,
      onSelected: (_) => setState(() => _domaine = val),
      selectedColor: const Color(0xFF8B5CF6),
      labelStyle: TextStyle(color: sel ? Colors.white : const Color(0xFF64748B)),
    );
  }

  Widget _chipNiveau(String val, String label) {
    final sel = _niveau == val;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
      selected: sel,
      onSelected: (_) => setState(() => _niveau = val),
      selectedColor: const Color(0xFF8B5CF6),
      labelStyle: TextStyle(color: sel ? Colors.white : const Color(0xFF64748B)),
    );
  }

  Widget _carteConfig({required String titre, required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );

  Widget _buildSimulation() {
    if (_questions.isEmpty) return const SizedBox();
    final q = _questions[_questionActuelle];
    final total = _questions.length;
    final prog = (_questionActuelle + 1) / total;
    final illus = illustrationPourQuestion(
      q['type']?.toString(),
      q['theme']?.toString(),
      q['question']?.toString(),
    );
    final couleur = _illusColor(illus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: prog),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          builder: (_, v, __) => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                  const Color(0xFF1A56DB).withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Q${_questionActuelle + 1}/$total',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          q['type']?.toString() ?? '',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8B5CF6), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Text(
                      '${(v * 100).round()}% complété',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Container(
            key: ValueKey<int>(_questionActuelle),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: couleur.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(color: couleur.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: couleur.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(illus['emoji']! as String, style: const TextStyle(fontSize: 28))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            illus['titre']! as String,
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: couleur),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            q['question']?.toString() ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if ((q['conseil'] as String?)?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            q['conseil'] as String,
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Votre réponse :',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF374151)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reponseCtrl,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Répondez clairement, avec des exemples concrets…',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (_questionActuelle > 0)
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded, size: 14),
                  label: const Text('Précédent'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    foregroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => setState(() {
                    _questionActuelle--;
                    _reponseCtrl.text = _reponses.length > _questionActuelle
                        ? (_reponses[_questionActuelle]['reponse']?.toString() ?? '')
                        : '';
                  }),
                ),
              ),
            if (_questionActuelle > 0) const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: _isEvaluating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        _questionActuelle < total - 1 ? Icons.arrow_forward_rounded : Icons.check_circle_rounded,
                        size: 16,
                      ),
                label: Text(
                  _isEvaluating
                      ? 'IA évalue…'
                      : _questionActuelle < total - 1
                          ? 'Répondre et continuer'
                          : 'Terminer l\'entretien',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isEvaluating ? null : _repondreEtContinuer,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultatStack() {
    if (_reponses.isEmpty) return const SizedBox();
    final scoreGlobal = (_reponses.map((r) => (r['score'] as num?)?.toInt() ?? 0).reduce((a, b) => a + b) / _reponses.length).round();
    final excellent = scoreGlobal >= 80;
    final bon = scoreGlobal >= 60;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.08,
            numberOfParticles: 20,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Color(0xFF1A56DB),
              Color(0xFF10B981),
              Color(0xFF8B5CF6),
              Color(0xFFF59E0B),
              Color(0xFFEF4444),
            ],
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: scoreGlobal / 100),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) {
                  final pct = (v * 100).round();
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: excellent
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : bon
                                ? [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)]
                                : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(excellent ? '🎉' : bon ? '👍' : '📈', style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        Text(
                          '$pct / 100',
                          style: GoogleFonts.poppins(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        Text(
                          excellent
                              ? 'Excellent ! Vous êtes prêt !'
                              : bon
                                  ? 'Bon résultat ! Continuez ainsi'
                                  : 'Des axes d\'amélioration identifiés',
                          style: GoogleFonts.inter(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: v,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildAnalyseDetaillee(scoreGlobal),
              const SizedBox(height: 20),
              Text(
                'Détail question par question',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              ..._reponses.asMap().entries.map((e) {
                final i = e.key;
                final r = e.value;
                final s = (r['score'] as num?)?.toInt() ?? 0;
                final sc = s >= 70 ? const Color(0xFF10B981) : s >= 50 ? const Color(0xFF8B5CF6) : const Color(0xFFF59E0B);
                final illus = illustrationPourQuestion(r['type']?.toString(), r['theme']?.toString(), r['question']?.toString());
                final pf = (r['points_forts'] is List) ? (r['points_forts'] as List).map((x) => x.toString()).toList() : <String>[];
                final am = (r['ameliorations'] is List) ? (r['ameliorations'] as List).map((x) => x.toString()).toList() : <String>[];

                return AnimatedContainer(
                  duration: Duration(milliseconds: 400 + i * 80),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sc.withValues(alpha: 0.3)),
                    boxShadow: [BoxShadow(color: sc.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(illus['emoji']! as String, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r['question']?.toString() ?? '',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: sc.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '$s/100',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: sc),
                            ),
                          ),
                        ],
                      ),
                      if (pf.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('Points forts', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
                        ...pf.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 2),
                            child: Text('• $p', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF374151))),
                          ),
                        ),
                      ],
                      if (am.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Axes d\'amélioration', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFF59E0B))),
                        ...am.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 2),
                            child: Text('• $a', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF374151))),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFF8B5CF6)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                r['feedback']?.toString() ?? '',
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF374151), height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Recommencer'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF8B5CF6)),
                  foregroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => setState(() {
                  _phase = 'config';
                  _questions = [];
                  _reponses = [];
                  _questionActuelle = 0;
                  _reponseCtrl.clear();
                }),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyseDetaillee(int score) {
    final excellent = score >= 80;
    final bon = score >= 60;
    final moyen = score >= 40;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6), size: 18),
              const SizedBox(width: 8),
              Text(
                'Analyse IA de votre entretien',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _EtapeAnalyse(
            numero: '01',
            titre: 'Pertinence des réponses',
            desc: excellent
                ? 'Vos réponses sont très pertinentes et bien structurées.'
                : bon
                    ? 'Vos réponses sont globalement pertinentes.'
                    : 'Certaines réponses gagneraient à être plus précises.',
            icone: excellent ? '✅' : bon ? '⚡' : '📝',
            couleur: excellent ? const Color(0xFF10B981) : bon ? const Color(0xFF1A56DB) : const Color(0xFFF59E0B),
          ),
          _EtapeAnalyse(
            numero: '02',
            titre: 'Maîtrise du domaine',
            desc: excellent
                ? 'Bonne impression de maîtrise du sujet et du contexte du poste.'
                : bon
                    ? 'Bases solides, quelques points à creuser davantage.'
                    : 'Renforcez les aspects techniques ou métiers liés au poste.',
            icone: excellent ? '🎯' : bon ? '📊' : '📚',
            couleur: excellent ? const Color(0xFF10B981) : bon ? const Color(0xFF8B5CF6) : const Color(0xFFF59E0B),
          ),
          _EtapeAnalyse(
            numero: '03',
            titre: 'Communication et clarté',
            desc: excellent
                ? 'Idées claires, bon fil conducteur dans vos réponses.'
                : bon
                    ? 'Communication correcte, structure perfectible.'
                    : 'Structurez davantage (contexte, action, résultat).',
            icone: excellent ? '🗣️' : bon ? '💬' : '✏️',
            couleur: excellent ? const Color(0xFF10B981) : bon ? const Color(0xFF0EA5E9) : const Color(0xFFF59E0B),
          ),
          _EtapeAnalyse(
            numero: '04',
            titre: 'Recommandation finale',
            desc: excellent
                ? 'Vous pouvez aborder un entretien réel avec confiance sur ce type de questions.'
                : bon
                    ? 'Continuez à pratiquer sur les points faibles identifiés ci-dessous.'
                    : moyen
                        ? 'Révisez les fondamentaux et refaites une simulation.'
                        : 'Prenez le temps de préparer des exemples concrets avant de postuler.',
            icone: excellent ? '🚀' : bon ? '💪' : '🎯',
            couleur: excellent ? const Color(0xFF10B981) : bon ? const Color(0xFF8B5CF6) : const Color(0xFFEF4444),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Future<void> _demarrerSimulation() async {
    if (_posteCtrl.text.trim().isEmpty) return;
    setState(() => _isGenerating = true);
    try {
      final body = await _svc.genererQuestionsSimulateur({
        'poste_vise': _posteCtrl.text.trim(),
        'domaine': _domaine,
        'niveau': _niveau,
        'nb_questions': _nbQuestions,
      });
      final qs = List<Map<String, dynamic>>.from((body['data'] as Map?)?['questions'] as List? ?? []);
      if (!mounted) return;
      setState(() {
        _questions = qs;
        _reponses = [];
        _questionActuelle = 0;
        _phase = 'simulation';
        _reponseCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _repondreEtContinuer() async {
    final reponse = _reponseCtrl.text.trim();
    if (reponse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Écrivez votre réponse avant de continuer'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isEvaluating = true);
    try {
      final q = _questions[_questionActuelle];
      final body = await _svc.evaluerReponseSimulateur({
        'question': q['question'],
        'reponse': reponse,
        'poste_vise': _posteCtrl.text.trim(),
        'domaine': _domaine,
        'niveau': _niveau,
      });
      final eval = body['data'] as Map<String, dynamic>? ?? {};
      final rep = <String, dynamic>{
        'question': q['question'],
        'reponse': reponse,
        'type': q['type'],
        'theme': q['theme'],
        'score': (eval['score'] as num?)?.toInt() ?? 50,
        'feedback': eval['feedback']?.toString() ?? '',
        'points_forts': eval['points_forts'] ?? [],
        'ameliorations': eval['ameliorations'] ?? [],
      };

      if (!mounted) return;
      setState(() {
        if (_reponses.length > _questionActuelle) {
          _reponses[_questionActuelle] = rep;
        } else {
          _reponses.add(rep);
        }
      });

      final total = _questions.length;
      if (_questionActuelle < total - 1) {
        if (!mounted) return;
        setState(() {
          _questionActuelle++;
          _reponseCtrl.clear();
        });
      } else {
        final scoreGlobal = (_reponses.map((r) => (r['score'] as num?)?.toInt() ?? 0).reduce((a, b) => a + b) / _reponses.length).round();
        await _svc.sauvegarderSimulation({
          'poste_vise': _posteCtrl.text.trim(),
          'domaine': _domaine,
          'niveau': _niveau,
          'questions': _reponses,
          'score_global': scoreGlobal,
        });
        if (!mounted) return;
        setState(() => _phase = 'resultat');
        if (scoreGlobal >= 60) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _confettiCtrl.play();
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur évaluation : $e'), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isEvaluating = false);
    }
  }
}

class _EtapeAnalyse extends StatelessWidget {
  const _EtapeAnalyse({
    required this.numero,
    required this.titre,
    required this.desc,
    required this.icone,
    required this.couleur,
    this.isLast = false,
  });

  final String numero;
  final String titre;
  final String desc;
  final String icone;
  final Color couleur;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: couleur.withValues(alpha: 0.3)),
              ),
              child: Center(child: Text(icone, style: const TextStyle(fontSize: 14))),
            ),
            if (!isLast) Container(width: 2, height: 28, color: const Color(0xFFE2E8F0)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      numero,
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Text(titre, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 3),
                Text(desc, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
