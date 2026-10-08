# SCHISM working rules

DO NOT TURN SCHISM BACK INTO A MENU-HEAVY DASHBOARD GAME. Build interactions with places and objects. Read docs/VISION.md, docs/ARCHITECTURE.md and HANDOFF.md before changing the mobile game.

The active product is mobile/, a Godot Android game. worker/, public/, drizzle/, db/ and old Node scripts remain the v0.10 research prototype. Do not delete or reset browser citizens, modify the live /home/commander/ashfall service, publish the old Site or migrate its production database as part of mobile work.

Keep simulation independent from presentation, persistence and future transport. Validate commands in the authority; use integer money and stored random state; settle each shift once. Save migration never drops unknown item metadata. No survival punishment based on wall-clock absence.

Preserve prompts, provenance, asset hashes, licenses and reproducible synthesis scripts. Touch interactions need tap alternatives and 48dp-equivalent targets. UI must bypass analogue effects. Run mobile tests, headless import, Android export and relevant device flows after simulation changes. Keep honest evidence in docs/playtests and HANDOFF. Commit coherent milestones; do not commit generated engine cache, keystores, credentials, or player saves.

## Native Codex delegation

The primary session is SCHISM's lead orchestrator. `.codex/config.toml` selects GPT-6.1 Sol with high reasoning; `.codex/agents/*.toml` defines the specialists. **This project explicitly requests automatic native subagent delegation for substantial development tasks**, including future sessions: choose specialists yourself without asking the user to select models. Follow the detailed setup and verification guide in `docs/CODEX_AGENTS.md`. Higher-priority session restrictions and an explicit user request for solo work still apply.

Handle trivial, localized edits directly. For substantial work, delegate when domain expertise, independent review or parallel work improves the outcome. Use only the needed specialists; do not start the whole team or a research agent for a file whose behavior is already clear. The lead owns planning, acceptance criteria, contracts, integration, final checks and HANDOFF updates.

| Task | Native agent | Model / reasoning |
| --- | --- | --- |
| Cross-system design, authority or schema contracts | `schism_architecture` | GPT-6 Astra / high |
| Gameplay commands and physical interactions | `schism_gameplay` | GPT-6.1 Sol / medium |
| Currency, settlement, save integrity and migrations | `schism_economy_persistence` | GPT-6 Astra / high |
| Focused mapping and documentation research | `schism_exploration` | GPT-6 Luna / medium |
| Locations, authored objects, story and assets | `schism_world_content` | GPT-6 Sol / medium |
| Android touch, lifecycle, rendering and performance | `schism_android` | GPT-6.1 Sol / high |
| Independent correctness review and regression testing | `schism_qa` | GPT-6 Sol / high |

Spawn the named native custom agent when the runtime exposes role selection; its TOML pins the model and effort. If the runtime only exposes `collaboration.spawn_agent` with model/effort overrides, use the matching file's instructions in a focused task with those exact overrides and `fork_turns="none"`. A full-history fork inherits the lead's model in that interface, so it does not implement this model routing. Do not build an external dispatcher. If a model or custom role is unavailable, check the runtime catalog, report the limitation, and use an available compatible specialist model explicitly; never claim an unverified model ran. Escalate unresolved deep design questions from Luna/Sol to Astra as needed, through the lead.

Before each spawn, supply the objective, relevant context/accepted contracts, read-only or exact writable paths, acceptance criteria, checks and expected result. Specialists must read the existing project instructions and must not delegate recursively unless the lead explicitly assigns a further independent subtask. All agents share a working tree: assign exactly one writer per file, including tests and JSON catalogs. `simulation.gd` is shared by gameplay and economy, and `main.gd`/object catalogs span UI and content; sequence those edits or use one writer with read-only specialist advice. Parallelize disjoint work or read-only review after contracts are stable, within the configured three-child limit. Serialize Godot imports/builds, shared artifact directories and use of the same device. An assigned path list is a coordination rule, not a filesystem security boundary.

Wait for every needed result, inspect the combined diff, resolve interface mismatches, and run checks on the integrated tree. Fix failed checks through the owner and recheck affected behavior. Delegation never substitutes for lead verification. Report changes, actual tests and material limitations. For agent/config-only changes, validate native loading/model routing instead of exporting an unchanged game; simulation changes still require the mobile checks, export and relevant device flows above.
