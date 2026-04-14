/**
 * Tâches planifiées (résumé hebdomadaire + newsletter IA + illustrations IA).
 * Désactiver : DISABLE_CRON=1
 */
let started = false;

export async function executer(task) {
  const t = String(task || '').trim().toLowerCase();
  if (t === 'resume_hebdo' || t === 'weekly_digest') {
    const m = await import('./weeklyDigest.service.js');
    await m.runWeeklyDigestJob();
    return { success: true, task: 'resume_hebdo' };
  }
  if (t === 'newsletter_ia_auto') {
    const m = await import('./newsletterIa.service.js');
    const r = await m.verifierEtEnvoyerAuto();
    return { success: true, task: 'newsletter_ia_auto', result: r };
  }
  if (t === 'newsletter_ia_hebdo') {
    const m = await import('./newsletterIa.service.js');
    const r = await m.genererEtEnvoyerNewsletter('hebdomadaire');
    return { success: true, task: 'newsletter_ia_hebdo', result: r };
  }
  return { success: false, message: `Tâche inconnue: ${task}` };
}

export async function startScheduledJobs() {
  if (started) return;
  if (process.env.DISABLE_CRON === '1' || process.env.DISABLE_CRON === 'true') {
    console.log('[cron] Désactivé (DISABLE_CRON)');
    return;
  }

  try {
    const cron = (await import('node-cron')).default;
    // Lundi 08:00 — Africa/Conakry
    cron.schedule(
      '0 8 * * 1',
      () => {
        import('./weeklyDigest.service.js').then((m) => void m.runWeeklyDigestJob());
      },
      { timezone: 'Africa/Conakry' },
    );

    const { verifierEtEnvoyerAuto, genererEtEnvoyerNewsletter } = await import(
      './newsletterIa.service.js'
    );
    // Vérification toutes les 6h (nouvelles offres >= seuil).
    cron.schedule(
      '0 */6 * * *',
      () => {
        console.log('[cron] Vérification newsletter IA automatique…');
        void verifierEtEnvoyerAuto().then((r) => console.log('[cron] Newsletter IA auto:', r));
      },
      { timezone: 'Africa/Conakry' },
    );
    // Newsletter IA hebdomadaire (lundi 9h).
    cron.schedule(
      '0 9 * * 1',
      () => {
        console.log('[cron] Newsletter IA hebdomadaire…');
        void genererEtEnvoyerNewsletter('hebdomadaire').then((r) => console.log('[cron] Newsletter IA hebdo:', r));
      },
      { timezone: 'Africa/Conakry' },
    );

    const { getIllustrationCronHour, genererIllustrationsJour } = await import(
      './illustrationIa.service.js'
    );
    const hourIllus = await getIllustrationCronHour();
    cron.schedule(
      `0 ${hourIllus} * * *`,
      () => {
        console.log('[cron] Génération illustrations IA…');
        void genererIllustrationsJour().then((r) => console.log('[cron] Illustration IA:', r));
      },
      { timezone: 'Africa/Conakry' },
    );

    started = true;
    console.log('[cron] Résumé hebdomadaire : chaque lundi 8h (Africa/Conakry)');
    console.log('[cron] Newsletter IA auto : toutes les 6h (Africa/Conakry)');
    console.log('[cron] Newsletter IA hebdo : lundi 9h (Africa/Conakry)');
    console.log(`[cron] Illustration IA : chaque jour ${hourIllus}h (Africa/Conakry)`);
  } catch (e) {
    console.warn('[cron] node-cron indisponible — installez la dépendance :', e.message);
  }
}
