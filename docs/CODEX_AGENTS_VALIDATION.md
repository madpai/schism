# Native agent validation — 2026-10-08

Validated in `/home/commander/schism` with **codex-cli 0.161.0**. The reviewed
machine-readable receipt is [codex-agents-2026-10-08.json](playtests/codex-agents-2026-10-08.json).
Raw prompt/session transcripts remain outside Git under `/tmp/`.

| Check | Observed result |
| --- | --- |
| Existing infrastructure | No prior `.codex/` agents/config; original AGENTS.md retained verbatim |
| Static role checks | All seven standalone TOMLs parse, have required fields, unique matching names and documented model/effort pairs |
| Account availability | Native `model/list` advertises all four configured model families and every configured reasoning effort |
| Native strict config | Enabled agents, three-child concurrency cap and Sol 6.1/medium child defaults load correctly |
| Fresh session | With no model override, lead resolves to `gpt-6.1-sol` / high; instruction source includes project AGENTS.md |
| Persistent trust | Exact checkout added to machine-local trusted projects; other user settings preserved |
| Error checks | Missing model and unsupported effort catalogs reject; malformed native output fails immediately with a useful message |
| Project preservation | Existing README/HANDOFF content retained; no game source, save schema, assets or release changes |
| Diff hygiene | Python compilation and `git diff --check` pass |

Commands used:

```sh
python3 scripts/check-codex-agents.py
python3 scripts/check-codex-agents.py --native --output /tmp/schism-codex-native-check.json
python3 -m py_compile scripts/check-codex-agents.py
git diff --check
codex --strict-config exec --ephemeral --sandbox read-only --json - \
  < .codex/delegation-demo.txt > /tmp/schism-codex-delegation.jsonl
```

The read-only live demo completed successfully (`turn.completed`). The fresh lead
selected these specialists for a hypothetical communal-kettle repair feature;
the prompt did not select models:

| Specialist | Pinned/requested model and effort | Contribution |
| --- | --- | --- |
| Exploration | GPT-6 Luna / medium | Existing kettle, state, paths and validation map |
| Economy/persistence | GPT-6 Astra / high | Explicit persisted repair stages, atomic consumption, migration/recovery contract |
| Android | GPT-6.1 Sol / high | Physical hallway interaction, lifecycle/touch and rendering coverage |
| QA | GPT-6 Sol / high | Independent regression review after reconciliation |

The first three returned independent analysis in parallel. QA reviewed the
reconciled contract afterward. The lead integrated the results into a proposed
single-writer file map and acceptance checks. It identified a full object atlas,
schema-version test assumptions, and future-schema protection across both save
slots as issues to resolve in a future implementation. Prices, stages and schema
5 were proposals, not changes made to SCHISM. The demo made no edits and ran no
builds or device flows.

The fresh CLI lead reported that named role selection was accepted without a
fallback. The current primary session's collaboration interface exposes explicit
model/effort overrides rather than a role selector; independent exploration,
architecture and QA reviews also completed using Luna/medium, Astra/high and
Sol 6/high with focused contexts and `fork_turns="none"`. These are both native
delegation paths supported by the project instructions. Architecture found the
setup coherent; QA's stdout error-handling finding was fixed before final checks.

Evidence boundaries are explicit: static TOML parsing verifies all seven role
definitions; the native checker verifies config defaults, account catalog and
fresh lead instructions; the live demo exercises four specialist roles. It does
not prove inference for all seven named roles. Spawn receipts expose task
identity but do not expose the resolved provider inference model/effort, so model
routing is verified at the pinned/requested configuration and successful task
completion level. Provider-side inference identity was not independently audited.

A new checkout needs its own trust entry. A new client/model catalog needs the
native check rerun. Existing sessions and explicit UI/CLI model overrides can
retain other settings. An unattended development service, automatic publishing,
physical-device QA and a kettle feature implementation are outside this setup.
