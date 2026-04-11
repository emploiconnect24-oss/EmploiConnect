/**
 * Client Redis optionnel (présence messagerie, cache, etc.).
 * Si REDIS_URL est absent, toutes les fonctions retournent null → fallback mémoire côté services.
 */
import { createClient } from 'redis';

/** @type {import('redis').RedisClientType | null} */
let client = null;
/** @type {Promise<import('redis').RedisClientType | null> | null} */
let connectPromise = null;
let connectFailed = false;

/**
 * @returns {Promise<import('redis').RedisClientType | null>}
 */
export async function getRedisClient() {
  const url = process.env.REDIS_URL?.trim();
  if (!url) return null;
  if (connectFailed) return null;
  if (client?.isOpen) return client;
  if (connectPromise) return connectPromise;

  connectPromise = (async () => {
    try {
      const c = createClient({ url });
      c.on('error', (err) => {
        console.error('[redis]', err?.message || err);
      });
      await c.connect();
      client = c;
      console.log('[redis] connecté — présence messagerie synchronisée entre instances');
      return c;
    } catch (err) {
      console.error('[redis] connexion impossible, fallback mémoire pour le typing:', err?.message || err);
      connectFailed = true;
      client = null;
      return null;
    } finally {
      connectPromise = null;
    }
  })();

  return connectPromise;
}

export async function closeRedisClient() {
  if (!client?.isOpen) return;
  try {
    await client.quit();
  } catch (_) {
    try {
      await client.disconnect();
    } catch (_) {}
  }
  client = null;
  connectFailed = false;
}
