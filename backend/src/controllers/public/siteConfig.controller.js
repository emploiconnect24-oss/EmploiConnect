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
  mode_maintenance: 'false',
  message_maintenance: '',
};

const defaultFooterConfig = {
  footer_email: 'contact@emploiconnect.gn',
  footer_telephone: '+224 620 00 00 00',
  footer_adresse: 'Conakry, Guinée',
  footer_tagline: 'Plateforme intelligente de l\'emploi',
  footer_linkedin: '',
  footer_facebook: '',
  footer_twitter: '',
  footer_instagram: '',
  footer_whatsapp: '',
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
