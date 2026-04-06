import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class ImageUploadWidget extends StatefulWidget {
  const ImageUploadWidget({
    super.key,
    this.currentImageUrl,
    required this.uploadUrl,
    required this.fieldName,
    required this.title,
    required this.dimensionsInfo,
    required this.acceptedFormats,
    required this.maxSizeMb,
    required this.previewHeight,
    required this.onUploaded,
  });

  final String? currentImageUrl;
  final String uploadUrl;
  final String fieldName;
  final String title;
  final String dimensionsInfo;
  final String acceptedFormats;
  final int maxSizeMb;
  final double previewHeight;
  final void Function(String url) onUploaded;

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  bool _isUploading = false;
  String? _localPreviewUrl;

  @override
  Widget build(BuildContext context) {
    final displayUrl = _localPreviewUrl ?? widget.currentImageUrl ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayUrl.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Actuel :',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              if (_localPreviewUrl != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Non sauvegardé',
                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF92400E)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Image.network(
                displayUrl,
                height: widget.previewHeight,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8), size: 32),
                    Text(
                      'Impossible de charger l\'image',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        GestureDetector(
          onTap: _isUploading ? null : _pickAndUpload,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: _isUploading ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isUploading
                    ? const Color(0xFF1A56DB)
                    : const Color(0xFF1A56DB).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                if (_isUploading) ...[
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(color: Color(0xFF1A56DB), strokeWidth: 2.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Upload en cours...',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A56DB)),
                  ),
                ] else ...[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.upload_file_outlined, color: Color(0xFF1A56DB), size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    displayUrl.isNotEmpty
                        ? 'Cliquer pour remplacer ${widget.title.toLowerCase()}'
                        : 'Cliquer pour choisir ${widget.title.toLowerCase()}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A56DB),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.acceptedFormats} · Max ${widget.maxSizeMb}MB',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.straighten_outlined, size: 14, color: Color(0xFFF59E0B)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dimensions recommandées : ${widget.dimensionsInfo}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                              color: const Color(0xFF92400E),
                            ),
                            softWrap: true,
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
      ],
    );
  }

  Future<void> _pickAndUpload() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final sizeMb = bytes.length / (1024 * 1024);
      if (sizeMb > widget.maxSizeMb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fichier trop volumineux (${sizeMb.toStringAsFixed(1)}MB). Max: ${widget.maxSizeMb}MB',
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        return;
      }

      setState(() => _isUploading = true);

      final token = context.read<AuthProvider>().token ?? '';
      final request = http.MultipartRequest('POST', Uri.parse(widget.uploadUrl));
      request.headers['Authorization'] = 'Bearer $token';

      final ext = file.path.split('.').last.toLowerCase();
      var mime = 'image/jpeg';
      if (ext == 'png') mime = 'image/png';
      if (ext == 'webp') mime = 'image/webp';
      if (ext == 'svg') mime = 'image/svg+xml';

      request.files.add(
        http.MultipartFile.fromBytes(
          widget.fieldName,
          bytes,
          filename: 'upload.$ext',
          contentType: MediaType.parse(mime),
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final data = (body['data'] is Map) ? Map<String, dynamic>.from(body['data'] as Map) : {};
        final newUrl = (data['logo_url'] ?? data['banniere_url'] ?? data['image_url'] ?? '').toString();
        if (newUrl.isEmpty) throw Exception('URL image absente dans la réponse');

        setState(() {
          _localPreviewUrl = newUrl;
          _isUploading = false;
        });
        widget.onUploaded(newUrl);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.title} uploadé avec succès'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        throw Exception(body['message']?.toString() ?? 'Erreur upload');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
