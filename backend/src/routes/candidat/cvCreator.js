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

async function buildPdfBuffer(payload) {
  const {
    nom,
    titre,
    email,
    telephone,
    ville,
    linkedin,
    resume,
    photo_url: photoUrl,
    modele_cv: modeleCv = 'moderne',
    experiences,
    formations,
    competences,
    langues,
  } = payload;

  const model = String(modeleCv || 'moderne').toLowerCase();
  const showPhoto = model === 'moderne' || model === 'elegant';

  let photoBuffer = null;
  if (showPhoto && String(photoUrl || '').startsWith('http')) {
    try {
      const response = await fetch(photoUrl);
      if (response.ok) {
        const arr = await response.arrayBuffer();
        photoBuffer = Buffer.from(arr);
      }
    } catch (_) {}
  }

  return new Promise((resolve, reject) => {
    const chunks = [];
    const doc = new PDFDocument({ margin: 48, size: 'A4' });
    doc.on('data', (c) => chunks.push(c));
    doc.on('error', reject);
    doc.on('end', () => resolve(Buffer.concat(chunks)));

    const GRIS = '#64748B';
    const NOIR = '#0F172A';
    const BLEU = '#1A56DB';
    const VIOLET = '#6D28D9';
    const BLEU_CLAIR = '#EFF6FF';
    const exps = Array.isArray(experiences) ? experiences : [];
    const forms = Array.isArray(formations) ? formations : [];
    const comps = Array.isArray(competences) ? competences : [];
    const langs = Array.isArray(langues) ? langues : [];

    const ensureSpace = (y, needed = 70) => {
      if (y + needed <= 780) return y;
      doc.addPage();
      return 52;
    };
    const contactLine = [
      email ? `Email: ${email}` : '',
      telephone ? `Tel: ${telephone}` : '',
      ville ? `Ville: ${ville}` : '',
      linkedin ? `LinkedIn: ${linkedin}` : '',
    ].filter(Boolean).join('  |  ');

    if (model === 'classique') {
      doc.rect(0, 0, 595, 112).fill('#0F172A');
      doc.fillColor('#FFFFFF').font('Helvetica-Bold').fontSize(24).text(String(nom || '').toUpperCase(), 48, 34, { width: 500 });
      doc.fillColor('#CBD5E1').font('Helvetica').fontSize(12).text(String(titre || ''), 48, 66, { width: 500 });
      doc.fontSize(9).text(contactLine, 48, 86, { width: 500 });
      let y = 132;
      if (String(resume || '').trim()) {
        doc.fillColor(NOIR).font('Helvetica-Bold').fontSize(12).text('PROFIL', 48, y);
        y += 18;
        doc.fillColor(GRIS).font('Helvetica').fontSize(10).text(String(resume).trim(), 48, y, { width: 499, lineGap: 3 });
        y += doc.heightOfString(String(resume).trim(), { width: 499 }) + 18;
      }
      if (exps.length) {
        y = ensureSpace(y);
        doc.fillColor(NOIR).font('Helvetica-Bold').fontSize(12).text('EXPERIENCES', 48, y);
        y += 18;
        for (const exp of exps) {
          y = ensureSpace(y);
          const t = exp.titre || exp.poste || '';
          const ent = exp.entreprise || '';
          doc.fillColor(NOIR).font('Helvetica-Bold').fontSize(11).text(t, 48, y, { width: 499 });
          y += 13;
          doc.fillColor(GRIS).font('Helvetica-Oblique').fontSize(9).text(ent, 48, y, { width: 499 });
          y += 12;
          const d = String(exp.description || exp.mission || '').trim();
          if (d) {
            doc.fillColor(GRIS).font('Helvetica').fontSize(9).text(d, 48, y, { width: 499 });
            y += doc.heightOfString(d, { width: 499 }) + 10;
          }
        }
      }
      if (forms.length) {
        y = ensureSpace(y);
        doc.fillColor(NOIR).font('Helvetica-Bold').fontSize(12).text('FORMATIONS', 48, y);
        y += 18;
        for (const f of forms) {
          const dip = f.diplome || f.titre || '';
          const ec = f.ecole || f.etablissement || '';
          doc.fillColor(NOIR).font('Helvetica-Bold').fontSize(10).text(dip, 48, y);
          doc.fillColor(GRIS).font('Helvetica').fontSize(9).text(ec, 48, y + 12);
          y += 30;
        }
      }
      if (comps.length || langs.length) {
        y = ensureSpace(y);
        if (comps.length) {
          const line = comps
            .map((c) => (typeof c === 'string' ? c : (c.nom || c.name || '')))
            .filter(Boolean)
            .slice(0, 18)
            .join(' · ');
          doc.fillColor(NOIR).font('Helvetica-Bold').fontSize(11).text('COMPETENCES', 48, y);
          y += 16;
          doc.fillColor(GRIS).font('Helvetica').fontSize(9).text(line, 48, y, { width: 499 });
          y += doc.heightOfString(line, { width: 499 }) + 12;
        }
        if (langs.length) {
          const line = langs
            .map((l) => (typeof l === 'string' ? l : `${l.name || ''} (${l.level || l.niveau || ''})`.trim()))
            .filter(Boolean)
            .join(' · ');
          doc.fillColor(NOIR).font('Helvetica-Bold').fontSize(11).text('LANGUES', 48, y);
          y += 16;
          doc.fillColor(GRIS).font('Helvetica').fontSize(9).text(line, 48, y, { width: 499 });
        }
      }
    } else if (model === 'elegant') {
      const sideW = 172;
      doc.rect(0, 0, sideW, 842).fill('#111827');
      doc.fillColor('#FFFFFF').font('Helvetica-Bold').fontSize(18).text(String(nom || '').toUpperCase(), 20, 38, { width: sideW - 28 });
      doc.fillColor('#A5B4FC').font('Helvetica').fontSize(11).text(String(titre || ''), 20, 66, { width: sideW - 28 });
      if (photoBuffer) {
        try {
          doc.save();
          doc.circle(86, 132, 42).clip();
          doc.image(photoBuffer, 44, 90, { width: 84, height: 84, fit: [84, 84] });
          doc.restore();
        } catch (_) {}
      }
      let sy = photoBuffer ? 188 : 110;
      doc.fillColor('#C7D2FE').font('Helvetica-Bold').fontSize(10).text('CONTACT', 20, sy);
      sy += 14;
      doc.fillColor('#E5E7EB').font('Helvetica').fontSize(9).text([email, telephone, ville, linkedin].filter(Boolean).join('\n'), 20, sy, { width: sideW - 28, lineGap: 2 });
      sy += 70;
      if (comps.length) {
        doc.fillColor('#C7D2FE').font('Helvetica-Bold').fontSize(10).text('COMPETENCES', 20, sy);
        sy += 14;
        for (const c of comps.slice(0, 12)) {
          const label = typeof c === 'string' ? c : (c.nom || c.name || '');
          if (!label) continue;
          doc.fillColor('#E5E7EB').font('Helvetica').fontSize(9).text(`• ${label}`, 20, sy, { width: sideW - 28 });
          sy += 12;
        }
      }
      if (langs.length) {
        sy += 8;
        doc.fillColor('#C7D2FE').font('Helvetica-Bold').fontSize(10).text('LANGUES', 20, sy);
        sy += 14;
        for (const l of langs.slice(0, 8)) {
          const label = typeof l === 'string' ? l : `${l.name || ''} (${l.level || l.niveau || ''})`;
          doc.fillColor('#E5E7EB').font('Helvetica').fontSize(9).text(`• ${label}`, 20, sy, { width: sideW - 28 });
          sy += 12;
        }
      }

      const x0 = sideW + 22;
      let y = 40;
      if (String(resume || '').trim()) {
        doc.fillColor(VIOLET).font('Helvetica-Bold').fontSize(12).text('PROFIL PROFESSIONNEL', x0, y);
        y += 20;
        doc.fillColor(GRIS).font('Helvetica').fontSize(10).text(String(resume).trim(), x0, y, { width: 595 - x0 - 26, lineGap: 3 });
        y += doc.heightOfString(String(resume).trim(), { width: 595 - x0 - 26 }) + 16;
      }
      if (exps.length) {
        y = ensureSpace(y);
        doc.fillColor(VIOLET).font('Helvetica-Bold').fontSize(12).text('EXPERIENCES', x0, y);
        y += 20;
        for (const exp of exps) {
          y = ensureSpace(y);
          doc.circle(x0 + 3, y + 5, 2).fill(VIOLET);
          doc.fillColor(NOIR).font('Helvetica-Bold').fontSize(11).text(exp.titre || exp.poste || '', x0 + 12, y, { width: 595 - x0 - 34 });
          y += 13;
          doc.fillColor(VIOLET).font('Helvetica').fontSize(9).text(exp.entreprise || '', x0 + 12, y);
          y += 12;
          const d = String(exp.description || exp.mission || '').trim();
          if (d) {
            doc.fillColor(GRIS).font('Helvetica').fontSize(9).text(d, x0 + 12, y, { width: 595 - x0 - 34 });
            y += doc.heightOfString(d, { width: 595 - x0 - 34 }) + 10;
          }
        }
      }
      if (forms.length) {
        y = ensureSpace(y);
        doc.fillColor(VIOLET).font('Helvetica-Bold').fontSize(12).text('FORMATIONS', x0, y);
        y += 20;
        for (const f of forms) {
          doc.fillColor(NOIR).font('Helvetica-Bold').fontSize(10).text(f.diplome || f.titre || '', x0, y);
          doc.fillColor(GRIS).font('Helvetica').fontSize(9).text(f.ecole || f.etablissement || '', x0, y + 12);
          y += 30;
        }
      }
    } else {
      const compactMode = model === 'compact';
      const accent = BLEU;
      const headerBg = accent;
      doc.rect(0, 0, 595, compactMode ? 100 : 120).fill(headerBg);
      doc.fillColor('#FFFFFF').font('Helvetica-Bold').fontSize(compactMode ? 20 : 22).text(String(nom || '').toUpperCase(), 48, compactMode ? 30 : 36, { width: showPhoto ? 420 : 500 });
      doc.fillColor('#E2E8F0').font('Helvetica').fontSize(compactMode ? 11 : 13).text(String(titre || ''), 48, compactMode ? 56 : 64, { width: showPhoto ? 420 : 500 });
      doc.fontSize(9).fillColor('#CBD5E1').text(contactLine, 48, compactMode ? 80 : 92, { width: showPhoto ? 420 : 500 });
      if (showPhoto) {
        const px = 490;
        const py = compactMode ? 22 : 26;
        doc.save();
        doc.circle(px + 32, py + 32, 32).clip();
        if (photoBuffer) {
          try {
            doc.image(photoBuffer, px, py, { width: 64, height: 64, fit: [64, 64] });
          } catch (_) {
            doc.rect(px, py, 64, 64).fill('#DBEAFE');
          }
        } else {
          doc.rect(px, py, 64, 64).fill('#DBEAFE');
        }
        doc.restore();
      }
      let y = compactMode ? 116 : 140;
      if (String(resume || '').trim()) {
        doc.fillColor(accent).font('Helvetica-Bold').fontSize(12).text('PROFIL PROFESSIONNEL', 48, y);
        doc.moveTo(48, y + 16).lineTo(547, y + 16).stroke('#CBD5E1');
        y += compactMode ? 24 : 28;
        doc.fillColor(GRIS).font('Helvetica').fontSize(compactMode ? 9 : 10).text(String(resume).trim(), 48, y, { width: 499, lineGap: compactMode ? 2 : 3 });
        y += doc.heightOfString(String(resume).trim(), { width: 499 }) + (compactMode ? 14 : 20);
      }
      if (exps.length) {
        doc.fillColor(accent).font('Helvetica-Bold').fontSize(12).text('EXPÉRIENCES PROFESSIONNELLES', 48, y);
        doc.moveTo(48, y + 16).lineTo(547, y + 16).stroke('#CBD5E1');
        y += compactMode ? 24 : 28;
        for (const exp of exps) {
          y = ensureSpace(y);
          const t = exp.titre || exp.poste || '';
          const ent = exp.entreprise || '';
          doc.fillColor(NOIR).font('Helvetica-Bold').fontSize(11).text(t, 48, y);
          doc.fillColor(accent).font('Helvetica').fontSize(10).text(ent, 48, y + 14);
          y += compactMode ? 24 : 28;
          const d = String(exp.description || exp.mission || '').trim();
          if (d) {
            doc.fillColor(GRIS).font('Helvetica').fontSize(9).text(d, 48, y, { width: 499 });
            y += doc.heightOfString(d, { width: 499 }) + (compactMode ? 6 : 10);
          }
        }
        y += compactMode ? 4 : 8;
      }
      if (forms.length) {
        y = ensureSpace(y);
        doc.fillColor(accent).font('Helvetica-Bold').fontSize(12).text('FORMATIONS', 48, y);
        doc.moveTo(48, y + 16).lineTo(547, y + 16).stroke('#CBD5E1');
        y += compactMode ? 24 : 28;
        for (const f of forms) {
          const dip = f.diplome || f.titre || '';
          const ec = f.ecole || f.etablissement || '';
          doc.fillColor(NOIR).font('Helvetica-Bold').fontSize(10).text(dip, 48, y);
          doc.fillColor(GRIS).font('Helvetica').fontSize(9).text(ec, 48, y + 12);
          y += compactMode ? 24 : 28;
        }
      }
      if (comps.length) {
        y = ensureSpace(y);
        doc.fillColor(accent).font('Helvetica-Bold').fontSize(12).text('COMPÉTENCES', 48, y);
        doc.moveTo(48, y + 16).lineTo(547, y + 16).stroke('#CBD5E1');
        y += compactMode ? 22 : 26;
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
          doc.fillColor(accent).font('Helvetica').fontSize(9).text(label, x + 8, y + 4);
          x += w + 6;
        }
        y += compactMode ? 22 : 28;
      }
      if (langs.length) {
        y = ensureSpace(y, 40);
        doc.fillColor(accent).font('Helvetica-Bold').fontSize(12).text('LANGUES', 48, y);
        doc.moveTo(48, y + 16).lineTo(547, y + 16).stroke('#CBD5E1');
        y += 24;
        const line = langs
          .map((l) => (typeof l === 'string' ? l : `${l.name || ''} (${l.level || l.niveau || ''})`.trim()))
          .filter(Boolean)
          .join(' · ');
        doc.fillColor(GRIS).font('Helvetica').fontSize(10).text(line, 48, y, { width: 499 });
      }
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
      modele_cv: modeleCv,
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

    const aboutFinal = String(resume || '').trim().slice(0, 1000);

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
      photo_url: photoUrl,
      modele_cv: modeleCv,
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
