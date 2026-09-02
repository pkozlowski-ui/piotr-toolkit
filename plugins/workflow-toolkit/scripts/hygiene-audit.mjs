#!/usr/bin/env node
// Warstwa 1 — deterministyczny linter higieny reguł pracy.
// Mierzy twarde inwarianty (nie ocenia — tylko liczy). Zero zależności (czysty fs).
//
// Użycie:
//   node .claude/scripts/hygiene-audit.mjs           pełny raport (human)
//   node .claude/scripts/hygiene-audit.mjs --hook     cichy gdy czysto; raport tylko gdy są ⚠️ (dla SessionStart)
//   node .claude/scripts/hygiene-audit.mjs --json      maszynowy (dla agent-audytu, warstwa 2)
//   node .claude/scripts/hygiene-audit.mjs --selftest  break-restore soczewek na syntetycznych fixturach (nie czyta projektu)
//
// Kontrakt: exit 0 zawsze (hook nie może blokować sesji). Sygnał niesie treść, nie kod wyjścia.

import { readFileSync, readdirSync, existsSync, statSync, appendFileSync } from 'node:fs';
import { join } from 'node:path';
import { homedir } from 'node:os';
import { execSync } from 'node:child_process';

// Skrypt jest reużywalny między projektami (żyje w piotr-toolkit), więc korzeniem
// jest CWD — uruchamiaj z roota repo (hook i cron agent robią cd do repo najpierw).
const root = process.cwd();
const cfgPath = join(root, '.claude', 'audit-invariants.json');

// Break-restore soczewek (fire/silent na syntetycznych fixturach) — PRZED czytaniem configu,
// żeby dało się odpalić z dowolnego katalogu. Kontrakt: exit 1 gdy którakolwiek gałąź nie strzela.
if (process.argv.includes('--selftest')) process.exit(runSelftest() ? 0 : 1);

if (!existsSync(cfgPath)) process.exit(0); // brak configu = ten projekt nie ma higieny, cicho wyjdź
const cfg = JSON.parse(readFileSync(cfgPath, 'utf8'));

const mode = process.argv.includes('--json') ? 'json'
  : process.argv.includes('--hook') ? 'hook'
  : 'human';

const checks = [];
const add = (id, label, value, limit, ok, detail) =>
  checks.push({ id, label, value, limit, ok, detail: detail || null });

// Log przebiegów — jedna linia na run, POZA repo (nie zaśmieca diffów, jest git-nietrwały).
// Istnieje, bo warunek wznowienia hipotezy H14 ("≥5 przebiegów hygiene-audit") był
// NIEWERYFIKOWALNY: audyt drukował stan i nie zostawiał śladu, że w ogóle się odpalił, więc
// warunek odnoszący się do liczby przebiegów wyglądał identycznie jak spełniany. Zapis jest
// best-effort i NIGDY nie może wywalić sesji — hook ma kontrakt "exit 0 zawsze".
// Warunek unieważnienia: zbędny, gdy harness zacznie sam raportować przebiegi hooków.
const runLogPath = join(homedir(), '.claude', 'hygiene-audit-runs.log');
function appendRunLog(warnCount) {
  try {
    appendFileSync(runLogPath,
      `${new Date().toISOString()}\t${mode}\t${root}\twarnings=${warnCount}\n`);
  } catch { /* best-effort: brak katalogu/uprawnień nie może zatrzymać audytu */ }
}

// --- memory ---
const memDir = join(root, cfg.memory.dir);
const indexPath = join(memDir, cfg.memory.indexFile);
let memFiles = [];
if (existsSync(memDir)) {
  memFiles = readdirSync(memDir).filter(f => isMemoryEntry(f, cfg.memory.indexFile));
}

// 1) cap wpisów aktywnych
add('memory-cap', 'wpisy memory', memFiles.length, cfg.memory.cap,
  memFiles.length <= cfg.memory.cap,
  memFiles.length > cfg.memory.cap ? `${memFiles.length - cfg.memory.cap} ponad cap → wymuś sweep konsolidacji` : null);

// 1b) rozmiar POJEDYNCZEGO wpisu (cap liczy PLIKI, więc jest zielony gdy treść rośnie W nich).
//     Ratchet z ledgerem — uzasadnienie i gałęzie: patrz evalMemoryEntrySize na końcu pliku.
if (cfg.memory.maxEntryBytes != null && existsSync(memDir)) {
  const entrySizes = memFiles.map(name => ({
    name,
    bytes: Buffer.byteLength(readFileSync(join(memDir, name), 'utf8'), 'utf8'),
  }));
  const mes = evalMemoryEntrySize({
    entries: entrySizes,
    maxBytes: cfg.memory.maxEntryBytes,
    ledger: cfg.memory.oversizeLedger || {},
    shrinkPct: cfg.memory.ledgerShrinkPct ?? 20,
  });
  add('memory-entry-size', 'rozmiar wpisu pamięci (ratchet + ledger)', mes.value, 0, mes.ok, mes.detail);
}

// 2) build-logi kandydujące do archiwum (allowlist = świadome KEEP mylone przez prefiks, np. reference)
const blRe = new RegExp(cfg.memory.buildLogPattern);
const blAllow = new Set((cfg.memory.buildLogAllowlist || []).map(n => n.endsWith('.md') ? n : `${n}.md`));
const buildLogs = memFiles.filter(f => blRe.test(f) && !blAllow.has(f));
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

// 4b) rozmiar CLAUDE.md w BAJTACH — realny always-on koszt.
//     Liczba linii to PROXY, które przestaje śledzić koszt, gdy treść rośnie DŁUGOŚCIĄ linii
//     zamiast ich liczbą (zmierzone 2026-08-04 w antisys prototype: 50 847 B → 97 096 B
//     w 10 dni przy 212 → 241 linii, czyli 36% zapasu na liczniku przy +91% realnego payloadu;
//     jeden bullet miał 21 KB = 21,6% pliku). Próg opcjonalny — sprawdzany tylko gdy podany.
if (cfg.claudeMd.maxBytes != null && existsSync(cmPath)) {
  const cmBytes = Buffer.byteLength(readFileSync(cmPath, 'utf8'), 'utf8');
  add('claudemd-bytes', `${cfg.claudeMd.path} (bajty, always-on)`, cmBytes, cfg.claudeMd.maxBytes,
    cmBytes <= cfg.claudeMd.maxBytes,
    cmBytes > cfg.claudeMd.maxBytes
      ? `${cmBytes - cfg.claudeMd.maxBytes} B ponad próg → zwiń najdłuższy bullet do imperatywu + wskaźnika na DS-docs (licznik linii tego NIE pokaże), albo podnieś baseline świadomie w tym samym commicie`
      : null);
}

// 4c) najdłuższa linia CLAUDE.md w znakach — łapie bloat niewidoczny dla liczby linii/bajtów.
//     Zmierzone 2026-08-10 (antisys prototype): 241/380 linii ✅, ale jedna linia miała
//     27 885 znaków (~26% pliku) — licznik linii/bajtów tego nie widzi, gdy treść rośnie
//     GĘSTOŚCIĄ jednej linii, nie ich liczbą. Próg opcjonalny (jak maxBytes) — sprawdzany
//     tylko gdy podany w configu.
if (cfg.claudeMd.maxLineChars != null && existsSync(cmPath)) {
  const cmText = readFileSync(cmPath, 'utf8');
  const cmLinesArr = cmText.split('\n');
  let maxLen = 0, maxLineNo = 0;
  cmLinesArr.forEach((l, i) => { if (l.length > maxLen) { maxLen = l.length; maxLineNo = i + 1; } });
  add('claudemd-max-line-chars', `${cfg.claudeMd.path} (najdłuższa linia, znaki)`, maxLen, cfg.claudeMd.maxLineChars,
    maxLen <= cfg.claudeMd.maxLineChars,
    maxLen > cfg.claudeMd.maxLineChars
      ? `linia ${maxLineNo} ma ${maxLen} znaków (próg ${cfg.claudeMd.maxLineChars}) → zwiń do imperatywu + wskaźnika na DS-docs/eval-README, nie duplikuj tam pełnego tekstu`
      : null);
}

// 5) markery design-detalu w CLAUDE.md (anti-bloat treści, nie tylko rozmiaru)
//    Proxy jakościowy: node-IDs / hex / surowe px to niemal zawsze design-detal,
//    który należy do registry/canonical-patterns, nie do always-on CLAUDE.md.
//    Baseline zamraża legit-gotchy; sygnał niesie WZROST (wpełzanie nowych).
if (cfg.claudeMd.designMarkerBaseline != null && existsSync(cmPath)) {
  const cm = readFileSync(cmPath, 'utf8');
  const nodeIds = (cm.match(/[0-9]{3,4}:[0-9]{2,6}/g) || []).length;
  const hex = (cm.match(/#[0-9a-fA-F]{6}/g) || []).length;
  const px = (cm.match(/[0-9]+ ?px/g) || []).length;
  const total = nodeIds + hex + px;
  const base = cfg.claudeMd.designMarkerBaseline;
  add('claudemd-design-markers', `${cfg.claudeMd.path} (markery design-detalu: nodeID+hex+px)`,
    total, base, total <= base,
    total > base
      ? `+${total - base} ponad baseline (nodeID ${nodeIds}, hex ${hex}, px ${px}) → design-detal wpełzł; przenieś do registry/canonical-patterns lub podnieś baseline świadomie`
      : null);
}

// 6) katalog _archive istnieje?
const archPath = join(memDir, cfg.memory.archiveDir);
add('archive-dir', `${cfg.memory.archiveDir}/ istnieje`, existsSync(archPath) ? 1 : 0, 1,
  existsSync(archPath), existsSync(archPath) ? null : 'brak — utwórz przy pierwszej archiwizacji');

// 7) higiena reguły doboru modelu (delegacja vs mechanika w oknie) — gated na cfg.modelPolicy
//    Proxy heurystyczny: liczy subagentów (rozbicie modeli) i sesje z mechaniczną robotą
//    Figma ze transcriptów ~/.claude/projects/<slug>. ⚠️ tylko gdy była mechanika, a zero
//    delegacji. Defensywne (try/catch) — brak transcriptów / błąd nigdy nie wywala hooka.
if (cfg.modelPolicy) {
  try {
    const mp = cfg.modelPolicy;
    const windowMs = (mp.windowDays || 3) * 86400e3;
    const now = Date.now();
    const slug = root.replace(/[^A-Za-z0-9]/g, '-'); // CWD → katalog projektu w ~/.claude/projects
    const projRoot = join(homedir(), '.claude', 'projects', slug);
    const inWindow = p => { try { return now - statSync(p).mtimeMs <= windowMs; } catch { return false; } };
    const famOf = m => /haiku/i.test(m) ? 'haiku' : /sonnet/i.test(m) ? 'sonnet'
      : /opus/i.test(m) ? 'opus' : /fable/i.test(m) ? 'fable' : 'other';

    let mechSessions = 0;
    const deleg = { haiku: 0, sonnet: 0, opus: 0, fable: 0, other: 0 };
    let delegTotal = 0;

    if (existsSync(projRoot)) {
      const entries = readdirSync(projRoot, { withFileTypes: true });
      // główne transcripty: <sessionId>.jsonl na top-levelu → mechanika = REALNE wywołanie
      // figma_execute (tool_use "name"), NIE goła wzmianka 'figma_execute' (ta jest w liście
      // deferred-tools każdego system-remindera → dałaby false-positive na każdej sesji)
      const mechRe = /"name"\s*:\s*"mcp__figma-console__figma_execute"/;
      for (const e of entries.filter(x => x.isFile() && x.name.endsWith('.jsonl'))) {
        const p = join(projRoot, e.name);
        if (!inWindow(p)) continue;
        try { if (mechRe.test(readFileSync(p, 'utf8'))) mechSessions++; } catch { /* skip */ }
      }
      // subagenty: <sessionId>/subagents/agent-*.jsonl → rodzina modelu z pola "model"
      for (const e of entries.filter(x => x.isDirectory())) {
        const subDir = join(projRoot, e.name, 'subagents');
        if (!existsSync(subDir)) continue;
        let agents = [];
        try { agents = readdirSync(subDir).filter(f => f.startsWith('agent-') && f.endsWith('.jsonl')); } catch { continue; }
        for (const a of agents) {
          const p = join(subDir, a);
          if (!inWindow(p)) continue;
          try {
            const m = readFileSync(p, 'utf8').match(/"model"\s*:\s*"([^"]+)"/);
            deleg[famOf(m ? m[1] : 'other')]++;
            delegTotal++;
          } catch { /* skip */ }
        }
      }
    }

    const minMech = mp.minMechSessionsToExpectDelegation ?? 2;
    // HIPOTEZA 2026-08-04 (audyt tokenów, baseline: Haiku = 0,14% wagi zużycia przy regule
    // "mechanika → Haiku"): sam delegTotal>0 maskował problem — delegacje szły na Sonnet/Opus,
    // mechanika zostawała w głównej sesji. Alert także gdy delegacje są, ale zero na Haiku.
    // Walidacja: następny audyt tokenów (~2 tyg.) — udział Haiku ma wzrosnąć, inne checki bez regresu.
    const ok = !(mechSessions >= minMech && (delegTotal === 0 || deleg.haiku === 0));
    const breakdown = `h:${deleg.haiku} s:${deleg.sonnet} o:${deleg.opus}` +
      (deleg.fable ? ` f:${deleg.fable}` : '') + (deleg.other ? ` ?:${deleg.other}` : '');
    add('model-delegation', `dobór modelu (deleg vs mechanika, ${mp.windowDays || 3}d)`,
      `${delegTotal} deleg [${breakdown}] / ${mechSessions} mech-sesji`, null, ok,
      ok ? null : (delegTotal === 0
        ? `${mechSessions} sesji z mechaniczną robotą Figma, 0 delegacji → deleguj sweepy/audyty do Haiku/Sonnet (subagent), nie rób ich na modelu głównej sesji`
        : `${mechSessions} sesji z mechaniką Figma, delegacje są (${delegTotal}) ale ŻADNA na Haiku → mechanikę (sweepy, audyty, batch-edycje) kieruj do subagenta Haiku/low, nie Sonnet/Opus`));

    // 7b) ESKALACJA (REKO 7 audytu workflow 2026-08-27): powyższy check jest zbiorczy (sesje
    //     z Figma-mechaniką w oknie) i uśrednia — jedna ciężka sesja bez delegacji ginie w
    //     agregacie obok czystych. Ten check jest PER SESJA i liczy WSZYSTKIE narzędzia (nie
    //     tylko figma_execute): dowód potrzeby = audyt tokenów 2026-08-27, subagenci
    //     15%→11,9% requestów, 4/20 sesji z 30–85 wywołaniami narzędzi i zero delegacji —
    //     nudge tekstowy w skillach nie wystarczał, próg tu jest mechaniczny.
    const toolUseRe = /"type"\s*:\s*"tool_use"/g;
    const sessions = [];
    if (existsSync(projRoot)) {
      const entries2 = readdirSync(projRoot, { withFileTypes: true });
      for (const e of entries2.filter(x => x.isFile() && x.name.endsWith('.jsonl'))) {
        const p = join(projRoot, e.name);
        if (!inWindow(p)) continue;
        try {
          const content = readFileSync(p, 'utf8');
          const toolCalls = (content.match(toolUseRe) || []).length;
          const sid = e.name.replace(/\.jsonl$/, '');
          const subDir2 = join(projRoot, sid, 'subagents');
          let hasDelegation = false;
          if (existsSync(subDir2)) {
            try { hasDelegation = readdirSync(subDir2).some(f => f.startsWith('agent-') && f.endsWith('.jsonl')); } catch { /* skip */ }
          }
          sessions.push({ sid, toolCalls, hasDelegation });
        } catch { /* skip */ }
      }
    }
    const mechCallsThreshold = mp.mechCallsThreshold ?? 40;
    const thr = evalDelegationThreshold({ sessions, threshold: mechCallsThreshold });
    add('model-delegation-threshold', `sesje >${mechCallsThreshold} wywołań bez delegacji (${mp.windowDays || 3}d)`,
      thr.value, null, thr.ok, thr.detail);
  } catch { /* higiena modelu nigdy nie blokuje audytu */ }
}

// 8) świeżość gita — czy audyt nie idzie po nieaktualnym drzewie (stale checkout)
//    Realny bug 2026-07-21: agent-audyt (warstwa 2) czytał pliki na lokalnym HEAD 8 commitów
//    za origin → wygenerował fałszywe znalezisko „sprzeczność" (kanon był już naprawiony zdalnie).
//    Fetch tylko w json/human (agent-audyt + ręczny) — w trybie --hook (SessionStart) pomijamy,
//    żeby nie dokładać latencji/sieci do startu sesji. Pełny try/catch: brak gita/sieci = skip, nigdy nie wywala.
if (mode !== 'hook') {
  try {
    const git = (args, opts = {}) => execSync(`git ${args}`, { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 8000, ...opts }).trim();
    git('rev-parse --is-inside-work-tree'); // rzuci jeśli nie-repo → skip
    // gałąź zdalna: origin/HEAD → fallback origin/main
    let remoteRef = 'origin/main';
    try { remoteRef = git('rev-parse --abbrev-ref origin/HEAD'); } catch { /* fallback */ }
    try { git('fetch --quiet origin', { timeout: 8000 }); } catch { /* offline → porównaj wg cache remote-ref */ }
    let behind = 0, ahead = 0;
    try {
      const counts = git(`rev-list --left-right --count HEAD...${remoteRef}`).split(/\s+/);
      ahead = parseInt(counts[0], 10) || 0;
      behind = parseInt(counts[1], 10) || 0;
    } catch { /* brak remote-tracking ref → skip poniżej */ }
    add('git-freshness', `świeżość drzewa (vs ${remoteRef})`, behind === 0 ? 'aktualne' : `${behind} za`, 0,
      behind === 0,
      behind > 0 ? `lokalne ${behind} commitów ZA ${remoteRef} (ahead ${ahead}) → \`git pull --rebase\` PRZED czytaniem stanu; audyt na stale checkout = fałszywe znaleziska (bug 2026-07-21)` : null);
  } catch { /* nie-repo / brak gita → świadomie brak checku */ }
}

// 9) kadencja audytu promptowania (jednorazowy sweep ~kwartalny) — gated na cfg.promptingAudit
//    Nie odpala sweepa (za drogi na SessionStart) — tylko przypomina o kadencji, licząc dni
//    od cfg.promptingAudit.lastRun (data trzymana w configu, aktualizowana po każdym przebiegu).
//    Analogicznie do stopki 'audyt osądu co ~N dni', ale jako pełny check z progiem.
if (cfg.promptingAudit && cfg.promptingAudit.lastRun) {
  const everyDays = cfg.promptingAudit.everyDays || 90;
  const last = Date.parse(cfg.promptingAudit.lastRun);
  if (!Number.isNaN(last)) {
    const days = Math.floor((Date.now() - last) / 86400e3);
    add('prompting-audit', 'audyt promptowania (dni od ostatniego)', days, everyDays,
      days <= everyDays,
      days > everyDays
        ? `${days} dni od ostatniego (próg ${everyDays}) → odpal audyt promptowania w świeżej sesji (/clear): sweep transcriptów ~/.claude/projects/*/*.jsonl, potem ustaw promptingAudit.lastRun`
        : null);
  }
}

// 10) rejestry node-ID vs realny plik designu — kadencja + stan ostatniego biegu
//     Sam check wymaga Figmy (`use_figma`), więc NIE odpala się tutaj: hook czyta tylko
//     RAPORT z dysku (offline). Dwa sygnały, świadomie rozdzielone — `dangling` to zmierzony
//     defekt, a przestarzały raport to BRAK POMIARU; ten drugi wygląda identycznie jak
//     „czysto", więc musi mieć własny komunikat.
if (cfg.registryNodeIds && cfg.registryNodeIds.reportPath) {
  const rnPath = join(root, cfg.registryNodeIds.reportPath);
  const everyDays = cfg.registryNodeIds.everyDays || 7;
  if (!existsSync(rnPath)) {
    add('registry-node-ids', 'rejestry node-ID (raport)', 'brak', 0, false,
      `nigdy nie mierzone → odpal: node .claude/scripts/registry-node-ids.mjs --extract, sonda w Figmie, --verdict (runbook: ${cfg.registryNodeIds.runbook || 'docs/audits/README.md'})`);
  } else {
    try {
      const rep = JSON.parse(readFileSync(rnPath, 'utf8'));
      const ageDays = Math.floor((Date.now() - statSync(rnPath).mtimeMs) / 86400e3);
      const s = rep.summary || {};
      const bad = (s.dangling || 0) + (s.unresolved || 0);
      if (bad > 0) {
        add('registry-node-ids', 'rejestry node-ID (dangling + unresolved)', bad, 0, false,
          `${s.dangling || 0} dangling, ${s.unresolved || 0} bez pomiaru (raport z przed ${ageDays} dni) → napraw rejestr albo dopisz nagrobek; szczegóły w ${cfg.registryNodeIds.reportPath}`);
      } else {
        add('registry-node-ids', `rejestry node-ID (dni od pomiaru, próg ${everyDays})`, ageDays, everyDays,
          ageDays <= everyDays,
          ageDays > everyDays ? `raport starszy niż ${everyDays} dni → przemierz (rejestr mógł zgnić po kasowaniu masterów)` : null);
      }
    } catch {
      add('registry-node-ids', 'rejestry node-ID (raport)', 'nieczytelny', 0, false,
        `${cfg.registryNodeIds.reportPath} nie parsuje się → przemierz check`);
    }
  }
}

// 11) blok gate'a Figmy — żywe soczewki + break-restore trybu selektywnego (REKO 1, audyt 2026-08-27).
//     Stan, nie efekt. Offline i tani (2× ~40 ms), więc jedzie też w trybie --hook.
//     Logika w evalGateBlock() (na dole pliku) — czysta funkcja, żeby miała break-restore.
if (cfg.gateBlock && cfg.gateBlock.script) {
  try {
    const scriptPath = join(root, cfg.gateBlock.script);
    if (!existsSync(scriptPath)) {
      add('gate-block', 'blok gate\'a (soczewki + selftest)', 'brak skryptu', 0, false,
        `${cfg.gateBlock.script} nie istnieje → REKO 1 (tryb selektywny --only) zniknął z drzewa albo ścieżka w configu zgniła`);
    } else {
      // `2>&1` nie jest kosmetyka: gate-block wypisuje raport `--check` na STDERR (console.error),
      // a execSync zwraca tylko stdout — bez scalenia strumieni licznik soczewek jest niewidoczny
      // i check raportowal "nie doszedl do pomiaru" na w pelni zdrowym skrypcie (zmierzone 2026-08-28).
      const run = args => {
        try {
          return { out: execSync(`node ${JSON.stringify(scriptPath)} ${args} 2>&1`, { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], timeout: 20000 }), exit: 0 };
        } catch (e) {
          return { out: `${e.stdout || ''}${e.stderr || ''}`, exit: e.status == null ? 1 : e.status };
        }
      };
      const c = run('--check');
      const t = run('--selftest');
      const r = evalGateBlock({
        checkOut: c.out, checkExit: c.exit, selftestOut: t.out, selftestExit: t.exit,
        expectedAudits: cfg.gateBlock.expectedAudits ?? null,
        minSelftestCases: cfg.gateBlock.minSelftestCases ?? null,
      });
      add('gate-block', 'blok gate\'a (soczewki · selftest)', r.value, null, r.ok, r.detail);
    }
  } catch { /* higiena gate'a nigdy nie blokuje audytu */ }
}

// 12) czas ostatniego nightly bramki CI (REKO 3, audyt 2026-08-27).
//     Wymaga sieci (`gh run list`), więc — jak git-freshness — POMIJANY w trybie --hook:
//     SessionStart zostaje offline, a pomiar bierze audyt osądu (--json, co ~3 dni) i ręczny run.
//     Logika w evalCiNightly() (na dole pliku).
if (cfg.ciNightly && cfg.ciNightly.workflow && mode !== 'hook') {
  try {
    const cn = cfg.ciNightly;
    let runs = null;
    try {
      const raw = execSync(
        `gh run list --workflow=${JSON.stringify(cn.workflow)} -L ${cn.sampleSize || 10} --json createdAt,updatedAt,event,conclusion,databaseId`,
        { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 20000 });
      runs = JSON.parse(raw);
    } catch { /* brak gh / brak sieci → runs zostaje null = BRAK POMIARU, nie zielone */ }
    const r = evalCiNightly({ runs, maxMinutes: cn.maxMinutes ?? 10, maxAgeHours: cn.maxAgeHours ?? 48 });
    add('ci-nightly', `ostatni nightly ${cn.workflow} (czas, próg ${cn.maxMinutes ?? 10} min)`, r.value, null, r.ok, r.detail);
  } catch { /* higiena CI nigdy nie blokuje audytu */ }
}

// --- output ---
const warnings = checks.filter(c => !c.ok);
appendRunLog(warnings.length); // jeden ślad na przebieg, przed KAŻDYM wyjściem (json/hook/human)

if (mode === 'json') {
  const days = cfg.judgementAuditEveryDays;
  process.stdout.write(JSON.stringify({ project: cfg.project, checks, warnings: warnings.length, judgementAuditEveryDays: days }, null, 2) + '\n');
  process.exit(0);
}

if (mode === 'hook' && warnings.length === 0) process.exit(0); // czysto → cisza w SessionStart

const icon = c => c.ok ? '✅' : '⚠️';
const lines = [];
lines.push(`🧹 Hygiene audit — ${cfg.project}`);
// --hook (SessionStart) = pokazuj TYLKO ⚠️ wymagające uwagi/decyzji — bez ściany ✅.
// human (ręczny) + json (agent-audyt) = pełny raport wszystkich checków.
const shown = mode === 'hook' ? warnings : checks;
for (const c of shown) {
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

// ============================================================================
// Soczewki wydzielone jako CZYSTE funkcje — żeby dały się złamać i przywrócić
// bez odpalania CI ani Figmy. Deklaracje są hoistowane, więc runSelftest()
// (wywoływany na górze pliku) widzi je mimo położenia na końcu.
// ============================================================================

/**
 * REKO 1 — blok gate'a Figmy. Trzy asercje, bo dwie pierwsze same z siebie ZIELENIEJĄ,
 * gdy tryb selektywny `--only` zniknie z drzewa: rewert zabiera 4 case'y break-restore,
 * a werdykt selftestu zostaje PASS. Dlatego skala selftestu (liczba case'ów) jest częścią
 * checku, nie tylko jego werdykt.
 *   (a) `--check`: WERDYKT pass + żywe soczewki == deklarowane == próg z configu
 *   (b) `--selftest`: WERDYKT PASS i zero failujących case'ów
 *   (c) liczba case'ów selftestu >= minSelftestCases z configu
 */
function evalGateBlock({ checkOut = '', checkExit = 0, selftestOut = '', selftestExit = 0, expectedAudits = null, minSelftestCases = null }) {
  const problems = [];

  const mAud = /\*Audit:\s*(\d+)\/(\d+)/.exec(checkOut);
  const live = mAud ? Number(mAud[1]) : null;
  const declared = mAud ? Number(mAud[2]) : null;
  if (mAud === null) {
    problems.push('`--check` nie wypisał licznika soczewek (`*Audit: n/m`) → skrypt nie doszedł do pomiaru');
  } else {
    if (live !== declared) problems.push(`żywe soczewki ${live}/${declared} (brakujące albo martwe)`);
    if (expectedAudits != null && declared !== expectedAudits) {
      problems.push(`skrypt deklaruje ${declared} soczewek, config oczekuje ${expectedAudits} → skala zmieniła się bez podniesienia progu w tym samym commicie`);
    }
  }

  const mCheckVerdict = /^\[gate-block\] WERDYKT:\s*(\S+)/m.exec(checkOut);
  if (!mCheckVerdict) problems.push('`--check` bez linii WERDYKT');
  else if (mCheckVerdict[1].toLowerCase() !== 'pass') problems.push(`\`--check\` WERDYKT: ${mCheckVerdict[1]}`);
  if (checkExit !== 0) problems.push(`\`--check\` exit ${checkExit}`);

  const mSt = /selftest WERDYKT:\s*(\w+)\s*\((\d+)\/(\d+)\)/.exec(selftestOut);
  const stPassed = mSt ? Number(mSt[2]) : null;
  const stTotal = mSt ? Number(mSt[3]) : null;
  if (mSt === null) {
    problems.push('`--selftest` nie wypisał werdyktu → break-restore nie przebiegł');
  } else {
    if (mSt[1].toUpperCase() !== 'PASS' || stPassed !== stTotal) problems.push(`selftest ${stPassed}/${stTotal} (${mSt[1]})`);
    if (minSelftestCases != null && stTotal < minSelftestCases) {
      problems.push(`selftest ma ${stTotal} case'ów, baseline ${minSelftestCases} → break-restore schudł (werdykt PASS tego NIE pokaże); przywróć case'y albo obniż baseline świadomie w tym samym commicie`);
    }
  }
  if (selftestExit !== 0) problems.push(`\`--selftest\` exit ${selftestExit}`);

  return {
    ok: problems.length === 0,
    value: `soczewki ${live ?? '?'}/${declared ?? '?'} · selftest ${stPassed ?? '?'}/${stTotal ?? '?'}`,
    detail: problems.length ? problems.join(' | ') : null,
  };
}

/**
 * REKO 3 — czas ostatniego nightly bramki CI. Trzy RÓŻNE fakty, świadomie rozdzielone
 * (zlanie ich w jedno "nie ok" gubi kierunek naprawy):
 *   • zmierzony przekroczony czas          → koszt CI urósł, patrz najdłuższy job
 *   • nightly starszy niż maxAgeHours      → BRAK POMIARU (harmonogram nie odpalił)
 *   • zero runów ze `schedule`             → nightly w ogóle nie chodzi
 * Bierze wyłącznie `event: schedule`: workflow_dispatch mierzy moment, w którym ktoś stał
 * nad tym ręcznie (i zwykle na rozgrzanym cache'u), więc jako "nightly" kłamie.
 */
function evalCiNightly({ runs = null, maxMinutes = 10, maxAgeHours = 48, now = Date.now() }) {
  if (runs === null) {
    return { ok: false, value: 'brak pomiaru', detail: '`gh run list` nie zwrócił danych (brak gh / brak autoryzacji / offline) → sprawdź `gh auth status`; to brak pomiaru, nie zielony wynik' };
  }
  const scheduled = runs
    .filter(r => r && r.event === 'schedule' && r.createdAt && r.updatedAt)
    .sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt));
  if (!scheduled.length) {
    return { ok: false, value: 'brak runu ze schedule', detail: `żaden z pobranych runów nie pochodzi z harmonogramu → nightly nie chodzi albo okno pobrania (sampleSize) jest za wąskie` };
  }
  const last = scheduled[0];
  const minutes = (Date.parse(last.updatedAt) - Date.parse(last.createdAt)) / 60000;
  const ageHours = (now - Date.parse(last.createdAt)) / 3600000;
  const stamp = `${last.createdAt.slice(0, 16).replace('T', ' ')} UTC`;
  if (ageHours > maxAgeHours) {
    return {
      ok: false,
      value: `ostatni nightly ${Math.round(ageHours)} h temu`,
      detail: `ostatni run ze schedule'a to ${stamp} (${minutes.toFixed(1)} min) — starszy niż ${maxAgeHours} h → harmonogram NIE odpalił (GitHub pomija cron przy obciążeniu, a workflow ze schedule'em usypia po 60 dniach bezczynności repo); to brak pomiaru, nie zielony wynik`,
    };
  }
  return {
    ok: minutes <= maxMinutes,
    value: `${minutes.toFixed(1)} min`,
    detail: minutes <= maxMinutes ? null
      : `nightly ${stamp} trwał ${minutes.toFixed(1)} min (próg ${maxMinutes}) → \`gh run view ${last.databaseId} --json jobs\`; koszt niesie najdłuższy job, nie suma`,
  };
}

/**
 * REKO 7 (audyt workflow 2026-08-27) — eskalacja "delegacja vs mechanika" z sygnału
 * zbiorczego (7, powyżej) do PER SESJA: sesja z >threshold wywołań narzędzi i ZERO
 * delegacji (subagent) w oknie → finding, niezależnie od tego, jak wygląda reszta okna.
 */
function evalDelegationThreshold({ sessions = [], threshold = 40 }) {
  const offenders = sessions.filter(s => s.toolCalls > threshold && !s.hasDelegation);
  return {
    ok: offenders.length === 0,
    value: `${offenders.length} sesji >${threshold} wywołań bez delegacji`,
    detail: offenders.length
      ? `${offenders.map(s => `${s.sid.slice(0, 8)}:${s.toolCalls}`).join(', ')} → deleguj sweepy/audyty do subagenta (Haiku mechanika / Sonnet rutyna), nie rób ich w głównej sesji`
      : null,
  };
}

/**
 * REKO 1 re-score'u 2026-09-02 — rozmiar POJEDYNCZEGO wpisu pamięci.
 *
 * Powód istnienia: `memory-cap` (check 1) liczy WPISY, więc trzyma się zielony, gdy liczba
 * plików stoi, a treść rośnie W NICH. Zmierzone w oknie 08-27 → 09-02 (antisis prototype):
 * cap 42 → 40 (poprawa!), a równolegle `git-session-collisions` 56 → 62,7 KB,
 * `family-portal-design-register` 51 → 57,6 KB i nowy 38,6 KB `worktree-tooling-gotchas`.
 * Licznik wpisów tego nie widzi — to ta sama klasa wady co linie-vs-bajty w CLAUDE.md.
 *
 * Dlaczego NIE płaski próg 10 KB z doktryny „jeden fakt = jeden plik": zmierzone
 * 2026-09-02 — 15 z 38 aktywnych wpisów przekracza 10 KB, więc taki check strzelałby
 * 15× w PIERWSZYM przebiegu i zostałby odruchowo zignorowany (martwy licznik świeci ✅
 * i wygląda jak pomiar; tu świeciłby ⚠️ i wyglądał jak szum — ta sama bezużyteczność).
 * Dlatego mechanizm jest RATCHETEM z ledgerem, wzorowanym na `dsHardcodeBudget`:
 *   (a) wpis POZA ledgerem > maxBytes            → finding (nowy moloch nie wchodzi cicho)
 *   (b) wpis Z ledgera > zapisanego rozmiaru     → finding (TO jest gałąź, która złapałaby
 *                                                  regres z 08-27 → 09-02; zero zapasu)
 *   (c) ledger wskazuje na nieistniejący wpis    → finding (pozycja zapłacona/zarchiwizowana,
 *                                                  a dalej licencjonuje dług — zdejmij ją)
 *   (d) wpis z ledgera schudł >shrinkPct pod zapis → finding (po sweepie ZACIŚNIJ ledger,
 *                                                  inaczej cicho re-licencjonuje powrót)
 * Ledger = świadomy dług z powodem, nie amnestia: pozycję zdejmujesz sweepem, nie edycją progu.
 * Warunek unieważnienia całej soczewki: gdy wpisy pamięci przestaną być ładowane treścią
 * przy recallu (wtedy rozmiar wpisu nie kosztuje nic poza indeksem, który mierzy `memory-cap`).
 */
function evalMemoryEntrySize({ entries = [], maxBytes = null, ledger = {}, shrinkPct = 20 }) {
  if (maxBytes == null) return { ok: true, value: 'brak progu', detail: null, skipped: true };
  const kb = b => (b / 1024).toFixed(1);
  const byName = new Map(entries.map(e => [e.name, e.bytes]));
  const findings = [];

  // (a) nowy moloch poza ledgerem
  for (const { name, bytes } of entries) {
    if (name in ledger) continue;
    if (bytes > maxBytes) findings.push(`${name} ${kb(bytes)} KB > próg ${kb(maxBytes)} KB (poza ledgerem) → rozbij na fakty albo wpisz do ledgera z powodem`);
  }
  // (b) ledgerowy wpis urósł ponad zapis — ratchet bez zapasu
  for (const [name, recorded] of Object.entries(ledger)) {
    const bytes = byName.get(name);
    if (bytes == null) continue;
    if (bytes > recorded) findings.push(`${name} urósł ${kb(recorded)} → ${kb(bytes)} KB (+${bytes - recorded} B ponad ledger) → dług miał maleć, nie rosnąć`);
  }
  // (c) ledger wskazuje na nieistniejący wpis
  for (const name of Object.keys(ledger)) {
    if (!byName.has(name)) findings.push(`${name} nie istnieje (zarchiwizowany/scalony?) → zdejmij pozycję z ledgera, bo licencjonuje dług, którego nie ma`);
  }
  // (d) schudł istotnie — ledger do zaciśnięcia, inaczej re-licencjonuje powrót
  for (const [name, recorded] of Object.entries(ledger)) {
    const bytes = byName.get(name);
    if (bytes == null || bytes > recorded) continue;
    if (bytes <= recorded * (1 - shrinkPct / 100)) findings.push(`${name} schudł ${kb(recorded)} → ${kb(bytes)} KB → ZACIŚNIJ ledger do ${kb(bytes)} KB w tym samym commicie, inaczej próg cicho pozwala wrócić`);
  }

  const over = entries.filter(e => e.bytes > maxBytes).length;
  return {
    ok: findings.length === 0,
    value: `${findings.length} findingów (${over} wpisów >${kb(maxBytes)} KB, ${Object.keys(ledger).length} w ledgerze)`,
    detail: findings.length ? findings.join(' | ') : null,
  };
}

// ---------- break-restore (syntetyczne fixtury — nie czyta projektu, nie rusza repo) ----------

// Czy plik w katalogu pamięci JEST wpisem pamięci (a nie indeksem/README/infra-logiem)?
// Wyciągnięte z inline-filtra, żeby dało się objąć break-restore'em — soczewka mierzona
// na syntetycznych nazwach, bez czytania dysku.
//
// `_`-prefiks = plik INFRASTRUKTURALNY, nie wpis pamięci. Powód konkretny: `_decision-sweep-log.md`
// tworzy sam skill `session-retro` (jego krok 4a) jako log przebiegów, a soczewka `index-parity`
// raportowała go jako "pamięć bez wpisu w indeksie" — czyli check żądał wpisu w MEMORY.md dla
// pliku, który wpisem pamięci nie jest. Ta sama klasa co dopasowanie po zbyt luźnym wzorcu:
// soczewka mierzyła NIE TEN obiekt. Katalog `_archive/` był już wykluczony przypadkiem (nie ma
// rozszerzenia `.md`) — teraz wykluczenie `_` jest JAWNE i wspólne dla wszystkich trzech soczewek
// karmionych `memFiles` (cap, build-logi, parytet), bo infra-log nie jest wpisem w żadnej z nich.
//
// Warunek unieważnienia: przestaje obowiązywać, gdy `_`-prefiks zacznie oznaczać realne wpisy
// pamięci (wtedy potrzebna jest jawna allowlista infra-plików zamiast reguły prefiksu).
function isMemoryEntry(f, indexFile) {
  if (!f.endsWith('.md')) return false;
  if (f === indexFile) return false;
  if (f.toUpperCase() === 'README.MD') return false;
  if (f.startsWith('_')) return false;
  return true;
}

function runSelftest() {
  const results = [];
  const t = (name, cond, got) => {
    results.push(!!cond);
    console.log(`  ${cond ? '✅' : '❌'} ${name}${cond ? '' : ` — dostał: ${got}`}`);
  };

  console.log('[hygiene-audit] selftest (break-restore, syntetyczne fixtury)');

  // --- soczewka isMemoryEntry (co JEST wpisem pamięci) ---
  const IDX = 'MEMORY.md';
  const FILES = ['brand-modes-manta.md', 'MEMORY.md', 'README.md', '_decision-sweep-log.md', 'notes.txt'];
  {
    const kept = FILES.filter(f => isMemoryEntry(f, IDX));
    t('isMemoryEntry silent: realny wpis zostaje', kept.includes('brand-modes-manta.md'), JSON.stringify(kept));
    t('isMemoryEntry fire: indeks NIE jest wpisem', !kept.includes(IDX), JSON.stringify(kept));
    t('isMemoryEntry fire: README NIE jest wpisem', !kept.includes('README.md'), JSON.stringify(kept));
    t('isMemoryEntry fire: nie-markdown NIE jest wpisem', !kept.includes('notes.txt'), JSON.stringify(kept));
    // TEN case jest powodem istnienia tej soczewki: infra-log skilla retro raportował się
    // jako "pamięć bez wpisu w indeksie", czyli check mierzył NIE TEN obiekt.
    t('isMemoryEntry fire: _-prefiks (infra-log) NIE jest wpisem', !kept.includes('_decision-sweep-log.md'), JSON.stringify(kept));
    t('isMemoryEntry: dokładnie 1 z 5 nazw przechodzi', kept.length === 1, JSON.stringify(kept));
  }
  {
    // mirror: reguła jest o PREFIKSIE, nie o tej jednej nazwie — inny infra-log też wypada,
    // a `_` w ŚRODKU nazwy nic nie zmienia (wpisy pamięci używają kebab-case, nie podkreśleń)
    t('isMemoryEntry mirror: dowolny inny _-plik też wypada', !isMemoryEntry('_hygiene-runs.md', IDX), 'przeszedł');
    t('isMemoryEntry mirror: podkreślenie w ŚRODKU nazwy nie wyklucza', isMemoryEntry('foo_bar.md', IDX), 'wypadł');
    // gate-proof: sam brak w indeksie NIE jest kryterium tej soczewki (to robi index-parity),
    // więc nazwa wyglądająca na infra, ale bez prefiksu, dalej JEST wpisem i podlega parytetowi
    t('isMemoryEntry gate-proof: "decision-sweep-log.md" bez prefiksu JEST wpisem', isMemoryEntry('decision-sweep-log.md', IDX), 'wypadł');
  }

  // --- soczewka gate-block ---
  const CHECK_OK = [
    '[gate-block] fence KIT: linie 27–135',
    '[gate-block] payload: 236819 znaków, składnia OK',
    '[gate-block] *Audit: 25/25',
    '[gate-block] WERDYKT: pass',
  ].join('\n');
  const ST_OK = '[gate-block] selftest WERDYKT: PASS (15/15)';
  const CFG = { expectedAudits: 25, minSelftestCases: 15 };

  // silent: zdrowy stan nie strzela
  {
    const r = evalGateBlock({ checkOut: CHECK_OK, selftestOut: ST_OK, ...CFG });
    t('gate-block silent: zdrowy check+selftest → brak findingu', r.ok === true && r.detail === null, JSON.stringify(r));
  }
  // fire (a1): martwa soczewka
  {
    const r = evalGateBlock({ checkOut: CHECK_OK.replace('25/25', '24/25'), selftestOut: ST_OK, ...CFG });
    t('gate-block fire: żywe soczewki 24/25 → finding', r.ok === false && /24\/25/.test(r.detail), JSON.stringify(r));
  }
  // fire (a2): skala zmieniona bez podniesienia progu w configu
  {
    const r = evalGateBlock({ checkOut: CHECK_OK.replace('25/25', '26/26'), selftestOut: ST_OK, ...CFG });
    t('gate-block fire: skrypt 26 soczewek vs config 25 → finding', r.ok === false && /config oczekuje 25/.test(r.detail), JSON.stringify(r));
  }
  // fire (a3): werdykt --check inny niż pass
  {
    const r = evalGateBlock({ checkOut: CHECK_OK.replace('WERDYKT: pass', 'WERDYKT: fail'), selftestOut: ST_OK, ...CFG });
    t('gate-block fire: --check WERDYKT fail → finding', r.ok === false && /WERDYKT: fail/.test(r.detail), JSON.stringify(r));
  }
  // fire (a4): brak licznika = brak pomiaru, nie zielone
  {
    const r = evalGateBlock({ checkOut: '[gate-block] WERDYKT: pass', selftestOut: ST_OK, ...CFG });
    t('gate-block fire: brak linii *Audit → finding (brak pomiaru ≠ czysto)', r.ok === false && /nie wypisał licznika/.test(r.detail), JSON.stringify(r));
  }
  // fire (b): selftest z failem
  {
    const r = evalGateBlock({ checkOut: CHECK_OK, selftestOut: '[gate-block] selftest WERDYKT: FAIL (13/15)', ...CFG });
    t('gate-block fire: selftest 13/15 FAIL → finding', r.ok === false && /13\/15/.test(r.detail), JSON.stringify(r));
  }
  // fire (c): TEN case jest powodem istnienia asercji skali — PASS przy schudniętym selfteście
  {
    const r = evalGateBlock({ checkOut: CHECK_OK, selftestOut: '[gate-block] selftest WERDYKT: PASS (11/11)', ...CFG });
    t('gate-block fire: selftest PASS ale 11 case\'ów vs baseline 15 → finding (rewert --only)', r.ok === false && /break-restore schudł/.test(r.detail), JSON.stringify(r));
  }
  // fire (b2): brak werdyktu selftestu
  {
    const r = evalGateBlock({ checkOut: CHECK_OK, selftestOut: '', ...CFG });
    t('gate-block fire: --selftest bez werdyktu → finding', r.ok === false && /break-restore nie przebiegł/.test(r.detail), JSON.stringify(r));
  }
  // fire (exit): niezerowy exit przy poprawnym stdout
  {
    const r = evalGateBlock({ checkOut: CHECK_OK, checkExit: 1, selftestOut: ST_OK, ...CFG });
    t('gate-block fire: --check exit 1 → finding', r.ok === false && /exit 1/.test(r.detail), JSON.stringify(r));
  }
  // silent (próg opcjonalny): bez progów w configu asercje skali milczą
  {
    const r = evalGateBlock({ checkOut: CHECK_OK.replace('25/25', '26/26'), selftestOut: '[gate-block] selftest WERDYKT: PASS (11/11)' });
    t('gate-block silent: bez progów w configu asercje skali nie strzelają', r.ok === true, JSON.stringify(r));
  }

  // --- soczewka ci-nightly ---
  const NOW = Date.parse('2026-08-28T08:00:00Z');
  const run = (created, mins, event = 'schedule', id = 1) => ({
    event, databaseId: id, conclusion: 'failure',
    createdAt: created,
    updatedAt: new Date(Date.parse(created) + mins * 60000).toISOString(),
  });

  // silent: świeży, szybki nightly
  {
    const r = evalCiNightly({ runs: [run('2026-08-28T06:15:00Z', 5.4)], maxMinutes: 10, now: NOW });
    t('ci-nightly silent: 5.4 min, 1.75 h temu → brak findingu', r.ok === true && r.detail === null, JSON.stringify(r));
  }
  // fire: wolny nightly
  {
    const r = evalCiNightly({ runs: [run('2026-08-28T06:15:00Z', 36, 'schedule', 42)], maxMinutes: 10, now: NOW });
    t('ci-nightly fire: 36 min > próg 10 → finding z numerem runu', r.ok === false && /36\.0 min/.test(r.detail) && /42/.test(r.detail), JSON.stringify(r));
  }
  // fire: harmonogram nie odpalił — BRAK POMIARU, nie „szybko"
  {
    const r = evalCiNightly({ runs: [run('2026-08-25T06:15:00Z', 4)], maxMinutes: 10, maxAgeHours: 48, now: NOW });
    t('ci-nightly fire: szybki ale 74 h stary run → finding (brak pomiaru ≠ zielone)', r.ok === false && /NIE odpalił/.test(r.detail), JSON.stringify(r));
  }
  // fire: workflow_dispatch NIE liczy się jako nightly (inaczej ręczny run maskuje wolny cron)
  {
    const r = evalCiNightly({ runs: [run('2026-08-28T07:00:00Z', 3, 'workflow_dispatch')], maxMinutes: 10, now: NOW });
    t('ci-nightly fire: sam workflow_dispatch → finding (nie udaje nightly)', r.ok === false && r.value === 'brak runu ze schedule', JSON.stringify(r));
  }
  // silent: dispatch obok schedule'a — bierzemy schedule, nie najnowszy run
  {
    const r = evalCiNightly({
      runs: [run('2026-08-28T07:30:00Z', 2, 'workflow_dispatch'), run('2026-08-28T06:15:00Z', 6)],
      maxMinutes: 10, now: NOW,
    });
    t('ci-nightly silent: dispatch nowszy, mierzony jest schedule (6.0 min)', r.ok === true && r.value === '6.0 min', JSON.stringify(r));
  }
  // fire: dispatch nowszy i szybki NIE maskuje wolnego schedule'a
  {
    const r = evalCiNightly({
      runs: [run('2026-08-28T07:30:00Z', 2, 'workflow_dispatch'), run('2026-08-28T06:15:00Z', 35)],
      maxMinutes: 10, now: NOW,
    });
    t('ci-nightly fire: szybki dispatch nie maskuje 35-min schedule\'a', r.ok === false && /35\.0 min/.test(r.detail), JSON.stringify(r));
  }
  // fire: brak danych z gh = brak pomiaru
  {
    const r = evalCiNightly({ runs: null, maxMinutes: 10, now: NOW });
    t('ci-nightly fire: runs=null → finding (brak pomiaru)', r.ok === false && /brak pomiaru/.test(r.value), JSON.stringify(r));
  }
  // fire: pusta lista runów
  {
    const r = evalCiNightly({ runs: [], maxMinutes: 10, now: NOW });
    t('ci-nightly fire: zero runów → finding', r.ok === false && /brak runu ze schedule/.test(r.value), JSON.stringify(r));
  }

  // --- soczewka model-delegation-threshold (REKO 7, 2026-08-27) ---
  // silent: sesja ciężka, ale delegowała
  {
    const r = evalDelegationThreshold({ sessions: [{ sid: 's1', toolCalls: 55, hasDelegation: true }], threshold: 40 });
    t('deleg-threshold silent: 55 wywołań ALE delegacja jest → brak findingu', r.ok === true && r.detail === null, JSON.stringify(r));
  }
  // silent: dużo sesji, żadna nie przekracza progu
  {
    const r = evalDelegationThreshold({ sessions: [{ sid: 's1', toolCalls: 12, hasDelegation: false }, { sid: 's2', toolCalls: 40, hasDelegation: false }], threshold: 40 });
    t('deleg-threshold silent: max 40 (nie >40) bez delegacji → brak findingu (próg ostry)', r.ok === true, JSON.stringify(r));
  }
  // fire: pojedyncza sesja >40 wywołań, zero delegacji
  {
    const r = evalDelegationThreshold({ sessions: [{ sid: 'abc12345', toolCalls: 41, hasDelegation: false }], threshold: 40 });
    t('deleg-threshold fire: 41 wywołań, 0 delegacji → finding z sid i licznikiem', r.ok === false && /abc12345:41/.test(r.detail), JSON.stringify(r));
  }
  // fire: 4/20 sesji ciężkich bez delegacji (kształt dowodu z REKO 7) — reszta czysta nie maskuje
  {
    const heavy = Array.from({ length: 4 }, (_, i) => ({ sid: `h${i}`, toolCalls: 41 + i * 15, hasDelegation: false }));
    const clean = Array.from({ length: 16 }, (_, i) => ({ sid: `c${i}`, toolCalls: 5, hasDelegation: false }));
    const r = evalDelegationThreshold({ sessions: [...heavy, ...clean], threshold: 40 });
    t('deleg-threshold fire: 4/20 sesji ciężkich bez delegacji → finding liczy tylko offenderów (nie 20)', r.ok === false && /^4 sesji/.test(r.value), JSON.stringify(r));
  }
  // silent: brak sesji w oknie
  {
    const r = evalDelegationThreshold({ sessions: [], threshold: 40 });
    t('deleg-threshold silent: puste okno → brak findingu', r.ok === true, JSON.stringify(r));
  }

  // --- soczewka memory-entry-size (ratchet + ledger) ---
  const MES_CAP = 25600; // 25 KB
  const SMALL = [{ name: 'a.md', bytes: 4000 }, { name: 'b.md', bytes: 12000 }];
  // silent: wszystko pod progiem, ledger pusty
  {
    const r = evalMemoryEntrySize({ entries: SMALL, maxBytes: MES_CAP, ledger: {} });
    t('mem-entry silent: wszystkie wpisy pod progiem → brak findingu', r.ok === true && r.detail === null, JSON.stringify(r));
  }
  // fire (a): nowy moloch POZA ledgerem
  {
    const r = evalMemoryEntrySize({ entries: [...SMALL, { name: 'nowy-moloch.md', bytes: 40000 }], maxBytes: MES_CAP, ledger: {} });
    t('mem-entry fire (a): wpis 39 KB poza ledgerem → finding', r.ok === false && /nowy-moloch\.md .*poza ledgerem/.test(r.detail), JSON.stringify(r));
  }
  // silent: ten sam moloch, ale świadomie w ledgerze i NIE urósł
  {
    const r = evalMemoryEntrySize({ entries: [...SMALL, { name: 'znany.md', bytes: 40000 }], maxBytes: MES_CAP, ledger: { 'znany.md': 40000 } });
    t('mem-entry silent: dług w ledgerze na zapisanym rozmiarze → brak findingu', r.ok === true && r.detail === null, JSON.stringify(r));
  }
  // fire (b): TEN case jest powodem istnienia soczewki — kształt realnego regresu 08-27 → 09-02
  //           (git-session-collisions 56 → 62,7 KB przy cap wpisów 42 → 40, czyli check 1 zielony)
  {
    const r = evalMemoryEntrySize({ entries: [{ name: 'git-session-collisions.md', bytes: 64228 }], maxBytes: MES_CAP, ledger: { 'git-session-collisions.md': 57344 } });
    t('mem-entry fire (b): wpis z ledgera urósł ponad zapis → finding (zero zapasu)', r.ok === false && /urósł .* ponad ledger/.test(r.detail), JSON.stringify(r));
  }
  // fire (b) gate-proof: przyrost o 1 bajt też strzela — ratchet nie ma tolerancji
  {
    const r = evalMemoryEntrySize({ entries: [{ name: 'x.md', bytes: 40001 }], maxBytes: MES_CAP, ledger: { 'x.md': 40000 } });
    t('mem-entry fire (b) gate-proof: +1 bajt ponad ledger → finding', r.ok === false, JSON.stringify(r));
  }
  // fire (c): ledger licencjonuje dług, którego już nie ma
  {
    const r = evalMemoryEntrySize({ entries: SMALL, maxBytes: MES_CAP, ledger: { 'zarchiwizowany.md': 30000 } });
    t('mem-entry fire (c): ledger wskazuje na nieistniejący wpis → finding', r.ok === false && /nie istnieje/.test(r.detail), JSON.stringify(r));
  }
  // fire (d): po sweepie ledger musi być zaciśnięty, inaczej re-licencjonuje powrót
  {
    const r = evalMemoryEntrySize({ entries: [{ name: 'po-sweepie.md', bytes: 14000 }], maxBytes: MES_CAP, ledger: { 'po-sweepie.md': 40000 }, shrinkPct: 20 });
    t('mem-entry fire (d): wpis schudł 39→13,7 KB → finding "ZACIŚNIJ ledger"', r.ok === false && /ZACIŚNIJ ledger/.test(r.detail), JSON.stringify(r));
  }
  // silent: schudł nieistotnie (w granicy shrinkPct) — zwykły churn nie nagabuje
  {
    const r = evalMemoryEntrySize({ entries: [{ name: 'churn.md', bytes: 38000 }], maxBytes: MES_CAP, ledger: { 'churn.md': 40000 }, shrinkPct: 20 });
    t('mem-entry silent: −5% (w granicy shrinkPct) → brak findingu', r.ok === true, JSON.stringify(r));
  }
  // silent: brak progu w configu = soczewka nieaktywna, nie „zielona"
  {
    const r = evalMemoryEntrySize({ entries: [{ name: 'huge.md', bytes: 999999 }], maxBytes: null });
    t('mem-entry silent: brak maxEntryBytes → skipped, nie fałszywe zielone', r.ok === true && r.skipped === true, JSON.stringify(r));
  }
  // silent: puste wejście
  {
    const r = evalMemoryEntrySize({ entries: [], maxBytes: MES_CAP, ledger: {} });
    t('mem-entry silent: zero wpisów → brak findingu', r.ok === true, JSON.stringify(r));
  }

  const pass = results.filter(Boolean).length;
  const all = pass === results.length;
  console.log(`[hygiene-audit] selftest WERDYKT: ${all ? 'PASS' : 'FAIL'} (${pass}/${results.length})`);
  return all;
}
