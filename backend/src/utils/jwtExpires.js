/**
 * Durée JWT : min(jwt_expiration_heures, duree_session_minutes) quand les deux sont définis.
 * Sinon la valeur disponible, sinon envDefault (ex. JWT_EXPIRES_IN).
 */
export function resolveJwtExpiresIn(secParams, envDefault) {
  const jwtH = parseInt(String(secParams?.jwt_expiration_heures ?? ''), 10);
  const sessM = parseInt(String(secParams?.duree_session_minutes ?? ''), 10);
  const jwtSec = Number.isFinite(jwtH) && jwtH > 0 ? jwtH * 3600 : null;
  const sessSec = Number.isFinite(sessM) && sessM > 0 ? sessM * 60 : null;

  if (jwtSec == null && sessSec == null) {
    return envDefault ?? '7d';
  }
  if (jwtSec != null && sessSec != null) {
    const m = Math.min(jwtSec, sessSec);
    return Math.max(m, 60);
  }
  if (sessSec != null) {
    return Math.max(sessSec, 60);
  }
  return `${jwtH}h`;
}

export function parseSessionIdleMinutes(secParams) {
  const sessM = parseInt(String(secParams?.duree_session_minutes ?? ''), 10);
  return Number.isFinite(sessM) && sessM > 0 ? sessM : null;
}
