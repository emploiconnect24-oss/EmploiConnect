import 'package:flutter/material.dart';

class CandidatTipsResourcesScreen extends StatefulWidget {
  const CandidatTipsResourcesScreen({super.key});

  @override
  State<CandidatTipsResourcesScreen> createState() => _CandidatTipsResourcesScreenState();
}

class _CandidatTipsResourcesScreenState extends State<CandidatTipsResourcesScreen> {
  String _activeCategory = 'Toutes';
  final Map<String, bool> _checklist = <String, bool>{
    'Vérifier son CV avant chaque candidature': true,
    'Personnaliser la lettre de motivation': true,
    'Se renseigner sur l’entreprise': false,
    'Préparer des questions pour l’entretien': false,
    'Relancer après 1 semaine sans réponse': false,
  };

  static const _categories = <String>[
    'Toutes',
    'CV & Lettre',
    'Entretien',
    'Recherche emploi',
    'Négociation salaire',
    'Reconversion',
    'Entrepreneuriat',
  ];

  static final _articles = <_Article>[
    _Article(
      title: '10 astuces pour un CV qui décroche des entretiens',
      summary: 'Optimisez la structure, les mots-clés et la mise en valeur de vos réalisations.',
      category: 'CV & Lettre',
      readTime: '6 min',
    ),
    _Article(
      title: 'Réussir son entretien technique en 5 étapes',
      summary: 'Préparez vos réponses, votre démonstration et vos questions de fin.',
      category: 'Entretien',
      readTime: '8 min',
    ),
    _Article(
      title: 'Trouver plus vite un emploi avec une stratégie hebdo',
      summary: 'Planifiez vos candidatures, relances et améliorations de profil chaque semaine.',
      category: 'Recherche emploi',
      readTime: '7 min',
    ),
    _Article(
      title: 'Comment négocier son salaire sans se pénaliser',
      summary: 'Positionnez une fourchette réaliste et défendez votre valeur avec des preuves.',
      category: 'Négociation salaire',
      readTime: '5 min',
    ),
    _Article(
      title: 'Changer de carrière: par où commencer ?',
      summary: 'Identifiez vos compétences transférables et bâtissez un plan d’apprentissage.',
      category: 'Reconversion',
      readTime: '9 min',
    ),
    _Article(
      title: 'Se lancer en freelance: les fondamentaux',
      summary: 'Clarifiez votre offre, votre tarification et votre approche commerciale.',
      category: 'Entrepreneuriat',
      readTime: '6 min',
    ),
  ];

  static final _videos = <_Video>[
    _Video(title: 'Pitch de présentation en 60 secondes', duration: '04:31'),
    _Video(title: 'Top 7 des erreurs en entretien', duration: '06:18'),
    _Video(title: 'Optimiser son profil LinkedIn', duration: '05:42'),
    _Video(title: 'Répondre aux questions pièges', duration: '07:02'),
  ];

  List<_Article> get _filteredArticles {
    if (_activeCategory == 'Toutes') return _articles;
    return _articles.where((a) => a.category == _activeCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pagePad = EdgeInsets.fromLTRB(
      20,
      16,
      20,
      MediaQuery.of(context).size.width <= 900 ? 80 : 24,
    );
    return ListView(
      padding: pagePad,
      children: [
        const Text('Conseils & Ressources', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text(
          'Découvrez des contenus pratiques pour améliorer votre candidature et accélérer votre recherche.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),
        _featuredCard(),
        const SizedBox(height: 16),
        const Text('Catégories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories
              .map(
                (c) => ChoiceChip(
                  label: Text(c),
                  selected: _activeCategory == c,
                  onSelected: (_) => setState(() => _activeCategory = c),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Articles récents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${_filteredArticles.length} article(s)', style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (_, c) {
            int columns = 1;
            if (c.maxWidth >= 1150) {
              columns = 3;
            } else if (c.maxWidth >= 760) {
              columns = 2;
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredArticles.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: 1.22,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (_, i) => _ConseilCard(article: _filteredArticles[i]),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text('Vidéos conseils', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SizedBox(
          height: 165,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _videos.length,
            separatorBuilder: (_, index) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final v = _videos[i];
              return Container(
                width: 260,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 86,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.play_circle_fill_rounded, size: 36, color: Color(0xFF1A56DB)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Row(
                      children: [
                        Text(v.duration, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lecture vidéo "${v.title}" à brancher.')),
                            );
                          },
                          child: const Text('Lire'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const Text('Checklist de candidature', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: _checklist.entries
                .map(
                  (e) => CheckboxListTile(
                    value: e.value,
                    onChanged: (v) => setState(() => _checklist[e.key] = v ?? false),
                    title: Text(e.key),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Outils utiles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _ToolCard(title: 'Générateur de CV'),
            _ToolCard(title: 'Simulateur entretien IA'),
            _ToolCard(title: 'Calculateur salaire'),
          ],
        ),
      ],
    );
  }

  Widget _featuredCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF1A56DB)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guide complet: réussir sa candidature',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Une méthode claire pour optimiser votre CV, personnaliser vos candidatures et mieux préparer vos entretiens.',
                  style: TextStyle(color: Color(0xFFE2E8F0)),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A56DB),
                  ),
                  child: const Text('Lire'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 110,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, size: 42, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ConseilCard extends StatefulWidget {
  const _ConseilCard({required this.article});
  final _Article article;

  @override
  State<_ConseilCard> createState() => _ConseilCardState();
}

class _ConseilCardState extends State<_ConseilCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor(widget.article.category);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: _hover
              ? const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 6))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.article_outlined, color: Color(0xFF64748B), size: 30),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                widget.article.category,
                style: TextStyle(fontSize: 11, color: categoryColor, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.article.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              widget.article.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const Spacer(),
            Row(
              children: [
                Text(widget.article.readTime, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('Lire l’article')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String c) {
    switch (c) {
      case 'CV & Lettre':
        return const Color(0xFF1A56DB);
      case 'Entretien':
        return const Color(0xFF7C3AED);
      case 'Recherche emploi':
        return const Color(0xFF0F766E);
      case 'Négociation salaire':
        return const Color(0xFFB45309);
      case 'Reconversion':
        return const Color(0xFFBE185D);
      case 'Entrepreneuriat':
        return const Color(0xFF15803D);
      default:
        return const Color(0xFF475569);
    }
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.build_circle_outlined, color: Color(0xFF1A56DB)),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 6),
          const Text('Bientôt', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _Article {
  const _Article({
    required this.title,
    required this.summary,
    required this.category,
    required this.readTime,
  });

  final String title;
  final String summary;
  final String category;
  final String readTime;
}

class _Video {
  const _Video({required this.title, required this.duration});

  final String title;
  final String duration;
}
