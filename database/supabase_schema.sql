-- ============================================================
-- SCHEMA SUPABASE - EMPLOICONNECT
-- Base de données pour la plateforme intelligente d'emploi
-- ============================================================

-- Extension pour UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLE: utilisateurs (Classe parente)
-- ============================================================
CREATE TABLE IF NOT EXISTS utilisateurs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nom VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    mot_de_passe VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('chercheur', 'entreprise', 'admin')),
    telephone VARCHAR(20),
    adresse TEXT,
    photo_url TEXT,
    est_actif BOOLEAN DEFAULT true,
    est_valide BOOLEAN DEFAULT false, -- Pour la modération admin
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour améliorer les performances
CREATE INDEX idx_utilisateurs_email ON utilisateurs(email);
CREATE INDEX idx_utilisateurs_role ON utilisateurs(role);

-- ============================================================
-- TABLE: chercheurs_emploi
-- ============================================================
CREATE TABLE IF NOT EXISTS chercheurs_emploi (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    utilisateur_id UUID UNIQUE NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    date_naissance DATE,
    genre VARCHAR(20),
    competences JSONB, -- Stockage des compétences extraites par IA
    niveau_etude VARCHAR(100),
    disponibilite VARCHAR(50),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chercheurs_utilisateur ON chercheurs_emploi(utilisateur_id);

-- ============================================================
-- TABLE: entreprises
-- ============================================================
CREATE TABLE IF NOT EXISTS entreprises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    utilisateur_id UUID UNIQUE NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    nom_entreprise VARCHAR(255) NOT NULL,
    description TEXT,
    secteur_activite VARCHAR(100),
    taille_entreprise VARCHAR(50),
    site_web VARCHAR(255),
    logo_url TEXT,
    adresse_siege TEXT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_entreprises_utilisateur ON entreprises(utilisateur_id);
CREATE INDEX idx_entreprises_nom ON entreprises(nom_entreprise);

-- ============================================================
-- TABLE: administrateurs
-- ============================================================
CREATE TABLE IF NOT EXISTS administrateurs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    utilisateur_id UUID UNIQUE NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    niveau_acces VARCHAR(50) DEFAULT 'moderateur',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_admin_utilisateur ON administrateurs(utilisateur_id);

-- ============================================================
-- TABLE: cv
-- ============================================================
CREATE TABLE IF NOT EXISTS cv (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chercheur_id UUID UNIQUE NOT NULL REFERENCES chercheurs_emploi(id) ON DELETE CASCADE,
    fichier_url TEXT NOT NULL, -- URL du fichier dans Supabase Storage
    nom_fichier VARCHAR(255),
    type_fichier VARCHAR(50), -- PDF, DOCX
    taille_fichier BIGINT, -- En bytes
    competences_extrait JSONB, -- Compétences extraites par IA
    experience JSONB, -- Expériences extraites
    domaine_activite VARCHAR(100),
    niveau_experience VARCHAR(50),
    texte_complet TEXT, -- Texte brut extrait du CV pour l'IA
    date_upload TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_analyse TIMESTAMP, -- Date de la dernière analyse IA
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_cv_chercheur ON cv(chercheur_id);
CREATE INDEX idx_cv_domaine ON cv(domaine_activite);

-- ============================================================
-- TABLE: offres_emploi
-- ============================================================
CREATE TABLE IF NOT EXISTS offres_emploi (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entreprise_id UUID NOT NULL REFERENCES entreprises(id) ON DELETE CASCADE,
    titre VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    exigences TEXT NOT NULL,
    competences_requises JSONB, -- Compétences extraites pour le matching IA
    salaire_min DECIMAL(10, 2),
    salaire_max DECIMAL(10, 2),
    devise VARCHAR(10) DEFAULT 'GNF',
    localisation VARCHAR(255),
    type_contrat VARCHAR(50), -- CDI, CDD, Stage, etc.
    niveau_experience_requis VARCHAR(50),
    domaine VARCHAR(100),
    statut VARCHAR(50) DEFAULT 'active' CHECK (statut IN ('active', 'brouillon', 'fermee', 'suspendue')),
    nombre_postes INTEGER DEFAULT 1,
    date_publication TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_limite DATE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_offres_entreprise ON offres_emploi(entreprise_id);
CREATE INDEX idx_offres_statut ON offres_emploi(statut);
CREATE INDEX idx_offres_domaine ON offres_emploi(domaine);
CREATE INDEX idx_offres_date_publication ON offres_emploi(date_publication DESC);

-- ============================================================
-- TABLE: candidatures
-- ============================================================
CREATE TABLE IF NOT EXISTS candidatures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chercheur_id UUID NOT NULL REFERENCES chercheurs_emploi(id) ON DELETE CASCADE,
    offre_id UUID NOT NULL REFERENCES offres_emploi(id) ON DELETE CASCADE,
    cv_id UUID REFERENCES cv(id) ON DELETE SET NULL,
    date_candidature TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    statut VARCHAR(50) DEFAULT 'en_attente' CHECK (statut IN ('en_attente', 'en_cours', 'acceptee', 'refusee', 'annulee')),
    score_compatibilite DECIMAL(5, 2), -- Score de 0 à 100 calculé par IA
    lettre_motivation TEXT,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(chercheur_id, offre_id) -- Un chercheur ne peut postuler qu'une fois à une offre
);

CREATE INDEX idx_candidatures_chercheur ON candidatures(chercheur_id);
CREATE INDEX idx_candidatures_offre ON candidatures(offre_id);
CREATE INDEX idx_candidatures_statut ON candidatures(statut);
CREATE INDEX idx_candidatures_score ON candidatures(score_compatibilite DESC);

-- ============================================================
-- TABLE: statistiques (pour l'administrateur)
-- ============================================================
CREATE TABLE IF NOT EXISTS statistiques (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date_collecte DATE DEFAULT CURRENT_DATE,
    nombre_chercheurs INTEGER DEFAULT 0,
    nombre_entreprises INTEGER DEFAULT 0,
    nombre_offres_actives INTEGER DEFAULT 0,
    nombre_candidatures INTEGER DEFAULT 0,
    nombre_candidatures_acceptees INTEGER DEFAULT 0,
    nombre_cv_analyses INTEGER DEFAULT 0,
    UNIQUE(date_collecte)
);

-- ============================================================
-- TABLE: signalements (pour la modération)
-- ============================================================
CREATE TABLE IF NOT EXISTS signalements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    utilisateur_signalant_id UUID REFERENCES utilisateurs(id) ON DELETE SET NULL,
    type_objet VARCHAR(50) NOT NULL, -- 'offre', 'profil', 'candidature'
    objet_id UUID NOT NULL,
    raison TEXT NOT NULL,
    statut VARCHAR(50) DEFAULT 'en_attente' CHECK (statut IN ('en_attente', 'traite', 'rejete')),
    date_signalement TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_traitement TIMESTAMP,
    admin_traitant_id UUID REFERENCES administrateurs(id) ON DELETE SET NULL
);

CREATE INDEX idx_signalements_statut ON signalements(statut);
CREATE INDEX idx_signalements_type ON signalements(type_objet, objet_id);

-- ============================================================
-- TRIGGERS: Mise à jour automatique de date_modification
-- ============================================================
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.date_modification = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Application des triggers
CREATE TRIGGER update_utilisateurs_modtime BEFORE UPDATE ON utilisateurs
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_chercheurs_modtime BEFORE UPDATE ON chercheurs_emploi
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_entreprises_modtime BEFORE UPDATE ON entreprises
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_cv_modtime BEFORE UPDATE ON cv
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_offres_modtime BEFORE UPDATE ON offres_emploi
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_candidatures_modtime BEFORE UPDATE ON candidatures
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- ============================================================
-- POLITIQUES RLS (Row Level Security) - À configurer selon besoins
-- ============================================================
-- Note: Activez RLS dans Supabase Dashboard et configurez les politiques selon vos besoins de sécurité

-- Exemple de politique pour les utilisateurs (à adapter)
ALTER TABLE utilisateurs ENABLE ROW LEVEL SECURITY;

-- Les utilisateurs peuvent voir leur propre profil
CREATE POLICY "Users can view own profile" ON utilisateurs
    FOR SELECT USING (auth.uid()::text = id::text);

-- Les utilisateurs peuvent modifier leur propre profil
CREATE POLICY "Users can update own profile" ON utilisateurs
    FOR UPDATE USING (auth.uid()::text = id::text);

-- ============================================================
-- VUES UTILES
-- ============================================================

-- Vue pour les offres avec informations entreprise
CREATE OR REPLACE VIEW v_offres_completes AS
SELECT 
    o.*,
    e.nom_entreprise,
    e.secteur_activite,
    u.email as email_entreprise,
    COUNT(c.id) as nombre_candidatures
FROM offres_emploi o
JOIN entreprises e ON o.entreprise_id = e.id
JOIN utilisateurs u ON e.utilisateur_id = u.id
LEFT JOIN candidatures c ON o.id = c.offre_id
WHERE o.statut = 'active'
GROUP BY o.id, e.id, u.id;

-- Vue pour les candidatures avec détails
CREATE OR REPLACE VIEW v_candidatures_completes AS
SELECT 
    c.*,
    ch.utilisateur_id as chercheur_user_id,
    u_chercheur.nom as nom_chercheur,
    u_chercheur.email as email_chercheur,
    o.titre as titre_offre,
    o.entreprise_id,
    e.nom_entreprise
FROM candidatures c
JOIN chercheurs_emploi ch ON c.chercheur_id = ch.id
JOIN utilisateurs u_chercheur ON ch.utilisateur_id = u_chercheur.id
JOIN offres_emploi o ON c.offre_id = o.id
JOIN entreprises e ON o.entreprise_id = e.id;

-- ============================================================
-- FIN DU SCHEMA
-- ============================================================

