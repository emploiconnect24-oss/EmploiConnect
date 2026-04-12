import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/footer_widget.dart';
import 'widgets/home_admin_banniere_strip.dart';
import 'widgets/home_cta_section.dart';
import 'widgets/home_header_widget.dart';
import 'widgets/home_hero_prd_section.dart';
import 'widgets/home_illustration_section.dart';
import 'widgets/home_pub_bannieres_section.dart';
import 'widgets/home_solutions_prd_section.dart';
import 'widgets/home_stats_section.dart';
import 'widgets/home_temoignages_section.dart';
import 'widgets/recent_jobs_section_widget.dart';
import 'widgets/top_entreprises_marquee_section_widget.dart';
import 'widgets/ticker_bannieres_widget.dart';

/// Accueil : header overlay, ticker, hero, stats, solutions, offres, entreprises, illustration, témoignages, CTA, footer, admin.
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onOpenMenu});

  final VoidCallback? onOpenMenu;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  List<Map<String, dynamic>> _temoignages = const [];
  HomepageStatsSnapshot? _homepageStats;

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTemoignages();
    _loadHomepageStats();
  }

  Future<void> _loadHomepageStats() async {
    HomepageStatsSnapshot? next;
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl$apiPrefix/stats/homepage'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final data = map['data'];
        if (data is Map) {
          next = HomepageStatsSnapshot(
            entreprises: _asInt(data['entreprises']),
            candidats: _asInt(data['candidats']),
            offres: _asInt(data['offres']),
            satisfaction: _asInt(data['satisfaction']).clamp(0, 100),
          );
        }
      }
    } catch (_) {
      // garde next null → repli 0 ci-dessous
    }
    next ??= const HomepageStatsSnapshot(
      entreprises: 0,
      candidats: 0,
      offres: 0,
      satisfaction: 0,
    );
    if (!mounted) return;
    setState(() => _homepageStats = next);
  }

  void _onScroll() {
    final next = _scrollController.offset > 12;
    if (next != _isScrolled && mounted) {
      setState(() => _isScrolled = next);
    }
  }

  Future<void> _loadTemoignages() async {
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl$apiPrefix/temoignages/public?limit=12'))
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final data = map['data'];
        if (data is List) {
          final mapped = data.map<Map<String, dynamic>>((e) {
            final row = Map<String, dynamic>.from(e as Map);
            return {
              'nom': row['candidat_nom'] ?? 'Candidat',
              'poste': row['entreprise_nom'] ?? 'Entreprise',
              'photo': row['candidat_photo_url'],
              'message': row['message'] ?? '',
            };
          }).toList();
          setState(() => _temoignages = mapped);
          return;
        }
      }
    } catch (_) {
      // garde liste vide
    }
  }

  static bool _isTicker(Map<String, dynamic> b) {
    final t = (b['type_banniere'] ?? 'hero').toString().toLowerCase().trim();
    return t == 'ticker';
  }

  static bool _isHero(Map<String, dynamic> b) {
    final t = (b['type_banniere'] ?? 'hero').toString().toLowerCase().trim();
    if (t == 'pub') return false;
    return t == 'hero' || t.isEmpty;
  }

  static bool _isPub(Map<String, dynamic> b) {
    return (b['type_banniere'] ?? '').toString().toLowerCase().trim() == 'pub';
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    const headerBar = 72.0;

    return Consumer<AppConfigProvider>(
      builder: (context, cfg, _) {
        final all = cfg.bannieres;
        final ticker = all.where(_isTicker).toList();
        final hero = all.where(_isHero).toList();
        final pub = all.where(_isPub).toList();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: topInset + headerBar),
                      TickerBannieresWidget(bannieres: ticker),
                      HomeHeroPrdSection(bannieres: hero),
                      HomeStatsSection(
                        statsSnapshot: _homepageStats,
                        expectParentStats: true,
                      ),
                      const HomeSolutionsPrdSection(),
                      const RecentJobsSectionWidget(
                        backgroundColor: Colors.white,
                        homepageV2Gradient: false,
                      ),
                      const TopEntreprisesMarqueeSectionWidget(),
                      HomePubBannieresSection(bannieres: pub),
                      const HomeIllustrationSection(),
                      HomeTemoignagesSection(temoignages: _temoignages),
                      const HomeCtaSection(),
                      const FooterWidget(),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          if (auth.role != 'admin') return const SizedBox.shrink();
                          return const HomeAdminBanniereStrip();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: HomeHeaderWidget(
                  isScrolled: _isScrolled,
                  onOpenMenu: widget.onOpenMenu,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
