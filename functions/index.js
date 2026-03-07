const https = require('https');
const { onRequest } = require('firebase-functions/v2/https');

const DEFAULT_SOURCE_URL =
  'https://ckan.opendata.pref.ishikawa.lg.jp/dataset/b9e71183-5d58-4aa3-8a52-6c436993fa2e/resource/3a8105cc-4b7e-40b5-aa99-ca614d0fa32f/download/catch_amount_type.csv';

function setCorsHeaders(res) {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
  res.set('Cache-Control', 'public, max-age=900');
}

function downloadText(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, (response) => {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          reject(new Error(`Upstream status ${response.statusCode}`));
          response.resume();
          return;
        }

        response.setEncoding('utf8');
        let body = '';
        response.on('data', (chunk) => {
          body += chunk;
        });
        response.on('end', () => resolve(body));
      })
      .on('error', reject);
  });
}

exports.ishikawaOpenDataProxy = onRequest(
  {
    region: 'asia-northeast1',
    cors: false,
  },
  async (req, res) => {
    setCorsHeaders(res);

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    if (req.method !== 'GET') {
      res.status(405).json({ error: 'Method Not Allowed' });
      return;
    }

    try {
      const csv = await downloadText(DEFAULT_SOURCE_URL);
      res.set('Content-Type', 'text/csv; charset=utf-8');
      res.status(200).send(csv);
    } catch (error) {
      res.status(502).json({
        error: 'Upstream fetch failed',
        detail: error.message,
      });
    }
  }
);
