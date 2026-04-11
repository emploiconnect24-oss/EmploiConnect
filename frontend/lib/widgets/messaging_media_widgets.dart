import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kMessagingPrimary = Color(0xFF1A56DB);

Future<void> openMessagingUrl(String? url) async {
  final u = Uri.tryParse(url ?? '');
  if (u != null && await canLaunchUrl(u)) {
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }
}

IconData messagingFileIcon(String ext) {
  switch (ext.toLowerCase()) {
    case 'pdf':
      return Icons.picture_as_pdf_rounded;
    case 'doc':
    case 'docx':
      return Icons.description_rounded;
    case 'xls':
    case 'xlsx':
    case 'csv':
      return Icons.table_chart_rounded;
    case 'zip':
    case 'rar':
    case '7z':
      return Icons.folder_zip_rounded;
    default:
      return Icons.insert_drive_file_rounded;
  }
}

/// Image seule : pas de bulle bleue — carte blanche ombrée (style apps modernes).
class MessagingStandaloneImage extends StatelessWidget {
  const MessagingStandaloneImage({
    super.key,
    required this.imageUrl,
    required this.isMine,
    this.messageId,
    this.onDelete,
    this.side = 216,
  });

  final String imageUrl;
  final bool isMine;
  final String? messageId;
  final Future<void> Function()? onDelete;
  final double side;

  @override
  Widget build(BuildContext context) {
    final showDelete = messageId != null &&
        messageId!.isNotEmpty &&
        onDelete != null;

    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            elevation: 3,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            child: InkWell(
              onTap: () => openMessagingUrl(imageUrl),
              borderRadius: BorderRadius.circular(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: side,
                  height: side,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFF1F5F9),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 40,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showDelete)
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () async {
                    await onDelete!();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Document PDF / Word / etc. — tuile carrée lisible, hors bulle colorée.
class MessagingFileSquareTile extends StatelessWidget {
  const MessagingFileSquareTile({
    super.key,
    required this.ext,
    required this.displayName,
    required this.isMine,
    required this.onDownload,
    this.messageId,
    this.onDelete,
  });

  final String ext;
  final String displayName;
  final bool isMine;
  final VoidCallback onDownload;
  final String? messageId;
  final Future<void> Function()? onDelete;

  static const double _side = 168;

  @override
  Widget build(BuildContext context) {
    final e = ext.isNotEmpty ? ext.toUpperCase() : 'FILE';
    final showDelete =
        messageId != null && messageId!.isNotEmpty && onDelete != null;

    return Material(
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: InkWell(
        onTap: onDownload,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: _side,
          height: _side,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isMine
                  ? [const Color(0xFFEFF6FF), const Color(0xFFF8FAFC)]
                  : [Colors.white, const Color(0xFFF8FAFC)],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    messagingFileIcon(ext),
                    size: 52,
                    color: kMessagingPrimary,
                  ),
                ),
              ),
              Text(
                e,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Télécharger',
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_rounded,
                        color: kMessagingPrimary, size: 22),
                  ),
                  if (showDelete)
                    IconButton(
                      tooltip: 'Supprimer',
                      onPressed: () async {
                        await onDelete!();
                      },
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444), size: 22),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Heure + statut lu sous contenu « hors bulle » (texte neutre).
Widget messagingMetaFooter({
  required String timeLabel,
  required bool isMine,
  bool showReadReceipt = false,
  bool isRead = false,
  Future<void> Function()? onDeleteForMine,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeLabel,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF94A3B8),
          ),
        ),
        if (isMine && showReadReceipt) ...[
          const SizedBox(width: 4),
          Icon(
            isRead ? Icons.done_all_rounded : Icons.done_rounded,
            size: 13,
            color: isRead ? kMessagingPrimary : const Color(0xFFCBD5E1),
          ),
        ],
        if (isMine && onDeleteForMine != null) ...[
          const SizedBox(width: 2),
          InkWell(
            onTap: () async {
              await onDeleteForMine();
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
