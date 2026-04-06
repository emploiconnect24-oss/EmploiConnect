import 'dart:async';
import 'package:flutter/material.dart';
import 'typewriter_text.dart';

class CarouselBanner extends StatefulWidget {
  const CarouselBanner({
    super.key,
    required this.messages,
    this.height,
    this.fullBleed = false,
  });

  final List<BannerMessage> messages;
  final double? height;
  final bool fullBleed;

  @override
  State<CarouselBanner> createState() => _CarouselBannerState();
}

class _CarouselBannerState extends State<CarouselBanner> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || widget.messages.isEmpty) return;
      _index = (_index + 1) % widget.messages.length;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final messages = widget.messages;
    if (messages.isEmpty) return const SizedBox.shrink();

    final bh = widget.height;
    final compact = bh != null && bh <= 300;
    final pad = compact ? 12.0 : 22.0;
    final boxSide = compact ? 76.0 : 160.0;
    final iconSz = compact ? 34.0 : 72.0;
    final titleFs = compact ? 17.0 : 26.0;
    final twFs = compact ? 12.5 : 16.0;
    final subFs = compact ? 11.0 : 14.0;
    final brBox = compact ? 14.0 : 24.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.fullBleed ? 22 : 18),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: messages.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final m = messages[i];
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        m.start,
                        m.end,
                      ],
                    ),
                  ),
                  // Images réelles : pour l’instant on garde un gradient.
                  // Quand vous aurez des assets, on pourra activer l’image par bannière.
                  child: Padding(
                    padding: EdgeInsets.all(pad),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.title,
                                style: TextStyle(
                                  fontSize: titleFs,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: compact ? 6 : 10),
                              TypewriterText(
                                texts: m.typewriter,
                                textStyle: TextStyle(
                                  fontSize: twFs,
                                  height: 1.35,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: compact ? 6 : 14),
                              Text(
                                m.subtitle,
                                style: TextStyle(
                                  fontSize: subFs,
                                  height: 1.3,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                                maxLines: compact ? 2 : 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: compact ? 8 : 12),
                        Container(
                          width: boxSide,
                          height: boxSide,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(brBox),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Icon(
                            m.icon,
                            size: iconSz,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: List.generate(
                        messages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 6),
                          height: 8,
                          width: i == _index ? 22 : 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: i == _index ? 0.95 : 0.45),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      'Publicités / bannières',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BannerMessage {
  const BannerMessage({
    required this.title,
    required this.typewriter,
    required this.subtitle,
    required this.icon,
    required this.start,
    required this.end,
  });

  final String title;
  final List<String> typewriter;
  final String subtitle;
  final IconData icon;
  final Color start;
  final Color end;
}

/// Bannières par défaut (tu pourras les remplacer par des pubs plus tard)
List<BannerMessage> defaultBanners() => const [
      BannerMessage(
        title: 'Trouvez l’offre qui vous correspond',
        typewriter: [
          'Matching intelligent CV ↔ offres…',
          'Suggestions personnalisées en quelques secondes…',
        ],
        subtitle: 'Centralisez vos candidatures, suivez vos statuts et gagnez du temps.',
        icon: Icons.auto_awesome,
        start: Color(0xFF1F6FEB),
        end: Color(0xFF00A3FF),
      ),
      BannerMessage(
        title: 'Recrutez plus vite et mieux',
        typewriter: [
          'Publiez une offre en quelques clics…',
          'Recevez et triez les candidatures…',
        ],
        subtitle: 'Un espace recruteur simple, clair et efficace pour gérer vos annonces.',
        icon: Icons.apartment,
        start: Color(0xFF0B4DB5),
        end: Color(0xFFFF8A00),
      ),
      BannerMessage(
        title: 'Une plateforme modérée et fiable',
        typewriter: [
          'Validation des comptes…',
          'Signalements et suivi…',
        ],
        subtitle: 'L’administrateur supervise les contenus et garantit la conformité.',
        icon: Icons.verified_user,
        start: Color(0xFF0F6D2B),
        end: Color(0xFF1F6FEB),
      ),
    ];

