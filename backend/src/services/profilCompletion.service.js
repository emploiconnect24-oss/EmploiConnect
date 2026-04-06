function hasText(v) {
  return typeof v === 'string' ? v.trim().length > 0 : !!v;
}

function hasCompetences(chercheur) {
  if (Array.isArray(chercheur?.competences)) return chercheur.competences.length > 0;
  if (chercheur?.competences && typeof chercheur.competences === 'object') {
    return Object.values(chercheur.competences).filter(Boolean).length > 0;
  }
  return false;
}

function hasCvAnalysis(cv) {
  const ce = cv?.competences_extrait;
  if (!ce) return false;
  if (Array.isArray(ce?.competences)) return ce.competences.length > 0;
  if (Array.isArray(ce)) return ce.length > 0;
  return false;
}

export function calculerCompletionProfil(utilisateur, chercheur, cv) {
  const points = [
    { label: 'Photo de profil', pts: 15, ok: hasText(utilisateur?.photo_url) },
    { label: 'Nom complet', pts: 5, ok: hasText(utilisateur?.nom) },
    { label: 'Téléphone', pts: 5, ok: hasText(utilisateur?.telephone) },
    { label: 'Adresse / Ville', pts: 5, ok: hasText(utilisateur?.adresse) },
    { label: 'Email', pts: 5, ok: hasText(utilisateur?.email) },
    { label: 'Titre professionnel', pts: 10, ok: hasText(chercheur?.titre_poste) || hasText(chercheur?.niveau_etude) },
    { label: 'Présentation', pts: 10, ok: hasText(chercheur?.about) },
    { label: 'Compétences', pts: 10, ok: hasCompetences(chercheur) },
    { label: 'CV uploadé', pts: 15, ok: hasText(cv?.fichier_url) || hasText(cv?.nom_fichier) },
    { label: 'CV analysé par IA', pts: 10, ok: hasCvAnalysis(cv) },
    { label: 'Disponibilité', pts: 5, ok: hasText(chercheur?.disponibilite) },
    { label: 'Niveau d\'étude', pts: 5, ok: hasText(chercheur?.niveau_etude) },
  ];

  const totalPts = points.reduce((sum, p) => sum + p.pts, 0);
  const obtenusPts = points.filter((p) => p.ok).reduce((sum, p) => sum + p.pts, 0);
  const pourcentage = Math.max(0, Math.min(100, Math.round((obtenusPts / totalPts) * 100)));

  const manquants = points
    .filter((p) => !p.ok)
    .map((p) => ({ label: p.label, pts: p.pts }))
    .sort((a, b) => b.pts - a.pts);

  const identite = points.slice(0, 5);
  const profil = points.slice(5, 8);
  const cvSection = points.slice(8, 10);

  const pct = (arr) => {
    const total = arr.reduce((s, p) => s + p.pts, 0);
    const got = arr.filter((p) => p.ok).reduce((s, p) => s + p.pts, 0);
    return total > 0 ? Math.round((got / total) * 100) : 0;
  };

  return {
    pourcentage,
    points_obtenus: obtenusPts,
    points_total: totalPts,
    manquants,
    sections: {
      identite: pct(identite),
      profil: pct(profil),
      cv: pct(cvSection),
    },
  };
}
