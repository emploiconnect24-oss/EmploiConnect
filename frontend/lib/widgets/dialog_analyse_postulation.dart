import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class DialogAnalysePostulation extends StatefulWidget {
  const DialogAnalysePostulation({
    super.key,
    required this.offreId,
    required this.offreTitre,
    required this.onConfirmerPostulation,
  });

  final String offreId;
  final String offreTitre;
  final VoidCallback onConfirmerPostulation;

  @override
  State<DialogAnalysePostulation> createState() => _DialogAnalysePostulationState();
}

class _DialogAnalysePostulationState extends State<DialogAnalysePostulation> {
  Map<String, dynamic>? _analyse;
  bool _isLoading = true;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _chargerAnalyse();
  }

  Future<void> _chargerAnalyse() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      debugPrint('[dialog] Chargement analyse pour: ${widget.offreId}');

      final res = await http
          .get(
            Uri.parse('$apiBaseUrl/api/candidat/offres/${widget.offreId}/analyse'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('[dialog] Status: ${res.statusCode}');
      final preview = res.body.substring(0, min(200, res.body.length));
      debugPrint('[dialog] Body: $preview');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        debugPrint('[dialog] Success: ${body['success']}');
        debugPrint('[dialog] Data: ${body['data']}');
        if (mounted) {
          setState(() {
            final data = body['data'];
            if (data is Map) {
              _analyse = Map<String, dynamic>.from(data);
            } else {
              _analyse = null;
            }
            _isLoading = false;
          });
        }
      } else {
        debugPrint('[dialog] Erreur HTTP: ${res.statusCode}');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('[dialog] Exception: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = (_analyse?['score'] as num?)?.toInt();
    Color couleur = const Color(0xFF64748B);
    String titre = 'Analyse en cours';
    String emoji = '🤔';
    if (score != null) {
      if (score >= 80) {
        couleur = const Color(0xFF10B981);
        titre = 'Excellent match';
        emoji = '🎯';
      } else if (score >= 60) {
        couleur = const Color(0xFFF59E0B);
        titre = 'Bonne compatibilite';
        emoji = '👍';
      } else if (score >= 40) {
        couleur = const Color(0xFFF97316);
        titre = 'Compatibilite moyenne';
        emoji = '⚠️';
      } else {
        couleur = const Color(0xFFEF4444);
        titre = 'Faible compatibilite';
        emoji = '❗';
      }
    }

    final pointsForts = (_analyse?['points_forts'] as List?)?.cast<dynamic>() ?? const [];
    final pointsFaibles = (_analyse?['points_faibles'] as List?)?.cast<dynamic>() ?? const [];
    final conseils = (_analyse?['conseils'] as List?)?.cast<dynamic>() ?? const [];
    final recommandeParcours = _analyse?['recommande_parcours'] == true;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: couleur,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        if (score != null)
                          Text('$score% de compatibilite', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(),
                      ))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.offreTitre, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          if ((_analyse?['message_court'] as String?)?.isNotEmpty == true)
                            Text(_analyse!['message_court'] as String),
                          _blocListe('Points forts', pointsForts, const Color(0xFF10B981)),
                          _blocListe('Points a ameliorer', pointsFaibles, const Color(0xFFF59E0B)),
                          _blocListe('Conseils IA', conseils, const Color(0xFF1A56DB)),
                          if (recommandeParcours)
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFD8B4FE)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.school_outlined, color: Color(0xFF7C3AED), size: 18),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text('Parcours Carriere recommande pour ameliorer vos chances.'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.go('/dashboard/parcours');
                                    },
                                    child: const Text('Voir'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isPosting
                          ? null
                          : () {
                              setState(() => _isPosting = true);
                              Navigator.pop(context);
                              widget.onConfirmerPostulation();
                            },
                      icon: _isPosting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, size: 16),
                      label: Text(score != null && score < 40 ? 'Postuler quand meme' : 'Postuler maintenant'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blocListe(String titre, List<dynamic> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right_rounded, color: color, size: 16),
                    const SizedBox(width: 3),
                    Expanded(child: Text(e.toString())),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
