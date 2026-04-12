import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../config/api_config.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/admin_service.dart';

/// Bloc « Illustration homepage » — Paramètres → IA (PRD v9.3).
class IllustrationIaSettingsWidget extends StatefulWidget {
  const IllustrationIaSettingsWidget({super.key});

  @override
  State<IllustrationIaSettingsWidget> createState() => _IllustrationIaSettingsWidgetState();
}

class _IllustrationIaSettingsWidgetState extends State<IllustrationIaSettingsWidget> {
  final _admin = AdminService();

  bool _iaActif = false;
  String _nbParJour = '4';
  String _urlManuelle = '';
  bool _isUploading = false;
  bool _isGenerating = false;
  String? _previewUrl;
  List<Map<String, dynamic>> _illustrations = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadIllustrations();
  }

  Future<void> _loadConfig() async {
    try {
      final res = await _admin.getParametres(categorie: 'ia');
      final data = res['data'] as Map<String, dynamic>?;
      final ia = data?['ia'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        final actifRaw = ia?['illustration_ia_actif']?['valeur'];
        _iaActif = actifRaw == true || actifRaw == 'true';
        final nb = ia?['illustration_nb_par_jour']?['valeur'];
        _nbParJour = nb != null ? '$nb' : '4';
        final url = ia?['illustration_url_manuelle']?['valeur'];
        _urlManuelle = url != null ? '$url' : '';
        if (_urlManuelle.isNotEmpty) _previewUrl = _urlManuelle;
      });
    } catch (_) {}
  }

  Future<void> _loadIllustrations() async {
    try {
      final body = await _admin.getIllustrationsIaListe();
      final raw = body['data'];
      final list = raw is List
          ? List<Map<String, dynamic>>.from(raw.map((e) => Map<String, dynamic>.from(e as Map)))
          : <Map<String, dynamic>>[];
      if (mounted) setState(() => _illustrations = list);
    } catch (_) {
      if (mounted) setState(() => _illustrations = []);
    }
  }

  Future<void> _saveParam(String cle, String valeur) async {
    try {
      await _admin.updateParametres([
        {'cle': cle, 'valeur': valeur},
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur sauvegarde : $e', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _choisirImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) return;
      if (!mounted) return;
      final token = context.read<AuthProvider>().token ?? '';

      setState(() => _isUploading = true);
      final uri = Uri.parse('$apiBaseUrl$apiPrefix/illustration/upload-manuel');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          file.bytes!,
          filename: file.name.isNotEmpty ? file.name : 'illustration.png',
        ),
      );
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (!mounted) return;
      if (body['success'] == true && body['data'] is Map) {
        final url = (body['data'] as Map)['url'] as String?;
        if (url != null) {
          setState(() {
            _urlManuelle = url;
            _previewUrl = url;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image uploadée', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          await _loadIllustrations();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message']?.toString() ?? 'Échec upload', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur upload : $e', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _generer() async {
    setState(() => _isGenerating = true);
    try {
      final body = await _admin.postIllustrationGenerer();
      if (!mounted) return;
      if (body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${body['nb_generees'] ?? 0} image(s) générée(s)',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadIllustrations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message']?.toString() ?? 'Erreur', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _activerIllustration(String id) async {
    try {
      await _admin.patchIllustrationActiver(id);
      if (mounted) await _loadIllustrations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur activation : $e', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Génération IA automatique (DALL-E)',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    'Cron serveur + clé OpenAI (même clé que ChatGPT ci-dessus).',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            Switch(
              value: _iaActif,
              onChanged: (v) {
                setState(() => _iaActif = v);
                _saveParam('illustration_ia_actif', v ? 'true' : 'false');
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF92400E), size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Coût indicatif DALL-E 3 : ~0,04 USD / image. Nécessite une clé OpenAI valide.',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E), height: 1.4),
                ),
              ),
            ],
          ),
        ),
        if (_iaActif) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Images générées par jour',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
              ),
              DropdownButton<String>(
                value: _nbParJour,
                underline: const SizedBox(),
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                items: ['2', '4', '6', '8', '10']
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text('$v / jour', style: GoogleFonts.inter()),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _nbParJour = v);
                    _saveParam('illustration_nb_par_jour', v);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isGenerating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text(
                _isGenerating ? 'Génération…' : 'Générer maintenant',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isGenerating ? null : _generer,
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 12),
        Text(
          'Image manuelle (fichier)',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
        ),
        const SizedBox(height: 4),
        Text(
          'PNG, JPG ou WebP. L’image est stockée sur le bucket public et enregistrée comme illustration active.',
          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _previewUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.network(
                        _previewUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Color(0xFFCBD5E1)),
                      ),
                    )
                  : const Icon(Icons.image_outlined, color: Color(0xFFCBD5E1), size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: _isUploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A56DB)),
                            )
                          : const Icon(Icons.upload_file_rounded, size: 16),
                      label: Text(
                        _isUploading ? 'Upload…' : 'Choisir une image',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1A56DB)),
                        foregroundColor: const Color(0xFF1A56DB),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isUploading ? null : _choisirImage,
                    ),
                  ),
                  if (_urlManuelle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        await _saveParam('illustration_url_manuelle', '');
                        setState(() {
                          _urlManuelle = '';
                          _previewUrl = null;
                        });
                      },
                      child: Text(
                        'Supprimer l’URL manuelle (paramètre)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (_illustrations.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          Text(
            'Images générées / historique',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _illustrations.take(8).map((illus) {
              final isActive = illus['est_active'] == true;
              final id = illus['id']?.toString() ?? '';
              final url = illus['url_image']?.toString() ?? '';
              return GestureDetector(
                onTap: id.isEmpty ? null : () => _activerIllustration(id),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                      width: isActive ? 2.5 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(
                          url,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Color(0xFFCBD5E1)),
                        ),
                      ),
                      if (isActive)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                            child: Icon(Icons.check, color: Colors.white, size: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            'Appuyez sur une vignette pour l’activer sur la homepage.',
            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
          ),
        ],
      ],
    );
  }
}
