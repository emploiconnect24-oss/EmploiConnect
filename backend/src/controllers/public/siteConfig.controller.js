import { supabase } from '../../config/supabase.js';

function isFetchFailedError(err) {
  const msg = String(err?.message || '').toLowerCase();
  return msg.includes('fetch failed') || msg.includes('network') || err?.name === 'TypeError';
}

const defaultGeneralConfig = {
  nom_plateforme: 'EmploiConnect',
  logo_url: '',
  favicon_url: '',
  couleur_primaire: '#1A56DB',
  description_plateforme: 'Plateforme intelligente d\'offres et de recherche d\'emploi en Guinée',
  email_contact: '',
  telephone_contact: '',
  adresse_contact: '',
  mode_maintenance: 'false',
  message_maintenance: '',
};

const defaultFooterConfig = {
  footer_email: 'contact@example.com',
  footer_telephone: '+224 620 00 00 00',
  footer_adresse: 'Conakry, Guinée',
  footer_tagline: 'Plateforme intelligente de l\'emploi',
  footer_linkedin: '',
  footer_facebook: '',
  footer_twitter: '',
  footer_instagram: '',
  footer_whatsapp: '',
  /** Renseigné depuis `nom_plateforme` (onglet Général) pour copyright / cohérence. */
  platform_name: 'EmploiConnect',
};

export async function getFooterConfig(req, res) {
  try {
    const { data, error } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .eq('categorie', 'footer');

    if (error) {
      console.error('[GET /config/footer] Erreur:', error.message);
      return res.json({ success: true, data: defaultFooterConfig });
    }

    const result = { ...defaultFooterConfig };
    (data || []).forEach((p) => {
      result[p.cle] = p.valeur;
    });

    const { data: genRows, error: genErr } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .in('cle', [
        'email_contact',
        'telephone_contact',
        'adresse_contact',
        'nom_plateforme',
        'description_plateforme',
      ]);
    const gen = {};
    if (!genErr) {
      (genRows || []).forEach((p) => {
        gen[p.cle] = p.valeur;
      });
    }
    const trim = (v) => String(v ?? '').trim();
    /** L’onglet Général prime lorsque les champs sont renseignés (même source que le footer public). */
    if (trim(gen.email_contact)) result.footer_email = trim(gen.email_contact);
    if (trim(gen.telephone_contact)) result.footer_telephone = trim(gen.telephone_contact);
    if (trim(gen.adresse_contact)) result.footer_adresse = trim(gen.adresse_contact);
    if (trim(gen.description_plateforme)) {
      result.footer_tagline = trim(gen.description_plateforme);
    }
    if (trim(gen.nom_plateforme)) {
      result.platform_name = trim(gen.nom_plateforme);
    }

    return res.json({ success: true, data: result });
  } catch (err) {
    if (isFetchFailedError(err)) {
      console.warn('[GET /config/footer] Supabase indisponible, fallback par défaut.');
    } else {
      console.error('[GET /config/footer] Exception:', err.message);
    }
    return res.json({ success: true, data: defaultFooterConfig });
  }
}

export async function getGeneralConfig(req, res) {
  try {
    const { data, error } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .in('cle', [
        'nom_plateforme',
        'logo_url',
        'favicon_url',
        'couleur_primaire',
        'description_plateforme',
        'email_contact',
        'telephone_contact',
        'adresse_contact',
        'mode_maintenance',
        'message_maintenance',
      ]);

    if (error) {
      console.error('[GET /config/general] Erreur:', error.message);
      return res.json({ success: true, data: defaultGeneralConfig });
    }

    const result = { ...defaultGeneralConfig };
    (data || []).forEach((p) => {
      result[p.cle] = p.valeur;
    });

    return res.json({ success: true, data: result });
  } catch (err) {
    if (isFetchFailedError(err)) {
      console.warn('[GET /config/general] Supabase indisponible, fallback par défaut.');
    } else {
      console.error('[GET /config/general] Exception:', err.message);
    }
    return res.json({ success: true, data: defaultGeneralConfig });
  }
}
