const fs = require('node:fs');
const path = require('node:path');

const root = path.join(__dirname, '..');
const catalogUrl = 'https://download.wmc.pub/api/v1/charts';

async function fetchPage(page) {
  const url = new URL(catalogUrl);
  url.search = new URLSearchParams({ raw: '1', limit: '200', page: String(page) });
  const response = await fetch(url, { signal: AbortSignal.timeout(20000) });
  if (!response.ok) throw new Error(`AWMC 目录第 ${page} 页返回 HTTP ${response.status}`);
  const data = await response.json();
  if (!Array.isArray(data.charts) || !Number.isInteger(data.pages) || data.pages < 1 || data.pages > 30) {
    throw new Error(`AWMC 目录第 ${page} 页格式异常`);
  }
  return data;
}

async function loadCatalog(source) {
  if (source) {
    const data = JSON.parse(fs.readFileSync(source, 'utf8').replace(/^\uFEFF/, ''));
    return Array.isArray(data) ? data : data.charts;
  }
  const first = await fetchPage(1);
  const charts = [...first.charts];
  for (let page = 2; page <= first.pages; page++) {
    const next = await fetchPage(page);
    if (next.generatedAt !== first.generatedAt) throw new Error('目录在分页过程中更新，请重试');
    charts.push(...next.charts);
  }
  if (charts.length !== first.matched) throw new Error('AWMC 目录缺页');
  return charts;
}

async function main() {
  const rows = await loadCatalog(process.argv[2]);
  if (!Array.isArray(rows)) throw new Error('AWMC 目录缺少 charts 列表');
  const entries = new Map();
  for (const row of rows) {
    if (!row || !/^\d{6}$/.test(row.shortid) || !row.versionFolder || !row.folderName || !row.image) continue;
    const id = Number(row.shortid);
    if (id === 0 || id === 10000) continue;
    const dx = id > 10000 && id < 100000;
    const baseId = dx ? id - 10000 : id;
    // 同曲先取现役条目，同为现役时优先标准谱。
    const score = (row.isOc ? 0 : 2) + (dx ? 0 : 1);
    if ((entries.get(baseId)?.score ?? -1) >= score) continue;
    entries.set(baseId, { score, cover: [row.shortid, row.versionFolder, row.folderName] });
  }

  const baseline = JSON.parse(fs.readFileSync(path.join(root, 'assets/dxrating_cover_index.json'), 'utf8'));
  const ids = Object.keys(baseline.images);
  const matched = ids.filter(id => entries.has(Number(id))).length;
  if (matched / ids.length < 0.99) throw new Error(`旧索引覆盖率不足 99%（${matched}/${ids.length}）`);

  // 包内只有路径。客户端可在运行时取得修订号，过期修订可回退到 CDN 原图接口。
  const covers = Object.fromEntries([...entries].map(([id, entry]) => [id, entry.cover]));
  fs.writeFileSync(path.join(root, 'assets/awmc_cover_index.json'), JSON.stringify(covers) + '\n');
  console.log(`AWMC 曲绘 ${entries.size} 首，覆盖旧索引 ${matched}/${ids.length}`);
}

main().catch(error => {
  console.error(error.message);
  process.exitCode = 1;
});
