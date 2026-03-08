const https = require('https');
const { onRequest } = require('firebase-functions/v2/https');
const XLSX = require('xlsx');

const DEFAULT_SOURCE_URL =
  'https://ckan.opendata.pref.ishikawa.lg.jp/dataset/00d7c221-a2c4-401d-aff5-8ec1587ab52f/resource/10320ebf-f47b-4295-b31d-1726dc7e48c6/download/2025.12.18.xlsx';

function setCorsHeaders(res) {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
  res.set('Cache-Control', 'public, max-age=900');
}

function downloadText(url) {
  const MAX_REDIRECTS = 5;
  return new Promise((resolve, reject) => {
    const doRequest = (currentUrl, redirectsRemaining) => {
      https
        .get(currentUrl, (response) => {
          const status = response.statusCode || 0;

          // Handle redirects (3xx with Location header)
          if (
            status >= 300 &&
            status < 400 &&
            response.headers &&
            response.headers.location &&
            redirectsRemaining > 0
          ) {
            try {
              const redirectUrl = new URL(
                response.headers.location,
                currentUrl
              ).toString();
              response.resume();
              doRequest(redirectUrl, redirectsRemaining - 1);
              return;
            } catch (e) {
              response.resume();
              reject(e);
              return;
            }
          }
function downloadBuffer(url) {
  const MAX_REDIRECTS = 5;
  return new Promise((resolve, reject) => {
    const doRequest = (currentUrl, redirectsRemaining) => {
      https
        .get(currentUrl, (response) => {
          const status = response.statusCode || 0;

          // Handle redirects (3xx with Location header)
          if (
            status >= 300 &&
            status < 400 &&
            response.headers &&
            response.headers.location &&
            redirectsRemaining > 0
          ) {
            try {
              const redirectUrl = new URL(
                response.headers.location,
                currentUrl
              ).toString();
              response.resume();
              doRequest(redirectUrl, redirectsRemaining - 1);
              return;
            } catch (e) {
              response.resume();
              reject(e);
              return;
            }
          }

          if (status < 200 || status >= 300) {
            response.resume();
            reject(new Error(`Upstream status ${status}`));
            return;
          }

          const chunks = [];
          response.on('data', (chunk) => chunks.push(chunk));
          response.on('end', () => resolve(Buffer.concat(chunks)));
        })
        .on('error', reject);
    };

    doRequest(url, MAX_REDIRECTS);
  });
}

function normalizeFishName(raw) {
  const v = String(raw || '').trim();
  if (!v) return null;

  if (v.includes('ﾏｱｼﾞ') || v.includes('あじ')) return 'アジ';
  if (v.includes('ﾒﾊﾞﾙ') || v.includes('めばる')) return 'メバル';
  if (v.includes('ｸﾛﾀﾞｲ') || v.includes('たい')) return 'クロダイ';
  if (v.includes('ｽｽﾞｷ') || v.includes('しーばす')) return 'シーバス';
  if (v.includes('ｶｻｺﾞ')) return 'カサゴ';
  if (v.includes('ﾉﾛｹﾞﾝｹﾞ') || v.includes('ｹﾞﾝｹﾞ')) return 'ゲンゲ';
  if (v.includes('ﾉﾄﾞｸﾞﾛ') || v.includes('ｱｶﾑﾂ')) return 'のどぐろ';

  return null;
}

function mapDistrictToSpotId(district) {
  const d = String(district || '').trim();
  if (!d) return null;

  if (d.includes('加賀') || d.includes('小松')) return 'kaga_offshore';
  if (d.includes('金沢') || d.includes('白山') || d.includes('かほく')) {
    return 'kanazawa_port';
  }
  if (d.includes('七尾') || d.includes('能登町')) return 'nanao_bay';
  if (
    d.includes('輪島') ||
    d.includes('珠洲') ||
    d.includes('志賀') ||
    d.includes('羽咋') ||
    d.includes('宝達')
  ) {
    return 'noto_north';
  }

  return null;
}

function toNumber(value) {
  if (value == null) return 0;
  const n = Number(String(value).replace(/,/g, '').trim());
  return Number.isFinite(n) ? n : 0;
}

function parseLandingWorkbook(buffer) {
  const workbook = XLSX.read(buffer, { type: 'buffer' });
  const sheetName = workbook.SheetNames[0];
  const rows = XLSX.utils.sheet_to_json(workbook.Sheets[sheetName], {
    defval: null,
    raw: false,
  });

  const spotFish = {
    noto_north: {},
    nanao_bay: {},
    kanazawa_port: {},
    kaga_offshore: {},
  };
  const spotTotal = {
    noto_north: 0,
    nanao_bay: 0,
    kanazawa_port: 0,
    kaga_offshore: 0,
  };

  let latestYear = 0;

  for (const row of rows) {
    const spotId = mapDistrictToSpotId(row['地区名']);
    if (!spotId) continue;

    const fish = normalizeFishName(row['銘柄名'] ?? row['銘柄 名']);
    if (!fish) continue;

    const amount = toNumber(row['数量年計']);
    if (amount <= 0) continue;

    const year = toNumber(row['年']);
    if (year > latestYear) latestYear = year;

    spotFish[spotId][fish] = (spotFish[spotId][fish] || 0) + amount;
    spotTotal[spotId] += amount;
  }

  const spots = Object.keys(spotFish).map((spotId) => ({
    spotId,
    totalCatchKg: Math.round(spotTotal[spotId]),
    fishCatchKg: Object.fromEntries(
      Object.entries(spotFish[spotId]).map(([fish, amount]) => [
        fish,
        Math.round(amount),
      ])
    ),
  }));

  return {
    datasetName: '石川県水揚げデータ（地域別集計）',
    source: DEFAULT_SOURCE_URL,
    observedYear: latestYear > 0 ? String(latestYear) : '',
    observedMonth: '',
    spots,
  };
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
      const workbookBuffer = await downloadBuffer(DEFAULT_SOURCE_URL);
      const normalized = parseLandingWorkbook(workbookBuffer);
      res.set('Content-Type', 'application/json; charset=utf-8');
      res.status(200).json(normalized);
    } catch (error) {
      res.status(502).json({
        error: 'Upstream fetch failed',
        detail: error.message,
      });
    }
  }
);
