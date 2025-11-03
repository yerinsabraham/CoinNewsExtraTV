const { onRequest } = require('firebase-functions/v2/https');
// Resolve a fetch implementation at runtime. On Node 18+ Cloud Functions (Node 22)
// global fetch is available. If not, fall back to dynamic import of node-fetch.
let fetchFn = (typeof fetch !== 'undefined') ? fetch : null;

async function resolveFetch() {
  if (fetchFn) return fetchFn;
  try {
    // dynamic import returns a module namespace; node-fetch v3 exports default
    const mod = await import('node-fetch');
    fetchFn = mod.default || mod;
    return fetchFn;
  } catch (err) {
    console.warn('No fetch implementation available (and node-fetch import failed):', err && err.message ? err.message : err);
    return null;
  }
}
// Note: Do NOT call admin.initializeApp() here — index.js initializes admin once.
const admin = require('firebase-admin');
const functions = require('firebase-functions');

// Note: we lazy-require Secret Manager client only when needed to avoid
// module-load failures if the optional package isn't installed. If the
// environment maps the secret into process.env.OPENAI_API_KEY (recommended)
// we don't need the Secret Manager client at all.
let smClient = null;

// Configuration: secret resource name (optional). If not set, will try
// process.env.OPENAI_API_KEY as a fallback.
// Recommended usage: during deploy, set the secret using --set-secrets
// and the runtime will expose it as an environment variable, or provide
// the secret name in OPENAI_SECRET resource style: projects/PROJECT_ID/secrets/NAME
const OPENAI_SECRET_NAME = process.env.OPENAI_SECRET_NAME || process.env.OPENAI_SECRET || null;

// In-memory cache to avoid repeated Secret Manager calls in hot containers.
let cachedOpenAIKey = null;
let cachedAt = 0;
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

async function getOpenAIKey() {
  // prefer explicit env var (runtime set via --set-secrets maps secret to env var)
  if (process.env.OPENAI_API_KEY) return process.env.OPENAI_API_KEY;

  // cached
  if (cachedOpenAIKey && (Date.now() - cachedAt) < CACHE_TTL_MS) return cachedOpenAIKey;

  // If a secret resource name is provided, fetch the latest version.
  // Lazy-require the Secret Manager client so a missing optional package
  // won't blow up at module load time.
  if (OPENAI_SECRET_NAME) {
    try {
      if (!smClient) {
        // require only when needed
        const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
        smClient = new SecretManagerServiceClient();
      }
      const name = OPENAI_SECRET_NAME.includes('projects/') ? OPENAI_SECRET_NAME : `projects/${process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT}/secrets/${OPENAI_SECRET_NAME}/versions/latest`;
      const [accessResponse] = await smClient.accessSecretVersion({ name });
      const payload = accessResponse.payload && accessResponse.payload.data ? accessResponse.payload.data.toString('utf8') : null;
      if (payload) {
        cachedOpenAIKey = payload.trim();
        cachedAt = Date.now();
        return cachedOpenAIKey;
      }
    } catch (err) {
      console.warn('Secret Manager read failed for OpenAI key (continuing to fallback):', err && err.message ? err.message : err);
      // continue to fallback below
    }
  }

  // last-resort fallback: functions.config()
  try {
    const cfg = functions.config && functions.config();
    if (cfg && cfg.openai && cfg.openai.key) {
      cachedOpenAIKey = cfg.openai.key;
      cachedAt = Date.now();
      return cachedOpenAIKey;
    }
  } catch (err) {
    // ignore
  }

  return null;
}

// Exported HTTPS function handler
exports.askOpenAI = onRequest({ cors: true }, async (req, res) => {
  try {
    if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

    const authHeader = req.get('Authorization') || '';
    if (!authHeader.startsWith('Bearer ')) return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    const idToken = authHeader.split('Bearer ')[1];

    let decoded;
    try {
      decoded = await admin.auth().verifyIdToken(idToken);
    } catch (err) {
      console.error('askOpenAI: invalid id token', err.message || err);
      return res.status(401).json({ error: 'Invalid identity token' });
    }

    const { prompt, preferConcise = true, max_tokens = 700 } = req.body || {};
    if (!prompt || typeof prompt !== 'string') return res.status(400).json({ error: 'Missing prompt' });

    const openaiKey = await getOpenAIKey();
    if (!openaiKey) {
      console.error('askOpenAI: OpenAI API key not available');
      return res.status(500).json({ error: 'OpenAI API key not configured on server' });
    }

    const system = preferConcise
      ? 'You are CNETV AI — answer direct factual questions in the first sentence and keep replies short (1–3 sentences). Ask one clarifying question if ambiguous.'
      : 'You are CNETV AI — provide helpful multi-paragraph answers when necessary. Begin with a direct answer sentence.';

    const payload = {
      model: 'gpt-3.5-turbo',
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: prompt }
      ],
      max_tokens: Number(max_tokens) || 700,
      temperature: 0.2,
    };

    const _fetch = await resolveFetch();
    if (!_fetch) {
      console.error('askOpenAI: no fetch available to call OpenAI');
      return res.status(500).json({ error: 'no_fetch_available' });
    }

    const r = await _fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${openaiKey}`,
      },
      body: JSON.stringify(payload),
    });

    if (!r.ok) {
      const text = await r.text();
      console.error('askOpenAI upstream OpenAI error', r.status, text.substring(0, 2000));
      return res.status(502).json({ error: 'OpenAI upstream error', detail: text });
    }

    const data = await r.json();
    const answer = (data.choices && data.choices[0] && data.choices[0].message && data.choices[0].message.content) || '';

    // Log only minimal non-sensitive info
    console.log(`askOpenAI: uid=${decoded.uid} tokens=${data.usage?.total_tokens || 'n/a'}`);

    return res.json({ answer: answer.trim() });
  } catch (err) {
    console.error('askOpenAI fatal', err && err.message ? err.message : err);
    return res.status(500).json({ error: 'internal_error' });
  }
});
