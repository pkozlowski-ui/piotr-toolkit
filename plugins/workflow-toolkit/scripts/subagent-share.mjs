#!/usr/bin/env node
/**
 * subagent-share.mjs — udział requestów subagentów vs główna sesja, z rozbiciem model/effort/agentType.
 *
 * PO CO: tańszy kanał pomiaru dla hipotezy H15 („delegacja jako domyślny tryb w skillach
 * sweep/audyt podnosi udział subagentów"). Dotąd metryka szła z RĘCZNEGO audytu tokenów
 * (czytanie transkryptów) — tu ta sama liczba jest policzona mechanicznie z ~/.claude/projects.
 * Baseline z audytu 2026-08-27: subagenci 11,9% requestów; próg sukcesu H15: > 15% w 2 kolejnych
 * pomiarach. Widoczność model+effort per subagent jest tym, co `/tasks` pokazuje w UI
 * (Claude Code 2.1.243) — ten skrypt czyta to samo ze źródła na dysku, żeby dało się porównać
 * okna w czasie i wpisać liczbę do gate'a, a nie tylko zobaczyć na ekranie.
 *
 * Request = wpis `type:"assistant"` z `message.usage` (jedna odpowiedź API).
 *   - główna sesja: <projekt>/<sessionId>.jsonl
 *   - subagent:     <projekt>/<sessionId>/subagents/agent-*.jsonl (+ .meta.json → agentType, model)
 * Okno liczone po `timestamp` wpisu (nie mtime pliku) — sesja sprzed okna nie zaśmieca wyniku.
 *
 * Użycie:
 *   node subagent-share.mjs [--days N] [--project <slug|.>] [--json]
 *   --days N        okno w dniach (default 14 — kadencja audytu tokenów 1. i 15. dnia miesiąca)
 *   --project slug  tylko jeden katalog projektu; `.` = projekt bieżącego cwd
 *   --json          maszynowy output (do gate'a / hipotezy)
 */
import { readdirSync, readFileSync, existsSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { homedir } from 'node:os';

const argv = process.argv.slice(2);
const flag = (name, def = null) => {
  const i = argv.indexOf(name);
  return i === -1 ? def : (argv[i + 1] ?? true);
};
const days = Number(flag('--days', 14));
const asJson = argv.includes('--json');
let projectFilter = flag('--project', null);
if (projectFilter === '.') projectFilter = process.cwd().replace(/[^A-Za-z0-9]/g, '-');

const PROJECTS = join(homedir(), '.claude', 'projects');
const cutoff = Date.now() - days * 86400e3;
const famOf = m => /haiku/i.test(m) ? 'haiku' : /sonnet/i.test(m) ? 'sonnet'
  : /opus/i.test(m) ? 'opus' : /fable/i.test(m) ? 'fable' : 'other';

/** Liczy requesty w oknie + rozbicie model/effort z jednego pliku jsonl. */
function scan(path) {
  const out = { requests: 0, models: {}, efforts: {} };
  let text;
  try {
    // szybki filtr: plik w całości starszy niż okno → pomiń bez parsowania
    if (statSync(path).mtimeMs < cutoff) return out;
    text = readFileSync(path, 'utf8');
  } catch { return out; }
  for (const line of text.split('\n')) {
    if (!line || line.indexOf('"assistant"') === -1) continue;
    let d;
    try { d = JSON.parse(line); } catch { continue; }
    if (d.type !== 'assistant' || !d.message?.usage) continue;
    const ts = Date.parse(d.timestamp ?? '');
    if (!Number.isFinite(ts) || ts < cutoff) continue;
    out.requests++;
    const fam = famOf(d.message.model ?? 'other');
    out.models[fam] = (out.models[fam] ?? 0) + 1;
    const eff = d.effort ?? 'n/a';
    out.efforts[eff] = (out.efforts[eff] ?? 0) + 1;
  }
  return out;
}
const merge = (into, from) => {
  into.requests += from.requests;
  for (const [k, v] of Object.entries(from.models)) into.models[k] = (into.models[k] ?? 0) + v;
  for (const [k, v] of Object.entries(from.efforts)) into.efforts[k] = (into.efforts[k] ?? 0) + v;
};
const empty = () => ({ requests: 0, models: {}, efforts: {} });

const main = empty();
const sub = empty();
const byAgentType = {};   // agentType → { agents, requests, models }
const perProject = {};

const projects = existsSync(PROJECTS)
  ? readdirSync(PROJECTS, { withFileTypes: true }).filter(e => e.isDirectory()).map(e => e.name)
  : [];

for (const proj of projects) {
  if (projectFilter && proj !== projectFilter) continue;
  const root = join(PROJECTS, proj);
  const p = { main: empty(), sub: empty() };
  let entries = [];
  try { entries = readdirSync(root, { withFileTypes: true }); } catch { continue; }

  for (const e of entries) {
    if (e.isFile() && e.name.endsWith('.jsonl')) {
      merge(p.main, scan(join(root, e.name)));
    } else if (e.isDirectory()) {
      const subDir = join(root, e.name, 'subagents');
      if (!existsSync(subDir)) continue;
      let files = [];
      try { files = readdirSync(subDir); } catch { continue; }
      for (const f of files.filter(x => x.startsWith('agent-') && x.endsWith('.jsonl'))) {
        const stats = scan(join(subDir, f));
        if (!stats.requests) continue;
        merge(p.sub, stats);
        // meta.json → agentType i zadeklarowany model (to, co /tasks pokazuje per subagent)
        let meta = {};
        try { meta = JSON.parse(readFileSync(join(subDir, f.replace(/\.jsonl$/, '.meta.json')), 'utf8')); } catch { /* brak metadanych */ }
        const type = meta.agentType ?? 'unknown';
        const bucket = byAgentType[type] ??= { agents: 0, requests: 0, models: {} };
        bucket.agents++;
        bucket.requests += stats.requests;
        for (const [k, v] of Object.entries(stats.models)) bucket.models[k] = (bucket.models[k] ?? 0) + v;
      }
    }
  }
  if (p.main.requests || p.sub.requests) {
    perProject[proj] = { main: p.main.requests, sub: p.sub.requests };
    merge(main, p.main);
    merge(sub, p.sub);
  }
}

const total = main.requests + sub.requests;
const share = total ? (sub.requests / total) * 100 : 0;
const BASELINE = 11.9;   // audyt tokenów 2026-08-27
const TARGET = 15;       // próg sukcesu H15
const result = {
  windowDays: days,
  project: projectFilter ?? 'all',
  requests: { main: main.requests, subagent: sub.requests, total },
  subagentSharePct: Math.round(share * 10) / 10,
  baselinePct: BASELINE,
  targetPct: TARGET,
  verdict: total === 0 ? 'no-data' : share > TARGET ? 'above-target'
    : share > BASELINE ? 'above-baseline' : 'at-or-below-baseline',
  subagentModels: sub.models,
  subagentEfforts: sub.efforts,
  byAgentType,
  perProject,
};

if (asJson) {
  console.log(JSON.stringify(result, null, 2));
} else {
  const fmt = o => Object.entries(o).sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k}:${v}`).join(' ') || '—';
  console.log(`okno: ${days}d · projekt: ${result.project}`);
  console.log(`requesty: main ${main.requests} · subagenci ${sub.requests} · razem ${total}`);
  console.log(`udział subagentów: ${result.subagentSharePct}%  (baseline ${BASELINE}% · próg H15 ${TARGET}%) → ${result.verdict}`);
  console.log(`modele subagentów: ${fmt(sub.models)}`);
  console.log(`effort subagentów: ${fmt(sub.efforts)}`);
  console.log('agentType:');
  for (const [t, b] of Object.entries(byAgentType).sort((a, b) => b[1].requests - a[1].requests)) {
    console.log(`  ${t}: ${b.agents} agentów · ${b.requests} req · [${fmt(b.models)}]`);
  }
  if (!projectFilter) {
    console.log('projekty (main/sub):');
    for (const [p, v] of Object.entries(perProject).sort((a, b) => b[1].sub - a[1].sub).slice(0, 8)) {
      console.log(`  ${p.slice(-40)}: ${v.main}/${v.sub}`);
    }
  }
}
