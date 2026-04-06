import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/app_config_provider.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({
    super.key,
    this.height = 36,
    this.fallbackTextColor,
    this.fallbackAccentColor,
  });

  final double height;
  final Color? fallbackTextColor;
  final Color? fallbackAccentColor;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppConfigProvider>(
      builder: (ctx, config, _) {
        final logoUrl = config.logoUrl.trim();
        if (logoUrl.isNotEmpty) {
          return Image.network(
            '$logoUrl?v=${logoUrl.hashCode}',
            height: height,
            fit: BoxFit.contain,
            headers: const {'Cache-Control': 'no-cache'},
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return _buildTextLogo(context);
            },
            errorBuilder: (context, error, stackTrace) =>
                _buildTextLogo(context),
          );
        }
        return _buildTextLogo(context);
      },
    );
  }

  Widget _buildTextLogo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Emploi',
            style: GoogleFonts.poppins(
              fontSize: height * 0.55,
              fontWeight: FontWeight.w800,
              color:
                  fallbackTextColor ??
                  (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          TextSpan(
            text: 'Connect',
            style: GoogleFonts.poppins(
              fontSize: height * 0.55,
              fontWeight: FontWeight.w800,
              color: fallbackAccentColor ?? const Color(0xFF1A56DB),
            ),
          ),
        ],
      ),
    );
  }
}
