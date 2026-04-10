/**
 * Créateur CV — génération PDF côté serveur (PRD §7)
 */
import { Router } from 'express';
import PDFDocument from 'pdfkit';
import { supabase, BUCKET_CV } from '../../config/supabase.js';
import { authenticate, requireRole } from '../../middleware/auth.js';
import { attachProfileIds } from '../../helpers/userProfile.js';
import { ROLES } from '../../config/constants.js';
import { createCvSignedUrl } from '../../helpers/cvSignedUrl.js';

const router = Router();
router.use(authenticate);
router.use(attachProfileIds);

const PDF_SIGN_TTL_SEC = 7 * 24 * 3600;

function buildPdfBuffer(payload) {
  const {
    nom,
    titre,
    email,
    telephone,
    ville,
    linkedin,
    resume,
    experiences,
    formations,
    competences,
    langues,
  } = payload;

  return new Promise((resolve, reject) => {
    const chunks = [];
    const doc = new PDFDocument({ margin: 48, size: 'A4' });
    doc.on('data', (c) => chunks.push(c));
    doc.on('error', reject);
    doc.on('end', () => resolve(Buffer.concat(chunks)));

    const BLEU = '#1A56DB';
    const BLEU_CLAIR = '#EFF6FF';
    const GRIS = '#64748B';
    const NOIR = '#0F172A';

    doc.rect(0, 0, 595, 120).fill(BLEU);
    doc.fillColor('#FFFFFF').font('Helvetica-Bold').fontSize(22).text(String(nom || '').toUpperCase(), 48, 36, { width: 500 });
    doc.fillColor('#E2E8F0').font('Helvetica').fontSize(13).text(String(titre || ''), 48, 64, { width: 500 });
    const contactLine = [
      email ? `Email: ${email}` : '',
      telephone ? `Tel: ${telephone}` : '',
      ville ? `Ville: ${ville}` : '',
      linkedin ? `LinkedIn: ${linkedin}` : '',
    ].filter(Boolean).join('  |  ');
    doc.fontSize(9).fillColor('#CBD5E1').text(contactLine, 48, 92, { width: 500 });

    let y = 140;

    if (String(resume || '').trim()) {
      doc.fillColor(BLEU).font('Helvetica-Bold').fontSize(12).text('PROFIL PROFESSIONNEL', 48, y);
      doc.moveTo(48, y + 16).lineTo(547, y + 16).stroke('#CBD5E1');
      y += 28;
      doc.fillColor(GRIS).font('Helvetica').fontSize(10).text(String(resume).trim(), 48, y, { width: 499, lineGap: 3 });
      y += doc.heightOfString(String(resume).trim(), { width: 499 }) + 20;
    }

    const exps = Array.isArray(experiences) ? experiences : [];
    if (exps.length > 0) {
      doc.fillColor(BLEU).font('Helvetica-Bold').fontSize(12).text('EXPÉRIENCES PROFESSIONNELLES', 48, y);
      doc.moveTo(48, y + 16).lineTo(547, y + 16).stroke('#CBD5E1');
      y += 28;
      for (const exp of exps) {
        const t = exp.titre || exp.poste || '';
        const ent = exp.entreprise || '';
        doc.fillColor(NOIR).font('Helvetica-Bold').fontSize(11).text(t, 48, y);
        doc.fillColor(BLEU).font('Helvetica').fontSize(10).text(ent, 48, y + 14);
        y += 28;
        if (exp.description || exp.mission) {
          const d = String(exp.description || exp.mission || '');
          doc.fillColor(GRIS).font('Helvetica').fontSize(9).text(d, 48, y, { width: 499 });
          y += doc.heightOfString(d, { width: 499 }) + 10;
        } else {
          y += 6;
        }
      }
      y += 8;
    }

    const forms = Array.isArray(formations) ? formations : [];
    if (forms.length > 0) {
      doc.fillColor(BLEU).font('Helvetica-Bold').fontSize(12).text('FORMATIONS', 48, y);
      doc.moveTo(48, y + 16).lineTo(547, y + 16).stroke('#CBD5E1');
      y += 28;
      for (const f of forms) {
        const dip = f.diplome || f.titre || '';
        const ec = f.ecole || f.etablissement || '';
        doc.fillColor(NOIR).font('Helvetica-Bold').fontSize(10).text(dip, 48, y);
        doc.fillColor(GRIS).font('Helvetica').fontSize(9).text(ec, 48, y + 12);
        y += 28;
      }
      y += 8;
    }

    const comps = Array.isArray(competences) ? competences : [];
    if (comps.length > 0) {
      doc.fillColor(BLEU).font('Helvetica-Bold').fontSize(12).text('COMPÉTENCES', 48, y);
      doc.moveTo(48, y + 16).lineTo(547, y + 16).stroke('#CBD5E1');
      y += 26;
      let x = 48;
      for (const comp of comps.slice(0, 16)) {
        const label = typeof comp === 'string' ? comp : (comp.nom || comp.name || '');
        if (!label) continue;
        const w = doc.widthOfString(label) + 16;
        if (x + w > 540) {
          x = 48;
          y += 22;
        }
        doc.roundedRect(x, y, w, 18, 4).fill(BLEU_CLAIR);
        doc.fillColor(BLEU).font('Helvetica').fontSize(9).text(label, x + 8, y + 4);
        x += w + 6;
      }
      y += 28;
    }

    const langs = Array.isArray(langues) ? langues : [];
    if (langs.length > 0) {
      doc.fillColor(BLEU).font('Helvetica-Bold').fontSize(12).text('LANGUES', 48, y);
      doc.moveTo(48, y + 16).lineTo(547, y + 16).stroke('#CBD5E1');
      y += 24;
      const line = langs
        .map((l) => (typeof l === 'string' ? l : `${l.name || ''} (${l.level || l.niveau || ''})`.trim()))
        .filter(Boolean)
        .join(' · ');
      doc.fillColor(GRIS).font('Helvetica').fontSize(10).text(line, 48, y, { width: 499 });
    }

    doc.end();
  });
}

router.post('/generer-pdf', requireRole(ROLES.CHERCHEUR), async (req, res) => {
  try {
    const {
      nom,
      titre,
      email,
      telephone,
      ville,
      linkedin,
      resume,
      photo_url: photoUrl,
      experiences,
      formations,
      competences,
      langues,
    } = req.body;

    if (!String(nom || '').trim() || !String(titre || '').trim()) {
      return res.status(400).json({
        success: false,
        message: 'Nom et titre professionnels requis',
      });
    }

    let chercheurId = req.chercheurId;
    if (!chercheurId) {
      const { data: created, error: insErr } = await supabase
        .from('chercheurs_emploi')
        .insert({ utilisateur_id: req.user.id })
        .select('id')
        .single();
      if (insErr || !created) {
        return res.status(404).json({
          success: false,
          message: 'Profil candidat non trouvé',
        });
      }
      chercheurId = created.id;
    }

    const compLabels = (Array.isArray(competences) ? competences : [])
      .map((c) => (typeof c === 'string' ? c : (c?.nom || c?.name || '').toString().trim()))
      .filter(Boolean);

    const aboutFinal = String(resume || '').trim().slice(0, 500);

    const experiencesFormattees = Array.isArray(experiences)
      ? experiences.map((e) => ({
        poste: e.poste || e.titre || '',
        titre: e.titre || e.poste || '',
        entreprise: e.entreprise || '',
        ville: e.ville || '',
        periode: e.periode || e.duree || [e.date_debut, e.date_fin].filter(Boolean).join(' — '),
        mission: e.mission || e.description || '',
        description: e.description || e.mission || '',
      }))
      : [];

    const formationsFormattees = Array.isArray(formations)
      ? formations.map((f) => ({
        diplome: f.diplome || f.titre || '',
        titre: f.titre || f.diplome || '',
        ecole: f.ecole || '',
        ville: f.ville || '',
        annee: f.annee || f.end_date || '',
      }))
      : [];

    const languesFinales = Array.isArray(langues) && langues.length > 0
      ? langues
        .map((l) => (typeof l === 'string' ? l : String(l.name || l.nom || '').trim()))
        .filter(Boolean)
      : ['Français'];

    await supabase.from('chercheurs_emploi').update({
      titre_poste: String(titre).trim(),
      about: aboutFinal || null,
      competences: compLabels,
      experiences: experiencesFormattees,
      formations: formationsFormattees,
      langues: languesFinales,
    }).eq('id', chercheurId);
    console.log('[generer-pdf] Profil mis à jour — comps:', compLabels.length, 'exps:', experiencesFormattees.length);

    await supabase
      .from('utilisateurs')
      .update({
        nom: String(nom).trim(),
        telephone: telephone ? String(telephone).trim() : null,
        adresse: ville ? String(ville).trim() : null,
      })
      .eq('id', req.user.id);

    const pdfBuffer = await buildPdfBuffer({
      nom,
      titre,
      email,
      telephone,
      ville,
      linkedin,
      resume,
      experiences,
      formations,
      competences,
      langues,
    });

    const safeName = String(nom).replace(/[^a-zA-Z0-9_-]/g, '_');
    const storagePath = `${chercheurId}/cv-genere-${Date.now()}.pdf`;

    const { error: upErr } = await supabase.storage.from(BUCKET_CV).upload(storagePath, pdfBuffer, {
      contentType: 'application/pdf',
      upsert: true,
    });

    if (upErr) {
      console.error('[generer-pdf] upload', upErr);
      return res.status(500).json({
        success: false,
        message: `Erreur upload: ${upErr.message}`,
      });
    }

    const { signedUrl, error: signErr } = await createCvSignedUrl(storagePath, PDF_SIGN_TTL_SEC);
    if (signErr || !signedUrl) {
      console.error('[generer-pdf] signed url', signErr);
      return res.status(500).json({
        success: false,
        message: 'Impossible de générer le lien de téléchargement',
      });
    }

    const nomFichier = `CV_${safeName}.pdf`;
    const competencesExtrait = {
      competences: compLabels.slice(0, 20),
      experience: Array.isArray(experiences) ? experiences : [],
      formation: Array.isArray(formations) ? formations : [],
      langues: languesFinales,
      resume_profil: aboutFinal,
      source: 'plateforme_cv_builder',
      analyse_le: new Date().toISOString(),
      photo_url_hint: photoUrl || null,
    };

    const { data: existing } = await supabase.from('cv').select('id').eq('chercheur_id', chercheurId).maybeSingle();

    const cvPayload = {
      chercheur_id: chercheurId,
      fichier_url: storagePath,
      nom_fichier: nomFichier,
      type_fichier: 'PDF',
      taille_fichier: pdfBuffer.length,
      competences_extrait: competencesExtrait,
      date_upload: new Date().toISOString(),
    };

    if (existing?.id) {
      const { error: uErr } = await supabase.from('cv').update(cvPayload).eq('chercheur_id', chercheurId);
      if (uErr) console.error('[generer-pdf] cv update', uErr);
    } else {
      const { error: iErr } = await supabase.from('cv').insert(cvPayload);
      if (iErr) console.error('[generer-pdf] cv insert', iErr);
    }

    return res.json({
      success: true,
      message: 'CV généré et profil mis à jour automatiquement',
      data: {
        pdf_url: signedUrl,
        nom_fichier: nomFichier,
        profil_mis_a_jour: true,
      },
    });
  } catch (err) {
    console.error('[generer-pdf]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
});

export default router;
