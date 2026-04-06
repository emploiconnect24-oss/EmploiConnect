# PRD — EmploiConnect · Vue d'ensemble + Mes Offres + Candidatures Recruteur
## Product Requirements Document v5.3 — Dashboard Recruteur Complet
**Stack : Flutter + Node.js/Express + PostgreSQL/Supabase**
**Outil : Cursor / Kirsoft AI**
**Objectif : Vue d'ensemble parfaite + compteur vues + mes offres + candidatures**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS POUR CURSOR
>
> La vue d'ensemble affiche maintenant les offres ✅
> Il reste à perfectionner :
> 1. Compteur de vues réel (quand un candidat consulte une offre)
> 2. Vue d'ensemble complète et bien designée
> 3. Page Mes Offres complète avec toutes les données
> 4. Page Candidatures avec liste + kanban
>
> Implémenter dans l'ordre exact des sections.

---

## 1. Backend — Compteur de Vues Réel

### Ajouter dans `backend/src/routes/offres.routes.js`

```javascript
// Dans GET /api/offres/:id (route PUBLIQUE consultée par les candidats)
// Après avoir récupéré l'offre, incrémenter les vues

router.get('/:id', async (req, res) => {
  try {
    const { supabase } = require('../config/supabase');

    // Récupérer l'offre
    const { data: offre, error } = await supabase
      .from('offres_emploi')
      .select(`
        *,
        entreprise:entreprise_id (
          id, nom_entreprise, logo_url,
          description, secteur_activite,
          taille_entreprise, site_web, adresse_siege
        )
      `)
      .eq('id', req.params.id)
      .single();

    if (error || !offre) {
      return res.status(404).json({
        success: false, message: 'Offre non trouvée'
      });
    }

    // ── Incrémenter le compteur de vues ──────────────────
    // Non bloquant — ne pas attendre la réponse
    setImmediate(async () => {
      try {
        const userId    = req.user?.id || null;
        const ipAddress = (
          req.headers['x-forwarded-for'] ||
          req.connection?.remoteAddress  ||
          req.ip || 'unknown'
        ).split(',')[0].trim();

        // Vérifier si déjà vu dans les dernières 24h
        // (éviter de compter plusieurs fois le même visiteur)
        const hier = new Date(
          Date.now() - 24 * 60 * 60 * 1000).toISOString();

        let queryVue = supabase
          .from('offres_vues')
          .select('id')
          .eq('offre_id', req.params.id)
          .gte('date_vue', hier);

        // Si utilisateur connecté → déduplication par user_id
        // Sinon → déduplication par IP
        if (userId) {
          queryVue = queryVue.eq('user_id', userId);
        } else {
          queryVue = queryVue.eq('ip_address', ipAddress);
        }

        const { data: vueExistante } = await queryVue.limit(1);

        // Enregistrer la vue seulement si pas déjà vue
        if (!vueExistante || vueExistante.length === 0) {
          // 1. Insérer dans offres_vues
          await supabase.from('offres_vues').insert({
            offre_id:   req.params.id,
            user_id:    userId,
            ip_address: ipAddress,
            date_vue:   new Date().toISOString(),
          });

          // 2. Incrémenter nb_vues dans offres_emploi
          await supabase.rpc('increment_vues', {
            offre_id: req.params.id
          });
        }
      } catch (e) {
        // Non bloquant — ne jamais crasher pour ça
        console.warn('[vues] Erreur non bloquante:', e.message);
      }
    });

    return res.json({ success: true, data: offre });

  } catch (err) {
    console.error('[GET /offres/:id]', err.message);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});
```

### Créer la fonction SQL `increment_vues`

```sql
-- Exécuter dans Supabase SQL Editor :

-- Fonction pour incrémenter nb_vues de manière atomique
CREATE OR REPLACE FUNCTION increment_vues(offre_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE offres_emploi
  SET nb_vues = COALESCE(nb_vues, 0) + 1
  WHERE id = offre_id;
END;
$$ LANGUAGE plpgsql;

-- Créer la table offres_vues si elle n'existe pas
CREATE TABLE IF NOT EXISTS offres_vues (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  offre_id   UUID NOT NULL REFERENCES offres_emploi(id)
    ON DELETE CASCADE,
  user_id    UUID REFERENCES utilisateurs(id) ON DELETE SET NULL,
  ip_address VARCHAR(45),
  date_vue   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_offres_vues_offre_date
  ON offres_vues(offre_id, date_vue DESC);

CREATE INDEX IF NOT EXISTS idx_offres_vues_user
  ON offres_vues(user_id);

-- Ajouter nb_vues dans offres_emploi si pas encore présent
ALTER TABLE offres_emploi
  ADD COLUMN IF NOT EXISTS nb_vues INTEGER DEFAULT 0;

-- Mettre à jour les vues existantes depuis offres_vues
UPDATE offres_emploi o
SET nb_vues = (
  SELECT COUNT(*) FROM offres_vues v WHERE v.offre_id = o.id
);
```

---

## 2. Backend — Dashboard Recruteur Amélioré

### Remplacer entièrement `backend/src/routes/recruteur/dashboard.routes.js`

```javascript
const express  = require('express');
const router   = express.Router();
const { auth } = require('../../middleware/auth');
const { requireRecruteur } = require('../../middleware/recruteurAuth');
const { supabase } = require('../../config/supabase');

router.use(auth, requireRecruteur);

router.get('/', async (req, res) => {
  try {
    const entrepriseId = req.entreprise.id;
    const now          = new Date();
    const debut30j     = new Date(
      now - 30 * 24 * 60 * 60 * 1000).toISOString();
    const debut7j      = new Date(
      now - 7 * 24 * 60 * 60 * 1000).toISOString();

    // ── 1. Toutes les offres de cette entreprise ──────────
    const { data: offres } = await supabase
      .from('offres_emploi')
      .select('id, titre, statut, nb_vues, date_publication, date_limite, date_creation')
      .eq('entreprise_id', entrepriseId)
      .order('date_creation', { ascending: false });

    const toutesOffres  = offres || [];
    const offresIds     = toutesOffres.map(o => o.id);
    const offresActives = toutesOffres.filter(o => o.statut === 'publiee');

    // ── 2. Candidatures pour ces offres ───────────────────
    let toutesCandidatures = [];
    if (offresIds.length > 0) {
      const { data: cands } = await supabase
        .from('candidatures')
        .select(`
          id, statut, score_compatibilite,
          date_candidature, offre_id,
          chercheur:chercheur_id (
            id,
            utilisateur:utilisateur_id (
              id, nom, email, photo_url
            )
          ),
          offre:offre_id (id, titre)
        `)
        .in('offre_id', offresIds)
        .order('date_candidature', { ascending: false });

      toutesCandidatures = cands || [];
    }

    // ── 3. Messages non lus ───────────────────────────────
    const { count: nbMessages } = await supabase
      .from('messages')
      .select('id', { count: 'exact' })
      .eq('destinataire_id', req.user.id)
      .eq('est_lu', false);

    // ── 4. Vues ce mois ───────────────────────────────────
    let vuesMois = 0;
    if (offresIds.length > 0) {
      const { count } = await supabase
        .from('offres_vues')
        .select('id', { count: 'exact' })
        .in('offre_id', offresIds)
        .gte('date_vue', debut30j);
      vuesMois = count || 0;

      // Fallback : utiliser nb_vues si offres_vues vide
      if (vuesMois === 0) {
        vuesMois = toutesOffres.reduce(
          (sum, o) => sum + (o.nb_vues || 0), 0);
      }
    }

    // ── 5. Calculs stats ──────────────────────────────────
    const candsEnAttente  = toutesCandidatures.filter(
      c => c.statut === 'en_attente');
    const candsTraitees   = toutesCandidatures.filter(c =>
      ['acceptee', 'refusee', 'entretien'].includes(c.statut));

    const tauxReponse = toutesCandidatures.length > 0
      ? Math.round(candsTraitees.length /
          toutesCandidatures.length * 100)
      : 0;

    // Candidatures urgentes (en attente > 7 jours)
    const candidaturesUrgentes = candsEnAttente.filter(
      c => c.date_candidature < debut7j);

    // ── 6. Offres actives avec stats par offre ────────────
    const offresActivesAvecStats = offresActives
      .slice(0, 5)
      .map(o => ({
        ...o,
        nb_candidatures: toutesCandidatures.filter(
          c => c.offre_id === o.id).length,
        nb_non_lues: toutesCandidatures.filter(
          c => c.offre_id === o.id &&
               c.statut === 'en_attente').length,
      }));

    // ── 7. Évolution candidatures 7 derniers jours ────────
    const evolutionSemaine = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().split('T')[0];
      const count   = toutesCandidatures.filter(c =>
        c.date_candidature?.startsWith(dateStr)).length;
      evolutionSemaine.push({
        date:  dateStr,
        jour:  ['Dim','Lun','Mar','Mer','Jeu','Ven','Sam'][d.getDay()],
        count,
      });
    }

    return res.json({
      success: true,
      data: {
        stats: {
          offres_actives:          offresActives.length,
          offres_en_attente_valid: toutesOffres.filter(
            o => o.statut === 'en_attente').length,
          total_offres:            toutesOffres.length,
          total_candidatures:      toutesCandidatures.length,
          candidatures_en_attente: candsEnAttente.length,
          vues_ce_mois:            vuesMois,
          taux_reponse:            tauxReponse,
          messages_non_lus:        nbMessages || 0,
        },
        offres_actives:          offresActivesAvecStats,
        candidatures_recentes:   toutesCandidatures.slice(0, 5),
        candidatures_urgentes:   candidaturesUrgentes.slice(0, 3),
        evolution_semaine:       evolutionSemaine,
        entreprise: {
          id:   req.entreprise.id,
          nom:  req.entreprise.nom_entreprise,
          logo: req.entreprise.logo_url,
        },
      }
    });

  } catch (err) {
    console.error('[recruteur/dashboard]', err.message);
    res.status(500).json({
      success: false, message: err.message
    });
  }
});

module.exports = router;
```

---

## 3. Flutter — Page Vue d'ensemble Complète

### Remplacer entièrement la page vue d'ensemble recruteur

```dart
// lib/screens/recruteur/pages/dashboard_overview_page.dart

class DashboardOverviewPage extends StatefulWidget {
  const DashboardOverviewPage({super.key});
  @override
  State<DashboardOverviewPage> createState() =>
    _DashboardOverviewPageState();
}

class _DashboardOverviewPageState extends State<DashboardOverviewPage> {
  final RecruteurService _svc = RecruteurService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res   = await _svc.getDashboard(token);
      if (res['success'] == true) {
        setState(() { _data = res['data']; _isLoading = false; });
      } else {
        setState(() {
          _error = res['message'] ?? 'Erreur inconnue';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();

    final stats      = _data!['stats']    as Map<String, dynamic>? ?? {};
    final offres     = List<Map<String, dynamic>>.from(
      _data!['offres_actives']        ?? []);
    final cands      = List<Map<String, dynamic>>.from(
      _data!['candidatures_recentes'] ?? []);
    final urgentes   = List<Map<String, dynamic>>.from(
      _data!['candidatures_urgentes'] ?? []);
    final evolution  = List<Map<String, dynamic>>.from(
      _data!['evolution_semaine']     ?? []);
    final entreprise = _data!['entreprise'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1A56DB),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── En-tête ──────────────────────────────────
            _buildHeader(entreprise, urgentes),
            const SizedBox(height: 20),

            // ── 4 Stat Cards ─────────────────────────────
            _buildStatCards(stats),
            const SizedBox(height: 24),

            // ── Alerte urgente ───────────────────────────
            if (urgentes.isNotEmpty) ...[
              _buildUrgentBanner(urgentes),
              const SizedBox(height: 16),
            ],

            // ── Ligne : graphique + répartition ──────────
            LayoutBuilder(builder: (ctx, c) {
              if (c.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 60,
                      child: _buildEvolutionChart(evolution)),
                    const SizedBox(width: 16),
                    Expanded(flex: 40,
                      child: _buildRepartitionCard(stats)),
                  ],
                );
              }
              return Column(children: [
                _buildEvolutionChart(evolution),
                const SizedBox(height: 16),
                _buildRepartitionCard(stats),
              ]);
            }),
            const SizedBox(height: 24),

            // ── Candidatures récentes ─────────────────────
            _buildSection(
              titre:     'Candidatures récentes',
              lienLabel: 'Voir tout →',
              lienRoute: '/dashboard-recruteur/candidatures',
              child:     _buildCandidaturesList(cands),
            ),
            const SizedBox(height: 24),

            // ── Mes offres actives ────────────────────────
            _buildSection(
              titre:     'Mes offres actives',
              lienLabel: 'Gérer →',
              lienRoute: '/dashboard-recruteur/offres',
              child:     _buildOffresList(offres),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Header avec heure ─────────────────────────────────────
  Widget _buildHeader(
    Map<String, dynamic> entreprise,
    List<Map<String, dynamic>> urgentes,
  ) {
    final nom  = entreprise['nom'] as String? ?? 'Mon entreprise';
    final hour = DateTime.now().hour;
    final salut = hour < 12 ? 'Bonjour' :
                  hour < 18 ? 'Bon après-midi' : 'Bonsoir';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text('$salut 👋',
            style: GoogleFonts.inter(
              fontSize: 14, color: const Color(0xFF64748B))),
          Text(nom, style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
          if (urgentes.isNotEmpty)
            Row(children: [
              Container(
                width: 8, height: 8, margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B), shape: BoxShape.circle)),
              Text(
                '${urgentes.length} candidature(s) en attente '
                'depuis plus de 7 jours',
                style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w500)),
            ]),
        ])),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: Text('Nouvelle offre',
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),
          onPressed: () =>
            context.push('/dashboard-recruteur/offres/nouvelle'),
        ),
      ],
    );
  }

  // ── 4 Stat Cards ──────────────────────────────────────────
  Widget _buildStatCards(Map<String, dynamic> stats) {
    final cards = [
      _StatInfo(
        label:  'Offres actives',
        value:  '${stats['offres_actives'] ?? 0}',
        subLabel: stats['offres_en_attente_valid'] != null &&
                  (stats['offres_en_attente_valid'] as int) > 0
          ? '+${stats['offres_en_attente_valid']} en attente validation'
          : 'Publiées et visibles',
        icon:  Icons.work_rounded,
        color: const Color(0xFF1A56DB),
        bg:    const Color(0xFFEFF6FF),
      ),
      _StatInfo(
        label:    'Candidatures',
        value:    '${stats['total_candidatures'] ?? 0}',
        subLabel: '${stats['candidatures_en_attente'] ?? 0} en attente',
        icon:     Icons.people_rounded,
        color:    const Color(0xFF10B981),
        bg:       const Color(0xFFECFDF5),
      ),
      _StatInfo(
        label:    'Vues ce mois',
        value:    '${stats['vues_ce_mois'] ?? 0}',
        subLabel: 'Visiteurs uniques',
        icon:     Icons.visibility_rounded,
        color:    const Color(0xFF8B5CF6),
        bg:       const Color(0xFFF5F3FF),
      ),
      _StatInfo(
        label:    'Taux de réponse',
        value:    '${stats['taux_reponse'] ?? 0}%',
        subLabel: stats['taux_reponse'] != null &&
                  (stats['taux_reponse'] as int) >= 50
          ? '✅ Bon taux' : 'À améliorer',
        icon:     Icons.reply_rounded,
        color:    const Color(0xFFF59E0B),
        bg:       const Color(0xFFFEF3C7),
      ),
    ];

    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth < 600 ? 2 : 4;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14, mainAxisSpacing: 14,
        childAspectRatio: c.maxWidth < 600 ? 1.4 : 1.8,
        children: cards.map((s) => _StatCard(info: s)).toList(),
      );
    });
  }

  // ── Alerte urgente ────────────────────────────────────────
  Widget _buildUrgentBanner(List<Map<String, dynamic>> urgentes) =>
    GestureDetector(
      onTap: () =>
        context.push('/dashboard-recruteur/candidatures'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDBA74))),
        child: Row(children: [
          const Icon(Icons.hourglass_empty_rounded,
            color: Color(0xFFF97316), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
            '${urgentes.length} candidature(s) attendent '
            'votre réponse depuis plus de 7 jours. '
            'Répondez rapidement pour améliorer votre taux !',
            style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF9A3412),
              fontWeight: FontWeight.w500))),
          const Icon(Icons.arrow_forward_ios,
            size: 14, color: Color(0xFF9A3412)),
        ]),
      ),
    );

  // ── Graphique évolution 7 jours ───────────────────────────
  Widget _buildEvolutionChart(List<Map<String, dynamic>> evolution) {
    final maxVal = evolution.isEmpty ? 1 :
      evolution.map((e) => e['count'] as int? ?? 0)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(children: [
          Text('Candidatures — 7 derniers jours',
            style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A))),
          const Spacer(),
          Text(
            'Total: ${evolution.fold(0, (s, e) => s + (e['count'] as int? ?? 0))}',
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF64748B))),
        ]),
        const SizedBox(height: 20),

        if (evolution.isEmpty)
          Center(child: Text('Aucune donnée',
            style: GoogleFonts.inter(color: const Color(0xFF94A3B8))))
        else
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: evolution.map((e) {
                final count   = e['count'] as int? ?? 0;
                final pct     = maxVal > 0 ? count / maxVal : 0.0;
                final isToday = e['jour'] == ['Dim','Lun','Mar','Mer',
                  'Jeu','Ven','Sam'][DateTime.now().weekday % 7];

                return Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                    if (count > 0)
                      Text('$count', style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A56DB))),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      height: (100 * pct).clamp(4.0, 100.0),
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFF1A56DB)
                            : const Color(0xFF1A56DB).withOpacity(0.25),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4))),
                    ),
                    const SizedBox(height: 6),
                    Text(e['jour'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isToday
                            ? const Color(0xFF1A56DB)
                            : const Color(0xFF94A3B8),
                        fontWeight: isToday
                            ? FontWeight.w700 : FontWeight.w400)),
                  ]),
                ));
              }).toList(),
            ),
          ),
      ]),
    );
  }

  // ── Répartition des candidatures ─────────────────────────
  Widget _buildRepartitionCard(Map<String, dynamic> stats) {
    final total = stats['total_candidatures'] as int? ?? 0;

    final items = [
      _RepartItem('En attente',
        stats['candidatures_en_attente'] ?? 0,
        const Color(0xFF1A56DB), total),
      _RepartItem('Acceptées',
        // Calculer depuis les données si disponible
        0, const Color(0xFF10B981), total),
      _RepartItem('Refusées',
        0, const Color(0xFFEF4444), total),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text('Répartition candidatures',
          style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A))),
        const SizedBox(height: 16),
        if (total == 0)
          Center(child: Column(children: [
            const Icon(Icons.people_outline,
              color: Color(0xFFE2E8F0), size: 40),
            const SizedBox(height: 8),
            Text('Aucune candidature',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8), fontSize: 13)),
          ]))
        else
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                Text(item.label, style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF334155))),
                Text(
                  item.total > 0
                    ? '${item.count} '
                      '(${(item.count/item.total*100).toStringAsFixed(0)}%)'
                    : '${item.count}',
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: item.color)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: item.total > 0
                    ? item.count / item.total : 0,
                  backgroundColor: item.color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(item.color),
                  minHeight: 6,
                ),
              ),
            ]),
          )),
      ]),
    );
  }

  // ── Section générique avec titre + lien ──────────────────
  Widget _buildSection({
    required String titre,
    required String lienLabel,
    required String lienRoute,
    required Widget child,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(titre, style: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A))),
      TextButton(
        onPressed: () => context.push(lienRoute),
        child: Text(lienLabel, style: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFF1A56DB))),
      ),
    ]),
    const SizedBox(height: 12),
    child,
  ]);

  // ── Liste candidatures récentes ───────────────────────────
  Widget _buildCandidaturesList(List<Map<String, dynamic>> cands) {
    if (cands.isEmpty) return _EmptyCard(
      icon:    Icons.people_outline,
      message: 'Aucune candidature reçue pour le moment',
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(children: cands.map((c) {
        final nom    = c['chercheur']?['utilisateur']?['nom']
            as String? ?? 'Candidat';
        final photo  = c['chercheur']?['utilisateur']?['photo_url']
            as String?;
        final offre  = c['offre']?['titre'] as String? ?? 'Offre';
        final score  = c['score_compatibilite'] as int?;
        final statut = c['statut'] as String? ?? 'en_attente';
        final date   = _formatDate(c['date_candidature']);

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(
              color: Color(0xFFE2E8F0)))),
          child: Row(children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF1A56DB),
              backgroundImage: photo != null
                  ? NetworkImage(photo) : null,
              child: photo == null
                  ? Text(nom[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: Colors.white))
                  : null,
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(nom, style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A))),
              Text(offre, style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF64748B)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 8),
            // Score IA
            if (score != null && score > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _scoreColor(score).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: _scoreColor(score).withOpacity(0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.auto_awesome, size: 10,
                    color: Color(0xFF1A56DB)),
                  const SizedBox(width: 3),
                  Text('$score%', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: _scoreColor(score))),
                ]),
              ),
            const SizedBox(width: 8),
            // Statut
            StatusBadge(label: statut),
            const SizedBox(width: 8),
            // Date
            Text(date, style: GoogleFonts.inter(
              fontSize: 11, color: const Color(0xFF94A3B8))),
          ]),
        );
      }).toList()),
    );
  }

  // ── Liste offres actives ──────────────────────────────────
  Widget _buildOffresList(List<Map<String, dynamic>> offres) {
    if (offres.isEmpty) return _EmptyCard(
      icon:        Icons.work_outline,
      message:     'Aucune offre active. Publiez votre première offre !',
      actionLabel: 'Publier une offre',
      onAction:    () => context.push('/dashboard-recruteur/offres/nouvelle'),
    );

    return Column(children: offres.map((o) {
      final titre    = o['titre']          as String? ?? 'Offre';
      final nbVues   = o['nb_vues']        as int? ?? 0;
      final nbCands  = o['nb_candidatures'] as int? ?? 0;
      final nbNonLus = o['nb_non_lues']    as int? ?? 0;
      final statut   = o['statut']         as String? ?? '';

      // Date limite
      String dateLimite = '';
      if (o['date_limite'] != null) {
        try {
          final dl   = DateTime.parse(o['date_limite']).toLocal();
          final diff = dl.difference(DateTime.now()).inDays;
          dateLimite = diff > 0
              ? 'Expire dans $diff j'
              : 'Expirée';
        } catch (_) {}
      }

      return GestureDetector(
        onTap: () => context.push(
          '/dashboard-recruteur/candidatures?offreId=${o['id']}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: nbNonLus > 0
                  ? const Color(0xFF1A56DB).withOpacity(0.3)
                  : const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(
              color: Color(0x06000000), blurRadius: 8,
              offset: Offset(0, 2))]),
          child: Row(children: [
            // Indicateur non lu
            Container(
              width: 4,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: nbNonLus > 0
                    ? const Color(0xFF1A56DB)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(100)),
            ),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(children: [
                Expanded(child: Text(titre,
                  style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A)),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                StatusBadge(label: statut),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                // Vues
                _OffreStat(
                  Icons.visibility_outlined, '$nbVues vues'),
                const SizedBox(width: 14),
                // Candidatures
                _OffreStat(
                  Icons.people_outline, '$nbCands candidats'),
                // Non lus
                if (nbNonLus > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(100)),
                    child: Text('$nbNonLus nouvelles',
                      style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981)))),
                ],
                const Spacer(),
                // Date limite
                if (dateLimite.isNotEmpty)
                  Text(dateLimite, style: GoogleFonts.inter(
                    fontSize: 11, color: dateLimite.contains('Expir')
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF94A3B8))),
              ]),
            ])),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
              size: 14, color: Color(0xFFCBD5E1)),
          ]),
        ),
      );
    }).toList());
  }

  // ── Helpers ───────────────────────────────────────────────
  Widget _buildLoading() => const Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      CircularProgressIndicator(color: Color(0xFF1A56DB)),
      SizedBox(height: 12),
      Text('Chargement...'),
    ],
  ));

  Widget _buildError() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.error_outline,
        color: Color(0xFFEF4444), size: 48),
      const SizedBox(height: 12),
      Text(_error ?? 'Erreur',
        style: GoogleFonts.inter(
          fontSize: 14, color: const Color(0xFF64748B))),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: _load,
        child: const Text('Réessayer')),
    ],
  ));

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFF1A56DB);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _formatDate(String? d) {
    if (d == null) return '';
    try {
      final dt   = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
      if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
      if (diff.inDays < 7)     return 'Il y a ${diff.inDays}j';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }
}

// ── Widgets helpers ────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final _StatInfo info;
  const _StatCard({required this.info});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: const [BoxShadow(
        color: Color(0x06000000), blurRadius: 8,
        offset: Offset(0, 2))]),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: info.bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(info.icon, color: info.color, size: 20)),
      ]),
      const SizedBox(height: 8),
      Text(info.value, style: GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w800,
        color: const Color(0xFF0F172A))),
      Text(info.label, style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: const Color(0xFF64748B))),
      if (info.subLabel != null)
        Text(info.subLabel!, style: GoogleFonts.inter(
          fontSize: 11, color: info.color)),
    ]),
  );
}

class _StatInfo {
  final String label, value;
  final String? subLabel;
  final IconData icon;
  final Color color, bg;
  const _StatInfo({
    required this.label, required this.value,
    this.subLabel, required this.icon,
    required this.color, required this.bg,
  });
}

class _RepartItem {
  final String label;
  final int count, total;
  final Color color;
  const _RepartItem(this.label, this.count, this.color, this.total);
}

class _OffreStat extends StatelessWidget {
  final IconData icon;
  final String text;
  const _OffreStat(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
      const SizedBox(width: 3),
      Text(text, style: GoogleFonts.inter(
        fontSize: 12, color: const Color(0xFF94A3B8))),
    ],
  );
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _EmptyCard({
    required this.icon, required this.message,
    this.actionLabel, this.onAction,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Center(child: Column(children: [
      Icon(icon, color: const Color(0xFFE2E8F0), size: 48),
      const SizedBox(height: 12),
      Text(message, style: GoogleFonts.inter(
        fontSize: 14, color: const Color(0xFF94A3B8)),
        textAlign: TextAlign.center),
      if (actionLabel != null && onAction != null) ...[
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8))),
          onPressed: onAction,
          child: Text(actionLabel!, style: GoogleFonts.inter(
            fontWeight: FontWeight.w600))),
      ],
    ])),
  );
}
```

---

## 4. Page Mes Offres — Données réelles et design complet

```dart
// lib/screens/recruteur/pages/mes_offres_page.dart

class _MesOffresPageState extends State<MesOffresPage>
    with SingleTickerProviderStateMixin {
  final RecruteurService _svc = RecruteurService();
  late TabController _tabs;
  List<Map<String, dynamic>> _offres = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _selectedStatut;
  String _recherche = '';
  final _ctrl = TextEditingController();
  Timer? _debounce;

  final _statuts = [
    {'key': null,          'label': 'Toutes',    'statKey': 'total'},
    {'key': 'publiee',     'label': 'Actives',   'statKey': 'publiees'},
    {'key': 'en_attente',  'label': 'En attente','statKey': 'en_attente'},
    {'key': 'expiree',     'label': 'Expirées',  'statKey': 'expirees'},
    {'key': 'brouillon',   'label': 'Brouillons','statKey': 'brouillons'},
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statuts.length, vsync: this);
    _tabs.addListener(_onTabChange);
    _load();
  }

  void _onTabChange() {
    if (!_tabs.indexIsChanging) {
      setState(() => _selectedStatut =
        _statuts[_tabs.index]['key'] as String?);
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getOffres(
        token,
        statut:    _selectedStatut,
        recherche: _recherche.isNotEmpty ? _recherche : null,
      );
      if (res['success'] == true) {
        setState(() {
          _offres    = List<Map<String, dynamic>>.from(
            res['data']?['offres'] ?? []);
          _stats     = res['data']?['stats']
              as Map<String, dynamic>? ?? {};
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [

        // ── En-tête ──────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mes offres d\'emploi',
              style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
            Text('Gérez toutes vos annonces',
              style: GoogleFonts.inter(
                fontSize: 14, color: const Color(0xFF64748B))),
          ]),
          Row(children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Exporter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
              onPressed: _exportCSV),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Publier une offre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
              onPressed: () =>
                context.push('/dashboard-recruteur/offres/nouvelle'),
            ),
          ]),
        ]),
        const SizedBox(height: 20),

        // ── Card principale ───────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(children: [

            // Tabs avec compteurs réels
            TabBar(
              controller: _tabs,
              isScrollable: true,
              labelStyle: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                GoogleFonts.inter(fontSize: 13),
              labelColor: const Color(0xFF1A56DB),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF1A56DB),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: _statuts.map((s) {
                final count = _stats[s['statKey']] ?? 0;
                return Tab(text: '${s['label']} ($count)');
              }).toList(),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: 'Rechercher une offre par titre...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFFCBD5E1)),
                  prefixIcon: const Icon(Icons.search,
                    size: 18, color: Color(0xFF94A3B8)),
                  filled: true, fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0))),
                ),
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 400), () {
                    setState(() => _recherche = v);
                    _load();
                  });
                },
              ),
            ),

            // Liste des offres
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(
                  color: Color(0xFF1A56DB))))
            else if (_offres.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: _EmptyCard(
                  icon:        Icons.work_outline,
                  message:     _recherche.isNotEmpty
                      ? 'Aucune offre trouvée pour "$_recherche"'
                      : 'Aucune offre dans cette catégorie',
                  actionLabel: _selectedStatut == null
                      ? 'Publier une offre' : null,
                  onAction:    _selectedStatut == null
                      ? () => context.push(
                          '/dashboard-recruteur/offres/nouvelle')
                      : null,
                ))
            else
              ...(_offres.map((o) => _OffreCard(
                offre:     o,
                onAction:  (action) => _doAction(o, action),
                onRefresh: _load,
              ))),
          ]),
        ),
      ]),
    );
  }

  Future<void> _doAction(
    Map<String, dynamic> offre, String action) async {
    final token = context.read<AuthProvider>().token ?? '';
    final id    = offre['id'] as String;

    try {
      switch (action) {
        case 'dupliquer':
          await _svc.dupliquerOffre(token, id);
          _showSnack('Offre dupliquée en brouillon ✅');
          break;
        case 'cloturer':
          await _svc.cloturerOffre(token, id);
          _showSnack('Offre clôturée');
          break;
        case 'supprimer':
          await _svc.deleteOffre(token, id);
          _showSnack('Offre supprimée');
          break;
        case 'voir_candidatures':
          context.push(
            '/dashboard-recruteur/candidatures?offreId=$id');
          return;
      }
      _load();
    } catch (e) {
      _showSnack('Erreur: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError
          ? const Color(0xFFEF4444)
          : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _exportCSV() async {
    final token = context.read<AuthProvider>().token ?? '';
    await DownloadService.downloadCsv(
      url:      '${ApiConfig.baseUrl}/api/recruteur/offres/export/csv',
      token:    token,
      fileName: 'mes_offres.csv',
      context:  context,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}

// ── Carte d'une offre ──────────────────────────────────────
class _OffreCard extends StatelessWidget {
  final Map<String, dynamic> offre;
  final void Function(String action) onAction;
  final VoidCallback onRefresh;
  const _OffreCard({
    required this.offre,
    required this.onAction,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final titre     = offre['titre']          as String? ?? '';
    final statut    = offre['statut']         as String? ?? '';
    final nbVues    = offre['nb_vues']        as int? ?? 0;
    final nbCands   = offre['nb_candidatures'] as int? ?? 0;
    final nbNonLues = offre['nb_non_lues']    as int? ?? 0;
    final localisation = offre['localisation'] as String? ?? '';
    final typeContrat  = offre['type_contrat'] as String? ?? '';
    final raisonRefus  = offre['raison_refus'] as String?;

    String dateLimite = '';
    if (offre['date_limite'] != null) {
      try {
        final dl   = DateTime.parse(offre['date_limite']).toLocal();
        final diff = dl.difference(DateTime.now()).inDays;
        dateLimite = diff > 0
            ? 'Expire dans $diff jour(s)'
            : 'Expirée';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(
          color: Color(0xFFF1F5F9)))),
      child: Column(children: [

        Row(children: [
          // Titre + badges
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(children: [
              Expanded(child: Text(titre,
                style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A)),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              StatusBadge(label: statut),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.location_on_outlined,
                size: 13, color: const Color(0xFF94A3B8)),
              Text(' $localisation',
                style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF94A3B8))),
              if (typeContrat.isNotEmpty) ...[
                Text(' · ', style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF94A3B8))),
                Text(typeContrat, style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF94A3B8))),
              ],
            ]),
          ])),

          // Menu actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
              color: Color(0xFF94A3B8)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
            itemBuilder: (_) => [
              if (nbCands > 0)
                PopupMenuItem(value: 'voir_candidatures',
                  child: Row(children: [
                    const Icon(Icons.people_outline, size: 16),
                    const SizedBox(width: 8),
                    Text('Voir les $nbCands candidature(s)'),
                  ])),
              const PopupMenuItem(value: 'dupliquer',
                child: Row(children: [
                  Icon(Icons.copy_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Dupliquer'),
                ])),
              if (statut == 'publiee')
                const PopupMenuItem(value: 'cloturer',
                  child: Row(children: [
                    Icon(Icons.stop_circle_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Clôturer'),
                  ])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'supprimer',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 16,
                    color: Color(0xFFEF4444)),
                  SizedBox(width: 8),
                  Text('Supprimer',
                    style: TextStyle(color: Color(0xFFEF4444))),
                ])),
            ],
            onSelected: onAction,
          ),
        ]),

        const SizedBox(height: 10),

        // Métriques
        Row(children: [
          _Metric(Icons.visibility_outlined, '$nbVues vues'),
          const SizedBox(width: 16),
          _Metric(Icons.people_outline, '$nbCands candidats'),
          if (nbNonLues > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(100)),
              child: Text('$nbNonLues nouvelles',
                style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: const Color(0xFF10B981)))),
          ],
          const Spacer(),
          if (dateLimite.isNotEmpty)
            Text(dateLimite, style: GoogleFonts.inter(
              fontSize: 11,
              color: dateLimite.contains('Expir')
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF94A3B8))),
        ]),

        // Motif refus si applicable
        if (statut == 'refusee' && raisonRefus != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCA5A5))),
            child: Row(children: [
              const Icon(Icons.info_outline,
                size: 14, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Expanded(child: Text(
                'Motif de refus : $raisonRefus',
                style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF991B1B)))),
            ]),
          ),
        ],

        // Offre en attente → info
        if (statut == 'en_attente') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.schedule_outlined,
                size: 14, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              Expanded(child: Text(
                'En attente de validation par un administrateur',
                style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF92400E)))),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Metric(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
      const SizedBox(width: 4),
      Text(text, style: GoogleFonts.inter(
        fontSize: 12, color: const Color(0xFF94A3B8))),
    ],
  );
}
```

---

## 5. Critères d'Acceptation

### ✅ Compteur de vues
- [ ] Fonction SQL `increment_vues` créée dans Supabase
- [ ] Table `offres_vues` créée avec index
- [ ] Quand un candidat/visiteur consulte une offre → `nb_vues` s'incrémente
- [ ] Déduplication : même visiteur = 1 vue / 24h

### ✅ Vue d'ensemble
- [ ] 4 stat cards : offres actives, candidatures, vues mois, taux réponse — données réelles
- [ ] Sous-label des cards : informatif (ex: "+2 en attente validation")
- [ ] Graphique barres : évolution candidatures 7 derniers jours
- [ ] Répartition candidatures : en attente / acceptées / refusées
- [ ] Alerte orange : candidatures urgentes > 7 jours
- [ ] Candidatures récentes : avatar, nom, offre, score IA, statut, date
- [ ] Offres actives : vues réelles, candidatures, badge "nouvelles"
- [ ] Pull-to-refresh recharge toutes les données

### ✅ Page Mes Offres
- [ ] Tabs avec compteurs réels depuis l'API
- [ ] Recherche en temps réel avec debounce 400ms
- [ ] Chaque offre : nb vues réelles + nb candidatures + nb nouvelles
- [ ] Badge statut dynamique : vert/orange/rouge selon statut réel
- [ ] Menu 3 points : voir candidatures / dupliquer / clôturer / supprimer
- [ ] Message refus affiché si offre refusée par admin
- [ ] Message "en attente validation" si en_attente
- [ ] Export CSV fonctionne
- [ ] État vide si aucune offre avec bouton "Publier"

---

*PRD EmploiConnect v5.3 — Vue d'ensemble + Mes Offres Recruteur*
*Cursor / Kirsoft AI — Phase 9.3*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
