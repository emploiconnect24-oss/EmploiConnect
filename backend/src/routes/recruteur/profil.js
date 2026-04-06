import { Router } from 'express';
import multer from 'multer';
import sharp from 'sharp';
import { authenticate } from '../../middleware/auth.js';
import { requireRecruteur } from '../../middleware/recruteurAuth.js';
import { supabase } from '../../config/supabase.js';

const router = Router();
router.use(authenticate, requireRecruteur);

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    console.log('[Upload] Fichier reçu:', file.originalname, file.mimetype, file.size);
    cb(null, true);
  },
});

router.get('/', async (req, res) => {
  try {
    // Deux requêtes : l’embed PostgREST `utilisateur:utilisateur_id (...)` échoue si la FK
    // n’est pas exposée comme attendu → 404 alors que requireRecruteur a déjà validé l’entreprise.
    const { data: ent, error: entErr } = await supabase
      .from('entreprises')
      .select('*')
      .eq('utilisateur_id', req.user.id)
      .single();
    if (entErr || !ent) {
      console.error('[recruteur/profil GET] entreprise:', entErr?.message);
      if (req.entreprise?.id) {
        // Fallback: le middleware a déjà validé le recruteur/entreprise.
        const fallbackEnt = { id: req.entreprise.id, nom_entreprise: req.entreprise.nom_entreprise, logo_url: req.entreprise.logo_url };
        return res.json({
          success: true,
          data: {
            ...fallbackEnt,
            utilisateur: null,
            stats: { nb_offres: 0, nb_candidatures: 0 },
          },
        });
      }
      return res.status(404).json({ success: false, message: 'Profil non trouvé' });
    }

    const { data: utilisateur, error: userErr } = await supabase
      .from('utilisateurs')
      .select('id, nom, email, telephone, adresse, photo_url, est_actif, est_valide, date_creation, derniere_connexion')
      .eq('id', req.user.id)
      .maybeSingle();
    if (userErr) {
      console.error('[recruteur/profil GET] utilisateur:', userErr.message);
    }

    const { count: nbOffres } = await supabase
      .from('offres_emploi')
      .select('id', { count: 'exact', head: true })
      .eq('entreprise_id', ent.id);
    const { data: offreIds } = await supabase
      .from('offres_emploi')
      .select('id')
      .eq('entreprise_id', ent.id);
    const ids = (offreIds || []).map((o) => o.id);
    const { count: nbCandidatures } = ids.length
      ? await supabase.from('candidatures').select('id', { count: 'exact', head: true }).in('offre_id', ids)
      : { count: 0 };

    return res.json({
      success: true,
      data: {
        ...ent,
        utilisateur: utilisateur ?? null,
        stats: {
          nb_offres: nbOffres || 0,
          nb_candidatures: nbCandidatures || 0,
        },
      },
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

const ENTREPRISE_PATCHABLE = [
  'nom_entreprise', 'description', 'secteur_activite', 'taille_entreprise', 'site_web',
  'logo_url', 'adresse_siege', 'slogan', 'email_public', 'telephone_public', 'mission',
  'annee_fondation', 'banniere_url', 'linkedin', 'facebook', 'twitter', 'instagram',
  'whatsapp_business', 'valeurs', 'avantages',
];

router.patch('/', async (req, res) => {
  try {
    const body = req.body || {};
    const { nom, telephone, nom_entreprise: nomEnt } = body;
    const entUpdate = {};
    ENTREPRISE_PATCHABLE.forEach((k) => {
      if (body[k] !== undefined) entUpdate[k] = body[k];
    });
    if (Object.keys(entUpdate).length) {
      const { error } = await supabase.from('entreprises').update(entUpdate).eq('utilisateur_id', req.user.id);
      if (error) throw error;
    }
    const userUp = {};
    if (nom !== undefined) userUp.nom = nom;
    if (telephone !== undefined) userUp.telephone = telephone;
    if (nomEnt !== undefined && nom === undefined) userUp.nom = nomEnt;
    if (Object.keys(userUp).length) {
      await supabase.from('utilisateurs').update(userUp).eq('id', req.user.id);
    }
    return res.json({ success: true, message: 'Profil entreprise mis à jour avec succès' });
  } catch (err) {
    console.error('[recruteur/profil PATCH]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
});

router.post('/logo', upload.single('logo'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'Aucun fichier fourni' });
    const buffer = await sharp(req.file.buffer).resize(200, 200, { fit: 'cover' }).png().toBuffer();
    const fileName = `logo-entreprise-${req.entreprise.id}-${Date.now()}.png`;
    const { error } = await supabase.storage.from('logos').upload(fileName, buffer, { contentType: 'image/png', upsert: true });
    if (error) throw error;
    const { data } = supabase.storage.from('logos').getPublicUrl(fileName);
    await supabase.from('entreprises').update({ logo_url: data.publicUrl }).eq('utilisateur_id', req.user.id);
    return res.json({ success: true, data: { logo_url: data.publicUrl } });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur upload' });
  }
});

const uploadBanniere = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    console.log('[Upload] Fichier reçu:', file.originalname, file.mimetype, file.size);
    cb(null, true);
  },
});

router.post('/banniere', uploadBanniere.single('banniere'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'Aucun fichier fourni' });
    let buffer = req.file.buffer;
    try {
      buffer = await sharp(req.file.buffer).resize(1200, 400, { fit: 'cover' }).jpeg().toBuffer();
    } catch {
      // no-op: keep original buffer if sharp fails
    }

    const fileName = `banniere-entreprise-${req.entreprise.id}-${Date.now()}.jpg`;
    const { error } = await supabase.storage
      .from(process.env.SUPABASE_BANNIERES_BUCKET || 'bannieres')
      .upload(fileName, buffer, { contentType: 'image/jpeg', upsert: true });
    if (error) throw error;
    const { data } = supabase.storage.from(process.env.SUPABASE_BANNIERES_BUCKET || 'bannieres').getPublicUrl(fileName);
    await supabase.from('entreprises').update({ banniere_url: data.publicUrl }).eq('utilisateur_id', req.user.id);
    return res.json({ success: true, data: { banniere_url: data.publicUrl } });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur upload banniere' });
  }
});

export default router;

