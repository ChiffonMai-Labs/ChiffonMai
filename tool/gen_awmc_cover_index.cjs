#!/usr/bin/env node
/**
 * 生成 AWMC 曲绘索引（P0-03 / P2-02）。
 *
 * 目录来自 `https://download.wmc.pub/api/v1/charts?limit=0&raw=1`（公开）。
 * `raw=1` 的记录没有 type 字段，类型只能按 shortid 区间推断：
 *   ≥100000 宴谱（UTG）、10000–99999 DX、其余 ST。
 * `[DX]` / `[宴]` 只在有 displayName 时作补充校验。
 *
 * 索引按 baseSongId 去重：DX 减去 10000，ST / 宴谱原样。同一首歌的 ST / DX
 * 两条记录都会保留（运行时先试请求的谱面，缺图再试孪生 id）。
 *
 * 用法：
 *   node tool/gen_awmc_cover_index.cjs
 *   node tool/gen_awmc_cover_index.cjs --key mk_live_xxx
 *   AWMC_VWMC_KEY=mk_live_xxx node tool/gen_awmc_cover_index.cjs
 *
 * Key 可选（download.wmc.pub 匿名也能拉）；若走需要鉴权的镜像可用 --source
 * 指定地址，并同时提供 --key / --alias-token（Header 分别为
 * Authorization: Bearer 与 X-Alias-Token）。
 *
 * 输出：assets/awmc_cover_index.json（运行时由 AwmcCoverService 读取）。
 */

'use strict';

const fs = require('node:fs');
const path = require('node:path');

const DEFAULT_SOURCE = 'https://download.wmc.pub/api/v1/charts?limit=0&raw=1';
const DEFAULT_OUT = path.resolve(__dirname, '..', 'assets', 'awmc_cover_index.json');
const BASELINE = path.resolve(__dirname, '..', 'assets', 'dxrating_cover_index.json');
const COVER_BASE = 'https://oss.awmc.cc/covers';
const COVER_WIDTHS = [240, 360, 480];
const TYPE_ORDER = { ST: 0, DX: 1, UTG: 2 };

function parseArgs(argv) {
  const args = {
    out: DEFAULT_OUT,
    source: DEFAULT_SOURCE,
    key: process.env.AWMC_VWMC_KEY || '',
    aliasToken: process.env.AWMC_ALIAS_TOKEN || '',
    skipSample: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    const value = () => {
      const next = argv[++i];
      if (!next) throw new Error(`${arg} 缺少参数`);
      return next;
    };
    if (arg === '--key') args.key = value();
    else if (arg === '--alias-token') args.aliasToken = value();
    else if (arg === '--source') args.source = value();
    else if (arg === '--out') args.out = path.resolve(value());
    else if (arg === '--skip-sample') args.skipSample = true;
    else if (arg === '-h' || arg === '--help') {
      console.log(fs.readFileSync(__filename, 'utf8').split('*/')[0]);
      process.exit(0);
    } else throw new Error(`未知参数：${arg}`);
  }
  return args;
}

function typeOf(shortid, displayName) {
  const id = Number.parseInt(shortid, 10);
  if (id >= 100000) return 'UTG';
  if (id >= 10000) return 'DX';
  if (typeof displayName === 'string') {
    if (displayName.startsWith('[DX]')) return 'DX';
    if (displayName.startsWith('[宴]') || displayName.startsWith('[UTG]')) {
      return 'UTG';
    }
  }
  return 'ST';
}

function baseSongIdOf(chartFileId, type) {
  if (type === 'UTG') return chartFileId;
  if (type === 'DX') return chartFileId - 10000;
  return chartFileId;
}

function shortIdOf(chartFileId) {
  return String(chartFileId).padStart(6, '0');
}

function coverUrl(versionFolder, folderName, imageRev, width = 360) {
  const nearest = COVER_WIDTHS.reduce((best, candidate) =>
    Math.abs(candidate - width) < Math.abs(best - width) ? candidate : best,
  );
  return `${COVER_BASE}/${encodeURIComponent(versionFolder)}/${encodeURIComponent(folderName)}/${encodeURIComponent(imageRev)}/w${nearest}.webp`;
}

async function fetchJson(url, args, timeoutMs = 90000) {
  const maxAttempts = 3;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const headers = {
        'User-Agent': 'ChiffonMai-CoverIndex/1.0 (+https://chiffonmai.cloud)',
        Accept: 'application/json',
      };
      if (args.key) headers.Authorization = `Bearer ${args.key}`;
      if (args.aliasToken) headers['X-Alias-Token'] = args.aliasToken;
      const response = await fetch(url, { headers, signal: controller.signal });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status} ${response.statusText}`);
      }
      return await response.json();
    } catch (error) {
      if (attempt === maxAttempts) throw error;
      console.warn(`拉取失败（第 ${attempt} 次，重试）：${error.message}`);
      await new Promise((resolve) => setTimeout(resolve, 1500 * attempt));
    } finally {
      clearTimeout(timer);
    }
  }
}

/** 目录可能分页；limit=0 时正常一次就返回全部，这里仍兼容分页响应。 */
async function fetchCatalog(args) {
  const first = await fetchJson(args.source, args);
  if (!first || !Array.isArray(first.charts)) {
    throw new Error('响应里没有 charts 数组');
  }
  let charts = first.charts;
  const pages = Number(first.pages) || 1;
  if (pages > 1 && charts.length < (Number(first.total) || 0)) {
    const url = new URL(args.source);
    url.searchParams.set('limit', '500');
    for (let page = 2; page <= pages; page++) {
      url.searchParams.set('page', String(page));
      const payload = await fetchJson(url.toString(), args);
      if (payload && Array.isArray(payload.charts)) charts = charts.concat(payload.charts);
    }
  }
  return charts;
}

function buildIndex(charts) {
  const covers = new Map();
  const stats = { ST: 0, DX: 0, UTG: 0, skipped: 0, duplicated: 0 };
  for (const chart of charts) {
    if (!chart || typeof chart.shortid !== 'string') {
      stats.skipped++;
      continue;
    }
    const chartFileId = Number.parseInt(chart.shortid, 10);
    if (!Number.isInteger(chartFileId) || chartFileId <= 0) {
      stats.skipped++;
      continue;
    }
    const type = typeOf(chart.shortid, chart.displayName);
    const versionFolder = chart.versionFolder;
    const folderName = chart.folderName;
    if (typeof versionFolder !== 'string' || typeof folderName !== 'string') {
      stats.skipped++;
      continue;
    }
    if (!versionFolder || !folderName) {
      stats.skipped++;
      continue;
    }
    const base = baseSongIdOf(chartFileId, type);
    const list = covers.get(String(base)) || [];
    if (list.some((item) => item.c === chartFileId)) {
      stats.duplicated++;
      continue;
    }
    list.push({
      c: chartFileId,
      t: type,
      vf: versionFolder,
      fn: folderName,
      rev: typeof chart.imageRev === 'string' ? chart.imageRev : '',
    });
    stats[type]++;
    covers.set(String(base), list);
  }
  for (const list of covers.values()) {
    list.sort(
      (a, b) => (TYPE_ORDER[a.t] ?? 9) - (TYPE_ORDER[b.t] ?? 9) || a.c - b.c,
    );
  }
  return { covers, stats };
}

function coverageOf(covers) {
  try {
    const baseline = JSON.parse(fs.readFileSync(BASELINE, 'utf8'));
    const ids = Object.keys(baseline.images || {});
    if (ids.length === 0) return null;
    let hit = 0;
    for (const id of ids) if (covers.has(id)) hit++;
    return { hit, total: ids.length, rate: (hit / ids.length) * 100 };
  } catch (_) {
    return null;
  }
}

async function sampleCovers(covers) {
  const urls = new Set();
  const entries = [...covers.values()];
  for (let i = 0; i < entries.length && urls.size < 10; i++) {
    const variant = entries[Math.floor((i * entries.length) / 10)]?.find((v) => v.rev);
    if (!variant) continue;
    urls.add(coverUrl(variant.vf, variant.fn, variant.rev));
  }
  let ok = 0;
  for (const url of urls) {
    try {
      const response = await fetch(url, {
        method: 'HEAD',
        headers: { 'User-Agent': 'ChiffonMai-CoverIndex/1.0' },
        signal: AbortSignal.timeout(20000),
      });
      const contentType = response.headers.get('content-type') || '';
      if (response.status === 200 && contentType === 'image/webp') ok++;
      else console.log(`  抽样失败：HTTP ${response.status} ${contentType} ${url}`);
    } catch (error) {
      console.log(`  抽样失败：${error.message} ${url}`);
    }
  }
  return { ok, total: urls.size };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  console.log(`目录：${args.source}`);
  console.log(`Key：${args.key ? '已提供' : '未提供（匿名拉取）'}`);

  const charts = await fetchCatalog(args);
  console.log(`目录记录：${charts.length} 条`);
  const { covers, stats } = buildIndex(charts);
  if (covers.size === 0) throw new Error('没有生成任何可用记录');

  const output = {
    v: 1,
    generatedAt: new Date().toISOString(),
    source: args.source,
    count: covers.size,
    stats,
    covers: Object.fromEntries(
      [...covers.entries()].sort((a, b) => Number(a[0]) - Number(b[0])),
    ),
  };
  fs.mkdirSync(path.dirname(args.out), { recursive: true });
  const tmp = `${args.out}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify(output));
  fs.renameSync(tmp, args.out);

  console.log(
    `已写入 ${args.out}\n` +
      `基础曲目 ${covers.size} 首 / 谱面 ${stats.ST + stats.DX + stats.UTG} 条` +
      `（ST ${stats.ST}、DX ${stats.DX}、UTG ${stats.UTG}；跳过 ${stats.skipped}，重复 ${stats.duplicated}）`,
  );

  const coverage = coverageOf(covers);
  if (coverage) {
    console.log(
      `对 assets/dxrating_cover_index.json 的覆盖率：` +
        `${coverage.hit}/${coverage.total} = ${coverage.rate.toFixed(2)}%`,
    );
  } else {
    console.log('没有可比对的基线索引，跳过覆盖率。');
  }

  if (!args.skipSample) {
    const sample = await sampleCovers(covers);
    console.log(`抽样曲绘：${sample.ok}/${sample.total} 为 200 image/webp`);
  }
}

main().catch((error) => {
  console.error(`生成失败：${error.stack || error.message}`);
  process.exit(1);
});
