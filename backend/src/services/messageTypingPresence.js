/**
 * Présence « en train d'écrire » par conversation.
 * - Si REDIS_URL est défini : clés partagées entre toutes les instances Node (prod).
 * - Sinon : Map en mémoire (dev local sans Redis).
 */

import { getRedisClient } from '../config/redis.js';

const REDIS_KEY_PREFIX = 'emploiconnect:typing:';
const TTL_SECONDS = 8;
const MEMORY_TTL_MS = TTL_SECONDS * 1000;

/** @type {Map<string, { userId: string, expireAt: number }>} */
const typingByConversation = new Map();

function redisKey(conversationId) {
  return `${REDIS_KEY_PREFIX}${String(conversationId)}`;
}

/**
 * @param {string} conversationId
 * @param {string} userId
 */
export async function recordTyping(conversationId, userId, ttlMs = MEMORY_TTL_MS) {
  if (!conversationId || !userId) return;
  const cid = String(conversationId);
  const uid = String(userId);

  const r = await getRedisClient();
  if (r) {
    try {
      await r.set(redisKey(cid), uid, { EX: TTL_SECONDS });
      return;
    } catch (err) {
      console.error('[typing] redis SET:', err?.message || err);
    }
  }

  typingByConversation.set(cid, {
    userId: uid,
    expireAt: Date.now() + ttlMs,
  });
}

/**
 * @param {string} conversationId
 * @param {string} viewerUserId — utilisateur qui consulte (exclure son propre typing)
 */
export async function isPeerTyping(conversationId, viewerUserId) {
  const cid = String(conversationId);
  const viewer = String(viewerUserId);

  const r = await getRedisClient();
  if (r) {
    try {
      const val = await r.get(redisKey(cid));
      return !!val && val !== viewer;
    } catch (err) {
      console.error('[typing] redis GET:', err?.message || err);
    }
  }

  const row = typingByConversation.get(cid);
  if (!row) return false;
  if (Date.now() > row.expireAt) {
    typingByConversation.delete(cid);
    return false;
  }
  return row.userId !== viewer;
}

/** Après envoi d’un message : retire l’indicateur pour cet auteur dans la conversation. */
export async function clearTypingForUser(conversationId, userId) {
  const cid = String(conversationId);
  const uid = String(userId);

  const r = await getRedisClient();
  if (r) {
    try {
      const val = await r.get(redisKey(cid));
      if (val === uid) await r.del(redisKey(cid));
      return;
    } catch (err) {
      console.error('[typing] redis DEL:', err?.message || err);
    }
  }

  const row = typingByConversation.get(cid);
  if (row && row.userId === uid) {
    typingByConversation.delete(cid);
  }
}
