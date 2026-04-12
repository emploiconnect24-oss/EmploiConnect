/**
 * Tâches planifiées (résumé hebdomadaire). Désactiver : DISABLE_CRON=1
 */
let started = false;

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
    console.log(`[cron] Illustration IA : chaque jour ${hourIllus}h (Africa/Conakry)`);
  } catch (e) {
    console.warn('[cron] node-cron indisponible — installez la dépendance :', e.message);
  }
}
