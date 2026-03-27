import 'package:flutter/material.dart';

import 'widgets/footer_widget.dart';
import 'widgets/hero_section_widget.dart';
import 'widgets/navbar_widget.dart';
import 'widgets/platform_section_widget.dart';
import 'widgets/recent_jobs_section_widget.dart';
import 'widgets/solutions_section_widget.dart';
import 'widgets/tips_carousel_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final next = _scrollController.offset > 10;
    if (next != _isScrolled) {
      setState(() => _isScrolled = next);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Accueil'),
                onTap: () => Navigator.of(context).pushNamed('/landing'),
              ),
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: const Text("Offres d'emploi"),
                onTap: () => Navigator.of(context).pushNamed('/landing'),
              ),
              ListTile(
                leading: const Icon(Icons.login_outlined),
                title: const Text('Connexion'),
                onTap: () => Navigator.of(context).pushNamed('/login'),
              ),
              ListTile(
                leading: const Icon(Icons.person_add_outlined),
                title: const Text('Inscription'),
                onTap: () => Navigator.of(context).pushNamed('/register'),
              ),
            ],
          ),
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: NavbarWidget(isScrolled: _isScrolled),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: const Column(
          children: [
            HeroSectionWidget(),
            PlatformSectionWidget(),
            TipsCarouselWidget(),
            SolutionsSectionWidget(),
            RecentJobsSectionWidget(),
            FooterWidget(),
          ],
        ),
      ),
    );
  }
}

