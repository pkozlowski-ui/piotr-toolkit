#!/usr/bin/env node
// Snapshot bookkeeping for the inspiration sweep.
//
// The model does the fetching and the judging; this file does the remembering,
// because "did I already look at this?" is exactly the question a model answers
// from vibes and a file answers from fact. Without it a monthly routine re-reads
// 88 cookbook entries every month, costs real tokens, and re-proposes things that
// were already rejected — the failure mode that makes recurring routines get
// switched off.
//
// Usage:
//   node snapshot.mjs diff <source>          # ids on stdin, one per line ("id<TAB>title")
//   node snapshot.mjs diff <source> --write   # …and record them as seen
//   node snapshot.mjs list <source>
//   node snapshot.mjs forget <source> <id>   # re-surface one entry next run
//
// Exit codes: 0 = nothing new, 10 = new entries found (so a caller can branch),
// 2 = usage error. Empty stdin is a usage error, never "nothing new" — a failed
// fetch must not read as a quiet clean sweep.
import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const stateDir = join(dirname(dirname(fileURLToPath(import.meta.url))), 'state')
const [cmd, source, ...rest] = process.argv.slice(2)

const die = (msg) => {
  console.error(`✗ ${msg}`)
  process.exit(2)
}

if (!cmd) die('usage: snapshot.mjs diff|list|forget <source> [--write]')
if (cmd !== 'list' && !source) die(`"${cmd}" needs a <source> (e.g. cookbook, claude-code-changelog)`)

const statePath = (s) => join(stateDir, `${s}.tsv`)

const readState = (s) => {
  const p = statePath(s)
  if (!existsSync(p)) return new Map()
  return new Map(
    readFileSync(p, 'utf8')
      .split('\n')
      .filter((l) => l.trim() && !l.startsWith('#'))
      .map((l) => {
        const [id, seenAt, title] = l.split('\t')
        return [id, { seenAt, title: title ?? '' }]
      }),
  )
}

const writeState = (s, map) => {
  mkdirSync(stateDir, { recursive: true })
  const lines = [
    `# ${s} — entries already reviewed by inspiration-sweep. One per line: id<TAB>firstSeen<TAB>title`,
    `# Delete a line (or: snapshot.mjs forget ${s} <id>) to have the next sweep look at it again.`,
    ...[...map.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([id, v]) => `${id}\t${v.seenAt}\t${v.title}`),
  ]
  writeFileSync(statePath(s), `${lines.join('\n')}\n`)
}

if (cmd === 'list') {
  if (!source) {
    const sources = existsSync(stateDir) ? readdirSync(stateDir).filter((f) => f.endsWith('.tsv')) : []
    console.log(sources.length ? sources.map((f) => f.replace('.tsv', '')).join('\n') : '(no sources tracked yet)')
    process.exit(0)
  }
  const state = readState(source)
  console.log(`${source}: ${state.size} entries seen`)
  for (const [id, v] of state) console.log(`  ${v.seenAt}  ${id}`)
  process.exit(0)
}

if (cmd === 'forget') {
  const id = rest[0]
  if (!id) die('forget needs an <id>')
  const state = readState(source)
  if (!state.delete(id)) die(`"${id}" was not in ${source}`)
  writeState(source, state)
  console.log(`✓ ${id} will be re-reviewed on the next sweep`)
  process.exit(0)
}

if (cmd !== 'diff') die(`unknown command "${cmd}"`)

const stdin = readFileSync(0, 'utf8')
const incoming = stdin
  .split('\n')
  .map((l) => l.trim())
  .filter((l) => l && !l.startsWith('#'))
  .map((l) => {
    const [id, ...titleParts] = l.split('\t')
    return { id: id.trim(), title: titleParts.join(' ').trim() }
  })
  .filter((e) => e.id)

// A fetch that returned nothing is a broken channel, not an empty world. Reporting
// it as "nothing new" is the same lie as a check that cannot fire reporting green.
if (incoming.length === 0) die('stdin held no entries — the fetch failed, or the format is not "id<TAB>title"')

const state = readState(source)
const fresh = incoming.filter((e) => !state.has(e.id))
const gone = [...state.keys()].filter((id) => !incoming.some((e) => e.id === id))

console.log(`${source}: ${incoming.length} upstream, ${state.size} seen, ${fresh.length} new, ${gone.length} vanished`)
for (const e of fresh) console.log(`NEW\t${e.id}\t${e.title}`)
// Vanished entries are reported but never removed from state: an index that drops
// an item does not un-review it, and re-adding it later should stay quiet.
for (const id of gone) console.log(`GONE\t${id}\t${state.get(id).title}`)

if (rest.includes('--write')) {
  const today = new Date().toISOString().slice(0, 10)
  for (const e of fresh) state.set(e.id, { seenAt: today, title: e.title })
  writeState(source, state)
  console.log(`✓ recorded ${fresh.length} new entr${fresh.length === 1 ? 'y' : 'ies'} as seen (${today})`)
}

process.exit(fresh.length ? 10 : 0)
