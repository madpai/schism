# SCHISM

A persistent occult cyberpunk city survival game, powered by a Cloudflare Worker and Sites D1. The interface is a legacy neural terminal with near-black panels, pale phosphor text, and crimson/violet signals. Three original raster scenes in `public/` depict the Ninth Stratum, the Mnemonic Foundry, and the Null Exchange. Generated source prompts and provenance are recorded in `art/occult-provenance.json`.

Each authenticated Sites user has a durable citizen. The server validates every action and owns balances, inventory, trust, health, rent, and crime outcomes. D1 transactions enforce shared-stock and player-trade integrity. The shared world changes every six hours, and elapsed time is settled when players return. Offline survival costs accrue for up to seven days per visit. Personal work and rest advance the citizen’s clock.

Play includes jobs and trust unlocks, food and warmth, rent and eviction, private housing, risky theft and smuggling, union membership and organizing, trading, shop licenses, property leases, municipal posts, citizen names, and a shared noticeboard. The landlord and official roles are an initial progression layer. This first version uses asynchronous multiplayer and a polling noticeboard, rather than a real-time movement world.

Personal encounters provide five branching story threads: an out-of-sync mirror transmitting the Canon and the Wound, Iona in the cell stacks, Havel’s memory-archive wage deductions, Rook’s sealed mnemonic delivery, and Voss’s identity registry. Choices have server-validated resource costs, relationship changes, gated follow-ups, and durable decision history. Different citizens keep separate stories within the shared city. The starting chapter is directly playable in Overview; all encounters, contacts, and decisions appear in Your story.

Order and Chaos share a city balance between -100 and +100. At +20, the Canon lowers ration/broth prices by 1 credit and raises capture risk by 10 percentage points. At -20, the Wound raises food prices by 1 credit, lowers capture risk by 10 percentage points, and raises successful package-run pay to 28 credits. The contested range uses ordinary prices and risks. Personal signal choices and one daily rite per citizen change the balance. An Order rite consumes a relay fragment and earns trust/coherence; a Chaos rite earns credits and surveillance while reducing coherence. City influence resets each six-hour city day; private alignment, coherence, and story history persist. Coherence is an implant-status record altered by choices, rites, and clinic treatment; it does not impose an additional survival penalty.

The thermal-lattice project is a shared multiplayer objective: donate 12 relay fragments in total, earn contributor trust, and reduce hourly cold exposure by one point for every citizen. A new project begins each city day. Atomic guards prevent duplicate final contributions, duplicate rites, and replayed personal choices. Existing character saves acquire story and signal fields without resetting progress. Legacy inventory keys remain unchanged to preserve saved items and existing player listings.

The desktop keyboard accepts 1–3 to select the first visible encounter’s responses; mobile exposes the same labeled choices. Optional browser agent tools are feature-detected. Their native WebMCP registration could not be validated in the available browser.

## Build and verify

Run `npm install`, `npm run db:generate` for new unapplied schema changes, `npm test`, `npm run build`, and `npm run validate`. The 87 gameplay checks cover survival and progression, concurrent stock/trades/repairs/rites, private branching stories, shared faction effects, replay protection, and city-day resets. Build emits a single Worker module with embedded HTML, CSS, JavaScript, and WebP assets, plus generated D1 migrations. Publishing is handled through the Sites skill.

The site requires the trusted `oai-authenticated-user-id` header forwarded by the Sites platform; requests without identity cannot load or change a character. To use the game with more citizens, the owner can change the Site sharing audience through Sites.
