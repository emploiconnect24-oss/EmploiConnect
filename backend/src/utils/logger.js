/**
 * Logger simple et centralisé pour le backend
 * - Préfixe les messages avec le niveau et un timestamp ISO
 * - Permet d'uniformiser les logs (utile en démo / prod)
 */

function formatMessage(level, message) {
  const ts = new Date().toISOString();
  return `[${ts}] [${level}] ${message}`;
}

export function logInfo(message, meta) {
  if (meta) {
    console.log(formatMessage('INFO', message), meta);
  } else {
    console.log(formatMessage('INFO', message));
  }
}

export function logWarn(message, meta) {
  if (meta) {
    console.warn(formatMessage('WARN', message), meta);
  } else {
    console.warn(formatMessage('WARN', message));
  }
}

export function logError(message, meta) {
  if (meta) {
    console.error(formatMessage('ERROR', message), meta);
  } else {
    console.error(formatMessage('ERROR', message));
  }
}

