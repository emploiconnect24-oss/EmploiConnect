import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../config/api_config.dart';
import '../../../providers/auth_provider.dart';
import '../pages/createur_cv_page.dart';

/// Carte « Analyse IA » avec étapes animées (PRD Resume Parser Fix).
class AnalyseIAWidget extends StatefulWidget {
  const AnalyseIAWidget({super.key, required this.onAnalysed});

  final VoidCallback onAnalysed;

  @override
  State<AnalyseIAWidget> createState() => _AnalyseIAWidgetState();
}

class _AnalyseIAWidgetState extends State<AnalyseIAWidget>
    with SingleTickerProviderStateMixin {
  bool _isAnalysing = false;
  int _etapeActuelle = -1;
  String? _message;
  int _nbComps = 0;
  int _nbExps = 0;
  int _nbFmts = 0;
  String? _conseil;
  bool _succes = false;

  late AnimationController _dotCtrl;
  late Animation<double> _dotAnim;

  static const _etapes = [
    '📥  Téléchargement du CV...',
    '📄  Lecture du document...',
    '🤖  Analyse IA en cours...',
    '📊  Extraction des compétences...',
    '✅  Analyse terminée !',
  ];

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _dotAnim = Tween<double>(begin: 0.5, end: 1.0).animate(_dotCtrl);
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    super.dispose();
  }

  Future<void> _lancer() async {
    setState(() {
      _isAnalysing = true;
      _etapeActuelle = 0;
      _message = null;
      _conseil = null;
      _succes = false;
    });

    StreamSubscription<int>? avanceur;
    avanceur = Stream.periodic(const Duration(milliseconds: 900), (i) => i + 1)
        .take(3)
        .listen((etape) {
      if (mounted && _isAnalysing) {
        setState(() => _etapeActuelle = etape);
      }
    });

    try {
      final token = context.read<AuthProvider>().token ?? '';
      final uri = Uri.parse('$apiBaseUrl$apiPrefix/cv/analyser');
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 90));

      await avanceur.cancel();

      if (!mounted) return;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400) {
        setState(() {
          _message = body['message']?.toString() ?? 'Erreur ${res.statusCode}';
          _conseil = null;
          _succes = false;
          _nbComps = 0;
          _etapeActuelle = -1;
          _isAnalysing = false;
        });
        return;
      }

      final data = body['data'] as Map<String, dynamic>? ?? {};
      final nbRaw = data['nb_competences'];
      _nbComps = nbRaw is int ? nbRaw : (nbRaw is num ? nbRaw.toInt() : 0);
      final nbExRaw = data['nb_experiences'];
      final nbFmRaw = data['nb_formations'];
      _nbExps = nbExRaw is int ? nbExRaw : (nbExRaw is num ? nbExRaw.toInt() : 0);
      _nbFmts = nbFmRaw is int ? nbFmRaw : (nbFmRaw is num ? nbFmRaw.toInt() : 0);
      _conseil = data['conseil'] as String?;
      _message = body['message'] as String? ?? '';
      _succes = _nbComps > 0;

      setState(() {
        _etapeActuelle = 4;
        _isAnalysing = false;
      });

      widget.onAnalysed();
      final profilMaj = data['profil_mis_a_jour'] == true;
      if (_nbComps >= 3 && profilMaj && mounted) {
        _showResultatDialog(
          List<String>.from(data['competences'] ?? const []),
          List<Map<String, dynamic>>.from(data['experience'] ?? const []),
          List<Map<String, dynamic>>.from(data['formation'] ?? const []),
        );
      }
    } catch (e) {
      await avanceur.cancel();
      if (mounted) {
        setState(() {
          _message = 'Erreur : $e';
          _isAnalysing = false;
          _etapeActuelle = -1;
        });
      }
    }
  }

  void _showResultatDialog(
    List<String> comps,
    List<Map<String, dynamic>> exps,
    List<Map<String, dynamic>> fmts,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Analyse IA terminée'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Compétences: ${comps.length}'),
              Text('Expériences: ${exps.length}'),
              Text('Formations: ${fmts.length}'),
              const SizedBox(height: 10),
              if (comps.isNotEmpty) Text(comps.take(10).join(', ')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _ouvrirCreateurCv() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => CreateurCvPage(
          onClose: () => Navigator.of(ctx).pop(),
          onDone: () {
            Navigator.of(ctx).pop();
            widget.onAnalysed();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isAnalysing
              ? const Color(0xFF1A56DB).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: _isAnalysing
            ? [
                BoxShadow(
                  color: const Color(0xFF1A56DB).withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'IA',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analyse IA de votre CV',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Extraction automatique des compétences',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isAnalysing)
                ElevatedButton.icon(
                  icon: Icon(
                    _etapeActuelle == 4 ? Icons.refresh_rounded : Icons.play_arrow_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _etapeActuelle == 4 ? 'Réanalyser' : 'Lancer l\'analyse',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56DB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _lancer,
                ),
            ],
          ),
          if (_isAnalysing || _etapeActuelle >= 0) ...[
            const SizedBox(height: 16),
            ...List.generate(_etapes.length, (i) {
              final fait = i < _etapeActuelle;
              final enCours = i == _etapeActuelle;
              final attente = i > _etapeActuelle;

              return AnimatedOpacity(
                opacity: attente && _etapeActuelle >= 0 ? 0.4 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: fait
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                  key: ValueKey<String>('fait'),
                                )
                              : enCours
                                  ? FadeTransition(
                                      opacity: _dotAnim,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1A56DB),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.radio_button_unchecked,
                                      color: Color(0xFFCBD5E1),
                                      size: 20,
                                      key: ValueKey<String>('attente'),
                                    ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _etapes[i],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: fait || enCours ? FontWeight.w600 : FontWeight.w400,
                            color: fait
                                ? const Color(0xFF10B981)
                                : enCours
                                    ? const Color(0xFF1A56DB)
                                    : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          if (_message != null && !_isAnalysing) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _succes
                    ? const Color(0xFFECFDF5)
                    : _nbComps > 0
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _succes
                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                      : _nbComps > 0
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                          : const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _message!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _succes
                          ? const Color(0xFF065F46)
                          : _nbComps > 0
                              ? const Color(0xFF92400E)
                              : const Color(0xFF991B1B),
                    ),
                  ),
                  if (_succes) ...[
                    const SizedBox(height: 6),
                    Text(
                      '$_nbComps compétence(s) · $_nbExps expérience(s) · $_nbFmts formation(s)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                  ],
                  if (_conseil != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _conseil!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _succes ? const Color(0xFF065F46) : const Color(0xFF92400E),
                      ),
                    ),
                  ],
                  if (!_succes) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _ouvrirCreateurCv,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 13),
                            const SizedBox(width: 6),
                            Text(
                              'Créer mon CV depuis la plateforme',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
