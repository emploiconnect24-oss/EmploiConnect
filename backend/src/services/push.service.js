/**
 * Push FCM (legacy HTTP API). Nécessite FCM_SERVER_KEY dans .env.
 */
import axios from 'axios';
import { supabase } from '../config/supabase.js';

export async function sendFcmToUserIds(userIds, { title, body, data }) {
  const key = process.env.FCM_SERVER_KEY;
  if (!key || !userIds?.length || !title) return;

  const { data: rows, error } = await supabase
    .from('device_push_tokens')
    .select('token')
    .in('utilisateur_id', [...new Set(userIds)]);

  if (error || !rows?.length) return;

  const tokens = [...new Set(rows.map((r) => r.token).filter(Boolean))];
  const payloadData = {};
  if (data && typeof data === 'object') {
    Object.entries(data).forEach(([k, v]) => {
      payloadData[k] = v == null ? '' : String(v);
    });
  }

  for (const to of tokens) {
    try {
      await axios.post(
        'https://fcm.googleapis.com/fcm/send',
        {
          to,
          notification: { title: String(title).slice(0, 120), body: String(body || '').slice(0, 200) },
          data: payloadData,
        },
        {
          headers: {
            Authorization: `key=${key}`,
            'Content-Type': 'application/json',
          },
          timeout: 10000,
        },
      );
    } catch (e) {
      console.warn('[push] FCM:', e.response?.status || e.message);
    }
  }
}
