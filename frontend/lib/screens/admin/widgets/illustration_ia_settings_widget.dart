import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final _illustrationPromptCtrl = TextEditingController();
  final _geminiKeyCtrl = TextEditingController();

  bool _iaActif = false;
  String _provider = 'dalle';
  String _geminiModele = 'auto';
  String _nbParJour = '4';
  String _urlManuelle = '';
  bool _isUploading = false;
  bool _isGenerating = false;
  bool _isTestingGemini = false;
  bool _testGeminiOk = false;
  String? _testGeminiResultat;
  String? _previewUrl;
  List<Map<String, dynamic>> _illustrations = [];

  @override
  void dispose() {
    _illustrationPromptCtrl.dispose();
    _geminiKeyCtrl.dispose();
    super.dispose();
  }

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
        _illustrationPromptCtrl.text =
            ia?['illustration_prompt_base']?['valeur']?.toString() ?? '';
        _provider = ia?['illustration_provider']?['valeur']?.toString() == 'gemini' ? 'gemini' : 'dalle';
        _geminiModele = ia?['gemini_modele']?['valeur']?.toString() ?? 'auto';
        final geminiKey = ia?['gemini_api_key']?['valeur']?.toString() ?? '';
        _geminiKeyCtrl.text = geminiKey.isNotEmpty ? '********' : '';
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
      if (file.bytes == null || file.bytes!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de lire le fichier (réessayez ou choisissez un autre fichier).', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (!mounted) return;
      final token = context.read<AuthProvider>().token ?? '';

      setState(() => _isUploading = true);
      final uri = Uri.parse('$apiBaseUrl$apiPrefix/illustration/upload-manuel');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final name = file.name.isNotEmpty ? file.name : 'illustration.png';
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'png';
      const mimeByExt = {
        'png': 'image/png',
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'webp': 'image/webp',
      };
      final mimeType = mimeByExt[ext] ?? 'image/png';

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          file.bytes!,
          filename: name,
          contentType: MediaType.parse(mimeType),
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

  Future<void> _testerGemini() async {
    if (_geminiKeyCtrl.text.trim().isEmpty || _geminiKeyCtrl.text.trim() == '********') {
      setState(() {
        _testGeminiOk = false;
        _testGeminiResultat = 'Entrez la cle Gemini d abord';
      });
      return;
    }
    setState(() {
      _isTestingGemini = true;
      _testGeminiResultat = null;
    });
    try {
      await _saveParam('gemini_api_key', _geminiKeyCtrl.text.trim());
      await _saveParam('gemini_modele', _geminiModele);
      final body = await _admin.postTestGeminiImage();
      if (!mounted) return;
      setState(() {
        _testGeminiOk = body['success'] == true;
        _testGeminiResultat = body['success'] == true
            ? 'Gemini Image operationnel !'
            : '${body['message'] ?? 'Erreur test Gemini'}';
        _geminiKeyCtrl.text = '********';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testGeminiOk = false;
        _testGeminiResultat = 'Erreur: $e';
      });
    } finally {
      if (mounted) setState(() => _isTestingGemini = false);
    }
  }

  Future<void> _confirmerSuppression(String id, bool isActive) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
            const SizedBox(width: 8),
            Text(
              'Supprimer l image ?',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          isActive
              ? 'Cette image est actuellement active sur la homepage. Elle sera remplacee.'
              : 'Cette image sera supprimee definitivement.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _supprimerIllustration(id);
    }
  }

  Future<void> _supprimerIllustration(String id) async {
    try {
      final body = await _admin.deleteIllustration(id);
      if (!mounted) return;
      if (body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image supprimee'),
            backgroundColor: Color(0xFF64748B),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadIllustrations();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                    'Generation IA automatique',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    'Cron serveur + provider image configurable (DALL-E ou Gemini).',
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
                  _provider == 'gemini'
                      ? 'Gemini: usage gratuit (quota AI Studio), cle Google requise.'
                      : 'Cout indicatif DALL-E 3: ~0,04 USD/image HD, cle OpenAI requise.',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Generateur d images',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
              ),
              DropdownButton<String>(
                value: _provider,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'dalle',
                    child: Text('DALL-E 3 (OpenAI)'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'gemini',
                    child: Text('Gemini (Google)'),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _provider = v);
                  _saveParam('illustration_provider', v);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _provider == 'gemini' ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _provider == 'gemini'
                  ? 'Gemini: gratuit (quota) - cle Google AI Studio requise.'
                  : 'DALL-E 3: qualite HD - cle OpenAI requise.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _provider == 'gemini' ? const Color(0xFF065F46) : const Color(0xFF1E40AF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _provider == 'gemini'
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _geminiKeyCtrl,
                          obscureText: _geminiKeyCtrl.text == '********',
                          decoration: InputDecoration(
                            labelText: 'Cle API Google Gemini',
                            hintText: 'AIzaSy-xxxxxxxxxxxxx',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => launchUrl(Uri.parse('https://aistudio.google.com/apikey')),
                          child: Text(
                            'Obtenir une cle gratuite sur aistudio.google.com',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Modele Gemini',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF374151),
                              ),
                            ),
                            DropdownButton<String>(
                              value: _geminiModele,
                              underline: const SizedBox(),
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A)),
                              items: const [
                                DropdownMenuItem<String>(
                                  value: 'auto',
                                  child: Text('Auto (recommande)'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'flash-image',
                                  child: Text('Gemini Flash Image'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'imagen-3',
                                  child: Text('Imagen 4 (haute qualite)'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _geminiModele = v);
                                _saveParam('gemini_modele', v);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _geminiModele == 'auto'
                              ? 'Essaie automatiquement le meilleur modele disponible (gemini-2.5-flash-image en priorite).'
                              : _geminiModele == 'flash-image'
                                  ? 'gemini-2.5-flash-image : rapide et gratuit.'
                                  : 'Imagen 4 : meilleure qualite portrait 9:16.',
                          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: _isTestingGemini
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.play_arrow_rounded, size: 16),
                            label: Text(
                              _isTestingGemini ? 'Test Gemini...' : 'Tester Gemini Image',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF10B981)),
                              foregroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isTestingGemini ? null : _testerGemini,
                          ),
                        ),
                        if (_testGeminiResultat != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _testGeminiOk ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _testGeminiResultat!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _testGeminiOk ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
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
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF8B5CF6), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Prompt personnalise pour les affiches',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Votre prompt guide le style general, mais chaque image reste unique grace a la rotation automatique des 8 styles.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              const exemple =
                  'Genere une affiche publicitaire verticale professionnelle pour EmploiConnect, '
                  'la plateforme N1 de l emploi en Guinee. Style marketing africain moderne, '
                  'couleurs bleu vif et blanc, personne africaine professionnelle souriante, '
                  'texte en francais, format portrait 9:16, qualite haute definition. '
                  'Chaque affiche doit etre unique avec une composition differente.';
              setState(() => _illustrationPromptCtrl.text = exemple);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF1A56DB).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: Color(0xFF1A56DB), size: 12),
                  const SizedBox(width: 6),
                  Text(
                    'Utiliser un exemple de prompt',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A56DB),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _illustrationPromptCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Ex: Affiche verticale EmploiConnect, style africain moderne, bleu/blanc...',
              hintStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFCBD5E1)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded, size: 14),
                  label: const Text('Reinitialiser'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _illustrationPromptCtrl.text = '');
                    await _saveParam('illustration_prompt_base', '');
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Prompt reinitialise (mode auto)', style: GoogleFonts.inter()),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded, size: 14),
                  label: const Text('Sauvegarder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _saveParam('gemini_modele', _geminiModele);
                    if (_geminiKeyCtrl.text.trim().isNotEmpty && _geminiKeyCtrl.text.trim() != '********') {
                      await _saveParam('gemini_api_key', _geminiKeyCtrl.text.trim());
                      if (mounted) setState(() => _geminiKeyCtrl.text = '********');
                    }
                    await _saveParam('illustration_prompt_base', _illustrationPromptCtrl.text.trim());
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Prompt sauvegarde'),
                        backgroundColor: Color(0xFF8B5CF6),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
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
                          left: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                            child: Icon(Icons.check, color: Colors.white, size: 12),
                          ),
                        ),
                      if (id.isNotEmpty)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _confirmerSuppression(id, isActive),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (illus['source']?.toString().trim().isNotEmpty ?? false)
                                ? illus['source'].toString()
                                : 'ia',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
