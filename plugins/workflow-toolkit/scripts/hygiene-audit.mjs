#!/usr/bin/env node
// Warstwa 1 — deterministyczny linter higieny reguł pracy.
// Mierzy twarde inwarianty (nie ocenia — tylko liczy). Zero zależności (czysty fs).
//
// Użycie:
//   node .claude/scripts/hygiene-audit.mjs           pełny raport (human)
//   node .claude/scripts/hygiene-audit.mjs --hook     cichy gdy czysto; raport tylko gdy są ⚠️ (dla SessionStart)
//   node .claude/scripts/hygiene-audit.mjs --json      maszynowy (dla agent-audytu, warstwa 2)
//
// Kontrakt: exit 0 zawsze (hook nie może blokować sesji). Sygnał niesie treść, nie kod wyjścia.

import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

// Skrypt jest reużywalny między projektami (żyje w piotr-toolkit), więc korzeniem
// jest CWD — uruchamiaj z roota repo (hook i cron agent robią cd do repo najpierw).
const root = process.cwd();
const cfgPath = join(root, '.claude', 'audit-invariants.json');

if (!existsSync(cfgPath)) process.exit(0); // brak configu = ten projekt nie ma higieny, cicho wyjdź
const cfg = JSON.parse(readFileSync(cfgPath, 'utf8'));

const mode = process.argv.includes('--json') ? 'json'
  : process.argv.includes('--hook') ? 'hook'
  : 'human';

const checks = [];
const add = (id, label, value, limit, ok, detail) =>
  checks.push({ id, label, value, limit, ok, detail: detail || null });

// --- memory ---
const memDir = join(root, cfg.memory.dir);
const indexPath = join(memDir, cfg.memory.indexFile);
let memFiles = [];
if (existsSync(memDir)) {
  memFiles = readdirSync(memDir).filter(f =>
    f.endsWith('.md') &&
    f !== cfg.memory.indexFile &&
    f.toUpperCase() !== 'README.MD'
  );
}

// 1) cap wpisów aktywnych
add('memory-cap', 'wpisy memory', memFiles.length, cfg.memory.cap,
  memFiles.length <= cfg.memory.cap,
  memFiles.length > cfg.memory.cap ? `${memFiles.length - cfg.memory.cap} ponad cap → wymuś sweep konsolidacji` : null);

// 2) build-logi kandydujące do archiwum
const blRe = new RegExp(cfg.memory.buildLogPattern);
const buildLogs = memFiles.filter(f => blRe.test(f));
add('build-logs', 'build-logi do przeglądu (flow-/man-/fp-)', buildLogs.length, 0,
  buildLogs.length === 0,
  buildLogs.length ? `sprawdź czy shipped bez open-items → mv do ${cfg.memory.archiveDir}/` : null);

// 3) parytet index ↔ pliki
let indexLinks = [];
if (existsSync(indexPath)) {
  const idx = readFileSync(indexPath, 'utf8');
  // tylko markdown-linki [label](file.md) — nie nawiasy w tekście opisu
  indexLinks = [...idx.matchAll(/\[[^\]]*\]\(([^)]+\.md)\)/g)].map(m => m[1]);
}
const linkSet = new Set(indexLinks);
const fileSet = new Set(memFiles);
const missingFromIndex = memFiles.filter(f => !linkSet.has(f)); // plik istnieje, brak w indeksie
const danglingIndex = indexLinks.filter(l => !fileSet.has(l));   // indeks wskazuje na nieistniejący plik
add('index-parity', 'parytet MEMORY.md ↔ pliki',
  missingFromIndex.length + danglingIndex.length, 0,
  missingFromIndex.length + danglingIndex.length === 0,
  [
    missingFromIndex.length ? `${missingFromIndex.length} plików bez wpisu w indeksie: ${missingFromIndex.slice(0,5).join(', ')}${missingFromIndex.length>5?'…':''}` : '',
    danglingIndex.length ? `${danglingIndex.length} martwych linków w indeksie: ${danglingIndex.slice(0,5).join(', ')}${danglingIndex.length>5?'…':''}` : ''
  ].filter(Boolean).join(' | ') || null);

// (Świadomie NIE sprawdzamy martwych wikilinków [[…]]: doktryna pamięci dopuszcza
//  dangling link jako marker "do napisania później", więc to nie jest defekt.)

// 4) rozmiar CLAUDE.md (always-on koszt)
const cmPath = join(root, cfg.claudeMd.path);
let cmLines = 0;
if (existsSync(cmPath)) cmLines = readFileSync(cmPath, 'utf8').split('\n').length;
add('claudemd-size', `${cfg.claudeMd.path} (linie, always-on)`, cmLines, cfg.claudeMd.maxLines,
  cmLines <= cfg.claudeMd.maxLines,
  cmLines > cfg.claudeMd.maxLines ? `${cmLines - cfg.claudeMd.maxLines} linii ponad próg → skróć/przenieś do DS-docs (skrót+wskaźnik)` : null);

// 6) katalog _archive istnieje?
const archPath = join(memDir, cfg.memory.archiveDir);
add('archive-dir', `${cfg.memory.archiveDir}/ istnieje`, existsSync(archPath) ? 1 : 0, 1,
  existsSync(archPath), existsSync(archPath) ? null : 'brak — utwórz przy pierwszej archiwizacji');

// --- output ---
const warnings = checks.filter(c => !c.ok);

if (mode === 'json') {
  const days = cfg.judgementAuditEveryDays;
  process.stdout.write(JSON.stringify({ project: cfg.project, checks, warnings: warnings.length, judgementAuditEveryDays: days }, null, 2) + '\n');
  process.exit(0);
}

if (mode === 'hook' && warnings.length === 0) process.exit(0); // czysto → cisza w SessionStart

const icon = c => c.ok ? '✅' : '⚠️';
const lines = [];
lines.push(`🧹 Hygiene audit — ${cfg.project}`);
for (const c of checks) {
  const val = c.limit != null && c.id !== 'archive-dir' ? `${c.value} / ${c.limit}` : `${c.value}`;
  lines.push(`  ${icon(c)} ${c.label}: ${val}${c.detail ? `\n       → ${c.detail}` : ''}`);
}
if (warnings.length) {
  lines.push(`\n${warnings.length} ⚠️  do naprawy. Głęboki audyt osądu (sprzeczności/dryf/duplikaty): co ~${cfg.judgementAuditEveryDays} dni (scheduled) lub odpal ręcznie.`);
} else {
  lines.push(`\n✅ Wszystkie twarde inwarianty OK.`);
}
process.stdout.write(lines.join('\n') + '\n');
process.exit(0);
