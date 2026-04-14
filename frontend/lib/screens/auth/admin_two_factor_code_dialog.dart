import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Saisie du code TOTP après le premier facteur (mot de passe ou Google).
Future<bool> showAdminTwoFactorCodeDialog(
  BuildContext context, {
  required Future<(bool ok, String? message)> Function(String code) submit,
}) async {
  final codeCtrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: Color(0xFF1A56DB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Code 2FA',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Entrez le code à 6 chiffres affiché dans votre application '
              '(Google Authenticator, Authy, etc.).',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 8,
              textAlign: TextAlign.center,
              autofocus: true,
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                labelText: 'Code',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1A56DB)),
            onPressed: () async {
              final (success, msg) = await submit(codeCtrl.text);
              if (!ctx.mounted) return;
              if (success) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(msg ?? 'Code invalide')),
                );
              }
            },
            child: const Text('Valider'),
          ),
        ],
      );
    },
  );
  codeCtrl.dispose();
  return ok == true;
}
