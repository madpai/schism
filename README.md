# SCHISM

A persistent dystopian city survival game, powered by a Cloudflare Worker and Sites D1. The interface is a DOS-inspired citizen terminal with original dithered city, factory, and market artwork in `public/`.

Each authenticated Sites user has a durable citizen. The server validates every action and owns balances, inventory, trust, health, rent, and crime outcomes. D1 transactions enforce shared-stock and player-trade integrity. The shared world changes every six hours, and elapsed time is settled when players return. Offline survival costs accrue for up to seven days per visit. Personal work and rest advance the citizen’s clock.

Play includes jobs and trust unlocks, food and warmth, rent and eviction, private housing, risky theft and smuggling, union membership and organizing, trading, shop licenses, property leases, municipal posts, citizen names, and a shared noticeboard. The landlord and official roles are an initial progression layer. This first version uses asynchronous multiplayer and a polling noticeboard, rather than a real-time movement world.

Personal encounters provide four branching story threads: Iona at the worker blocks, Havel’s wage deductions, Rook’s sealed delivery, and Voss’s permit registry. Choices have server-validated resource costs, relationship changes, gated follow-ups, and durable decision history. Different citizens keep separate stories within the shared city. The starting chapter is directly playable in Overview; all encounters, contacts, and decisions appear in Your story.

The district-heating project is a shared multiplayer objective: donate 12 scrap in total, earn contributor trust, and reduce hourly cold exposure by one point for every citizen. A new project begins each city day. Atomic guards prevent duplicate final contributions and reject already-resolved personal choices. Existing character saves acquire story fields without resetting progress.

The desktop keyboard accepts 1–3 to select the first visible encounter’s responses; mobile exposes the same labeled choices. Optional browser agent tools are feature-detected. Their native WebMCP registration could not be validated in the available browser.

## Build and verify

Run `npm install`, `npm run db:generate` for new unapplied schema changes, `npm test`, `npm run build`, and `npm run validate`. Build emits a single Worker module with embedded HTML, CSS, JavaScript, and WebP assets, plus generated D1 migrations. Publishing is handled through the Sites skill.

The site requires the trusted `oai-authenticated-user-id` header forwarded by the Sites platform; requests without identity cannot load or change a character. To use the game with more citizens, the owner can change the Site sharing audience through Sites.
