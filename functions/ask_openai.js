const { onRequest } = require('firebase-functions/v2/https');
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// HTTP function that proxies prompts to OpenAI. Requires Authorization: Bearer <Firebase ID Token>
exports.askOpenAI = onRequest({ cors: true }, async (req, res) => {
  try {
    if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

    // Verify Firebase ID token from Authorization header
    const authHeader = req.get('Authorization') || '';
    if (!authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    const idToken = authHeader.split('Bearer ')[1];
    let decoded;
    try {
      decoded = await admin.auth().verifyIdToken(idToken);
    } catch (err) {
      console.error('Invalid ID token', err);
      return res.status(401).json({ error: 'Invalid identity token' });
    }

    const body = req.body || {};
    const prompt = body.prompt;
    const preferConcise = body.preferConcise !== false; // default true
    const max_tokens = body.max_tokens || 700;

    if (!prompt || typeof prompt !== 'string') {
      return res.status(400).json({ error: 'Missing prompt' });
    }

    // Read API key from environment first (recommended for Functions v2).
    // Attempt to read legacy functions.config() only as a last resort and
    // guard against it not being available in v2 runtimes.
    let openaiKey = process.env.OPENAI_API_KEY;
    try {
      if (!openaiKey && typeof functions !== 'undefined' && functions.config) {
        const cfg = functions.config();
        if (cfg && cfg.openai && cfg.openai.key) openaiKey = cfg.openai.key;
      }
    } catch (err) {
      // functions.config() may be unavailable in v2; ignore the error and
      // continue using environment variables.
      console.warn('functions.config() unavailable; using environment variables if present');
    }

    if (!openaiKey) {
      console.error('OpenAI key not configured in environment or functions config');
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
      max_tokens,
      temperature: 0.2,
    };

    const r = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${openaiKey}`,
      },
      body: JSON.stringify(payload),
    });

    if (!r.ok) {
      const text = await r.text();
      console.error('OpenAI error', r.status, text);
      return res.status(502).json({ error: 'OpenAI error', detail: text });
    }

    const data = await r.json();
    const answer = (data.choices && data.choices[0] && data.choices[0].message && data.choices[0].message.content) || '';

    // Optionally log minimal metrics (do not store prompts)
    console.log(`askOpenAI: uid=${decoded.uid} tokens=${data.usage?.total_tokens || 'n/a'}`);

    return res.json({ answer: answer.trim() });
  } catch (err) {
    console.error('askOpenAI error', err);
    return res.status(500).json({ error: err.message || 'internal_error' });
  }
});
