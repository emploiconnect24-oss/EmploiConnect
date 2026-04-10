import 'package:flutter/material.dart';

class ApplyBottomSheet extends StatefulWidget {
  const ApplyBottomSheet({
    super.key,
    required this.offerTitle,
    this.onSubmit,
  });

  final String offerTitle;
  final Future<void> Function(String motivation)? onSubmit;

  @override
  State<ApplyBottomSheet> createState() => _ApplyBottomSheetState();
}

class _ApplyBottomSheetState extends State<ApplyBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _motivationCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _motivationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit?.call(_motivationCtrl.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final len = _motivationCtrl.text.trim().length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: scrollCtrl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Postuler à cette offre', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(widget.offerTitle, style: const TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Lettre de motivation', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'Obligatoire',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Minimum 100 caractères, maximum 4000.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _motivationCtrl,
                    maxLines: 8,
                    maxLength: 4000,
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) {
                        return 'La lettre de motivation est obligatoire';
                      }
                      if (t.length < 100) {
                        return 'Minimum 100 caractères (${t.length}/100)';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Présentez-vous et expliquez votre adéquation au poste…',
                      isDense: true,
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$len/4000 ${len >= 100 ? "✓" : "(min. 100)"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: len >= 100 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_submitting || len < 100) ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_outlined, size: 18),
                      label: Text(_submitting ? 'Envoi...' : 'Envoyer ma candidature'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
