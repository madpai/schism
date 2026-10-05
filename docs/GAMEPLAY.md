# Life in the Ninth Stratum

This file describes the v0.7 rules. Player values come from the server. The game has asynchronous multiplayer; it does not simulate a real-time movement or combat world. This update preserves all existing characters.

## Account, arrival, and appearance

Sites provides ChatGPT sign-in; the stable authenticated user ID owns one citizen. Opening the state endpoint creates an unregistered account record. A valid registration supplies a character name and appearance, and starts residency, housing grace, and the first tax deadline. The train arrives at the existing shared server day. Registration cannot be replayed or used to reset a character.

Appearance: Woman/Man/Nonbinary; Porcelain/Sand/Olive/Bronze/Umber/Ebony skin; Black/Brown/Copper/Blonde/Silver/Violet hair; Cropped/Swept/Bob/Braids/Shaved styles; Lean/Broad/Soft builds. No choice changes stats. Names accept 2–24 Unicode letters, numbers, spaces, periods, underscores, and hyphens.

Existing saves without a registration field are established residents. They receive default editable appearance and civic ledger fields while retaining possessions and progress. Residence age uses the original saved `joined` timestamp.

After the residency release, the owner explicitly requested resetting the old characters to remove their easier-economy head start. The one-time live reset completed October 5, 2026, at 16:08:47 UTC. It cleared all citizens, player listings, noticeboard posts, personal journals, and unfinished district commitments. The next sign-in creates an unregistered citizen with no inherited credits, careers, housing, tax debt, or story progress. Registration starts the new character's residence age. The shared clock, market, faction/project state, and completed contributions continue; regular updates do not reset characters.

## Shared time and activity

The server epoch remains October 5, 2026, 00:00 UTC. A shared day is six real hours and contains 24 fifteen-minute city hours. Residence age counts complete real 24-hour days since registration; it is separate from server day.

Work, sleep, crime, organizing, clinic treatment, shop sessions, official duty, security patrols, city-response work, and registry review create one timed assignment per citizen. Energy and consumed stock/fees are reserved on starting. Positive rewards and progression wait for the deadline. Eating, buying, taxes, rent, trade, and equipment management remain available during an assignment. Starting a second assignment is rejected. Quota claiming and career switching wait until it finishes.

Settlement applies pending rewards once with a version-guarded transaction and completion journal entry. Balance additions preserve purchases and incoming trade payments made during an assignment. District contributions are immutable scheduled rows, so other citizens see completed output without waiting for its owner to sign in.

Eight city hours of employment, official duty, security duty, or district-response work may be started per shared city day. A shift crossing midnight charges the starting day’s permit and records its quota on the completion day. Sleep is available once per starting city day. There are three criminal operations and two shop sessions per city day.

Finite narrative choices and daily faction rites consume their declared energy without advancing shared time. They retain replay protection and story history. The shared faction balance, quotas, projects, and district metrics reset on the six-hour city day; private allegiance and progression persist.

## Survival and housing

New citizens have 0 credits, health 78, energy 58, fullness 42, warmth 35, and no trust or allegiance. They have worn clothing, boots, an identity implant, and a bunk. The first rent bill arrives six real hours after registration.

Per city hour, fullness falls by 2, or 1.5 during sleep. Idle energy returns at 1/hour, sleep at 6/hour; employment does not regenerate energy. Completing full sleep grants 16 additional energy and 8 health. Completing housed sleep restores warmth: bunk 20, room 32, apartment 40. Street sleep grants no warmth.

During an assignment, hourly cold exposure is 3 without an insulated shroud or 1 with it, before district weather and heating effects. Idle/sleep baseline hourly cold exposure: street 3, bunk 1, private room 0.5, heated apartment 0.25. An equipped insulated shroud reduces this by 0.6; shared repairs and communal boilers each reduce exposure by 1; a null front increases it by 1. The minimum cold exposure is 0.2/hour. Below 15 fullness or warmth, exposure damages health. Passive health cannot fall below 10, allowing relief recovery instead of irreversible death.

Offline survival settlement is capped at seven real days per visit and uses the current district weather/heating. Rent deadlines are timestamp-based; four unpaid bills trigger street eviction, with rent arrears bounded to four unpaid cycles rather than growing without limit. Paying rent restores access to a bunk.

| Housing | Deposit | Rent per six-hour cycle | Additional eligibility |
| --- | --- | --- | --- |
| Bunk | Starting assignment | 12 CR | Settle an eviction to re-enter |
| Private room | 45 CR | 20 CR | Not evicted |
| Heated apartment | 180 CR | 32 CR | Currently in a room; 2 real residency days; 20 trust |

Once per city day, relief is consumed immediately: +24 fullness, +10 warmth, health raised to at least 25 and energy to at least 20. It grants no tradeable ration or credits. Public custodial work is available to a tax- or arrest-flagged citizen after any active sentence ends.

## Tax and identity holds

Tax is 12% of recorded earned income: employment, licensed shops, administration, security, paid city-response work, quotas, property income, broker sales, citizen exchange sales, and reported narrative wages. Illegal operations, Wound payments, and unreported story proceeds are outside Revenue’s ledger.

The server keeps gross earned income, unpaid tax, lifetime paid tax, and fractional carry in hundredths of a credit. Whole-credit tax is assessed as earnings accrue; small earnings cannot avoid tax by splitting transactions. The player pays manually. The deadline is six real hours after registration or the most recent payment; with no whole-credit debt, an elapsed deadline rolls forward. Once a deadline expires with debt, the ID receives a delinquency hold.

A tax hold or unresolved arrest blocks mnemonic/recovery factory jobs, factory/freight emergency work, shop licensing and shop operation, administration, and security. An active detention also restricts other actions; taxes, rent, posts, owned consumables, and relief remain available.

To clear an ID:

1. Pay all whole-credit tax debt.
2. Finish detention and reduce heat to 20 or below.
3. Complete Registry review: 2 CR, 6 energy, and 15 real minutes. With less than 2 CR, the no-fee indigence appeal takes 14 energy and 30 real minutes.

Paying debt alone and finishing detention alone each leave the hold intact. Factory access returns only after clearance completes. Heat normally fades by 0.25 per city hour. A 12-credit bribe reduces heat by 35 but does not clear an ID hold.

## Careers, institutions, and crime

Four careers preserve separate XP. Each work hour earns 2 XP; ranks at 24, 80, and 180 XP provide +1/+2/+3 credits on the active matching path. Specialist job eligibility also requires trust and the specified XP. Three completed shifts on a path in one shared day award a once-only 3-CR, 1-trust quota bonus. Gear affects fatigue, hazards, cold, coherence, field pay, and checkpoint capture risk.

| Institution | Requirements |
| --- | --- |
| Shop license | 1 real residency day, 10 trust, clean ID, 90 CR |
| Municipal administration | 2 real days, 25 trust, 80 civic XP, heat below 20, clean ID, 60 CR |
| Security forces | 7 real days, 30 completed shifts, 60 trust, 180 civic XP, Order +40, heat at most 10, clean ID, no active detention |

Security patrols take 45 real minutes and 24 energy, pay 20 gross credits, earn 1 trust and 2 Order alignment, and contribute 2 patrols. Shop sessions take 30 real minutes and 8 energy, consuming one owned item: ration (7 gross CR), fragment (8), warming pack (6), dressing (4), or neural patch (7). Two sessions per cycle limit simulated foot traffic. Existing official/shop/property owners retain their institutions, with current ID rules governing operations.

Successful theft earns three fragments and 3 underground XP; successful smuggling earns 24 gross unreported credits (28 with Chaos dominance) and 6 underground XP. Each success moves private alignment 3 toward Chaos and adds 12 heat. Street contact, known runner, and district fixer titles appear at 9/24/60 underground XP.

Capture risk starts at 30% for theft and 40% for smuggling, adds heat/200, and includes faction, equipment, and district security effects. Arrest confiscates up to 7/15 credits, lowers trust by 2, costs 8 health, adds 20 heat, sets an arrest hold, and adds a two-city-hour sentence after the operation ends. Three attempts per city day cap repetition.

## District causality

The active production target is `max(6, recently active registered citizens × 3)`; recent activity means an action during the previous real day. District contributions count only once their scheduled completion timestamp has passed and are grouped by completion city day.

| Event | Trigger | Shared effect |
| --- | --- | --- |
| Null front | Weather phase 2 | Food +2 CR; cold +1/hour |
| Identity sweep | Weather phase 3 | Capture +15 percentage points |
| Production shortfall | City hour ≥12 and production below target | Food +1 CR; shift pay −1 CR |
| Relief train held | City hour ≥8 and freight below 3 | Food +1 CR |
| District lockdown | At least 3 crime, patrols below crime | Food +1 CR; capture +10 points |
| Negotiated contract | At least 3 organizing shifts | Shift pay +2 CR; capture +5 points |
| Printer lines restored | Production reaches target | Food −1 CR |
| Communal boilers | At least 4 relief | Cold −1/hour |
| Relief train unloaded | Freight reaches 3 | Remove border surcharge |

Mnemonic and recovery work contribute production equal to hours; transit contributes equivalent freight; civic work contributes 1 relief. Organizing adds 1 unrest; a criminal operation adds 1 crime; security adds 2 patrols. Completed production and freight deliver ration/broth stock once using a guarded delivered counter. Food modifiers combine with Order/Chaos price effects; prices never fall below 1 CR.

Citizens can take published district-response assignments: emergency printers (2 city hours, 18 energy, 5 CR, 4 production), unload relief freight (2 hours, 22 energy, 6 CR, 3 freight), or run the boiler (2 hours, 12 energy, one fragment, 1 trust, 2 relief). The boiler remains available with an ID hold.

## Short activities, salvage, and crafts

One short-task slot runs alongside an ordinary `work` shift. The off-duty tasks (bins, electronics, casino) require no long assignment. Work-break tasks and crafts are unavailable during sleep, detention, clinic, official/security duty, and other non-work assignments. An unfinished short task must finish before starting a long assignment. All short tasks, recipes, network contracts, and casino hands share a ten-start limit per six-hour city cycle. The starting cycle pays the quota, even when the task finishes after midnight.

| Task | Real seconds | Energy | Result |
| --- | --- | --- | --- |
| Search collection bins | 25 | 4 | Two fabric or two wire, equally likely |
| Strip dead electronics | 45 | 5 | Two wire and one circuit part; 20% chance of 2 health damage |
| Clean a terminal | 20 | 3 | 1 taxable CR |
| Decode a signal | 35 | 4 | One signal trace |
| Patch a heating relay | 60 | 6 | Costs one wire; 2 taxable CR and one shared relief |

| Recipe | Ingredients | Real seconds / energy | Result |
| --- | --- | --- | --- |
| Warming pack | Two fabric, one wire | 45 / 3 | Consumable: +14 warmth |
| Field dressing | Two fabric | 35 / 3 | Consumable: +10 health |
| Relay fragment | Three wire, one circuit | 75 / 6 | One ordinary relay fragment; trade, sell, or repair with it |
| Neural patch | Two circuits, two traces | 60 / 5 | Consumable: +12 coherence |

Costs are reserved at start; rewards and one workshop XP arrive at completion. Workshop XP is a record of crafting, not civic career XP. Materials are carried separately; crafted relay fragments use the existing fragment inventory. Crafted consumables work during a shift and in detention. Repairs and contract contributions become visible to the whole city at completion, even before their owner returns.

## Civic neural network and the Null House

Three persistent player chat channels: District IX, Exchange wire, and The Uncounted. Character names are attached by the server. Messages accept 1–320 characters, with 15 seconds between transmissions and 40 per real hour. The interface polls every ten seconds while the network screen is visible and the player is not typing. Chat is available during shifts and detention.

Two network contracts are each available once per cycle. Each costs one trace and 50 seconds. A public freight manifest costs 5 energy, pays 2 taxable CR and 1 trust, and contributes one freight. A hidden Wound echo costs 6 energy, pays 3 unreported CR, adds 4 heat, moves personal alignment −1, and contributes one criminal operation. Decode signals to obtain traces.

A Null House hand costs 6 energy and 20 seconds. Stakes must be whole credits from 1–3; the stake is reserved immediately. A 45% win returns twice the stake; otherwise nothing returns. Expected loss is 10% of the stake. Four hands per cycle are also counted toward the common ten-task limit. Gambling proceeds are unreported; there is no debt, cancel/reroll, or client-chosen outcome.

## Neighborhood encounters and free planning

Completing bins, salvage, signal decoding, and the first ordinary paid shift discovers four distinct encounters. Discovery happens at completion, not on starting an action. Each has server-owned nodes, published choices, and a persistent decision record. Repeating the task does not create another copy; reloads cannot change an offered node or replay a reward.

| Discovery | Contact | Initial alternatives | Later consequences |
| --- | --- | --- | --- |
| Ration card in a bin | Neri | Return for trust/Order; sell for 2 taxable CR; forge for heat/Chaos | Return or forge branches receive a reply after 60 seconds; meet the boiler crew, donate a dressing, warn Rook, or erase evidence |
| Sabotaged hardware | Esra | Report for trust; spend 2 energy to strip wire/circuit; send evidence to Rook | Reporting or copying leads to a follow-up and contacts/evidence choices |
| Disputed identity record | Voss | Correct for trust/Order; consult Rook using a trace; delete | Correct/consult branches lead to address correction or a quiet route |
| Missing hours after a shift | Esra | Record the discrepancy; keep quiet; leak the badge log to Rook | Recorded/leaked evidence receives a later crew or checkpoint choice; your original wages are unchanged |

Most replies cost no energy and pay no money. The interface lists the exact immediate cost and consequence beside each choice. Contacts, flags, and the last 40 decisions persist; these are finite authored stories rather than simulated AI chats. Respond while idle or on an ordinary shift, after detention. Other long assignments require full attention. Zero-energy responses remain available to an exhausted worker when no item cost applies.

Three free bulletins can be read once per cycle: checkpoint timings, the repair crew's demand board, and civic obligations. They spend neither energy nor a short-task start. The checkpoint bulletin prepares one quiet crime route. Named story choices may prepare the same benefit; it does not stack.

Alternatively, paid reconnaissance takes 30 seconds, 4 energy, one trace, and one short-task start while off duty. A prepared route subtracts **10 percentage points** from capture risk for one operation. It is consumed when that operation starts, succeeds or fails, and expires at the cycle boundary. A late return cannot restore an expired route. Normal heat, arrest, taxes, and attempt limits still apply.

The overview prioritizes a meal/relief, work or useful work breaks, civic recovery, and rent/tax savings according to current state. Task cards show remaining energy after a start and warn when the public custodial reserve would be spent. Free planning, conversations, chat, and trade offer activity without turning exhaustion into unlimited wages.

## Funded supply orders

The citizen exchange accepts listings and buy orders for fabric, wire, circuits, traces, warming packs, dressings, neural patches, rations, medicine, and fragments. Orders request 1–10 units at an integer 1–50 CR per unit. The full price is reserved upfront; ordinary citizens may have three open orders, licensed shops eight. Buyers cannot fill their own orders.

Another citizen delivers all or part of the requested quantity from actual owned stock. Goods enter the buyer's inventory immediately; the supplier receives the corresponding gross payment and 12% tax assessment in the same transaction. Canceling returns only the undelivered escrow and leaves previous deliveries intact. Concurrent fills or cancellation cannot spend the same escrow twice. Orders, cancellations, and listings use no energy and can be managed during an ordinary assignment.

Two municipal orders establish a small demand floor each cycle. Odd cycles request wire at 2 CR and dressings at 3 CR; even cycles request warming packs at 4 CR and wire at 2 CR. Shared quantities are fixed at creation between three and eight units from recent contributors. Each citizen can make **one one-unit municipal delivery per cycle**, not one per order. Refreshing does not restock it. Municipal dressing or warming-pack deliveries also contribute one relief. Unfilled municipal orders close when the cycle changes; citizen orders persist.

## An emergency that develops

Odd cycles open **The cold line**; even cycles open **The relief convoy**. The first real hour is a warning, with no extra crisis penalty. The response deadline is five real hours after the shared cycle begins. Between warning and deadline, unmet boiler demand adds 0.5 cold exposure per city hour, or unmet freight demand adds 1 CR to food prices. Reaching the target stabilizes conditions; a subsequent criminal diversion can destabilize them again.

The fixed target is `max(3, min(12, ceil(recent completed contributors × 1.5)))`, sampled when the emergency is created. New arrivals and repeated reads cannot raise the requirement. Progress is completed repair units minus completed diversion units, bounded at zero for display. Boiler repair units come from relief and patrol contributions; freight repair units come from freight contributions. Crime subtracts units. Only commitments finishing by the deadline count. Relevant ordinary jobs, network contracts, municipal deliveries, and career cases use those same contributions.

| Direct response | Seconds / energy | Consumed item | Result |
| --- | --- | --- | --- |
| Deliver supplies | 25 / 2 | One warming pack (boiler) or wire (freight) | Repair +1; 1 taxable CR; trust +1 |
| Join crew / verify seal | 60 / 6 | One wire (boiler) or trace (freight) | Repair +2; 2 taxable CR; trust +1 |
| Divert stock | 45 / 7 | One trace | Diversion +2; 4 unreported CR; heat +6; Chaos +2; crime +1 |

At most two direct responses per citizen per cycle; both use the ordinary short-task slot and ten-start quota and can fit into an ordinary work break. Costs are reserved, and payouts wait for completion. Actions that cannot finish by the deadline are denied.

At the deadline, the server records secured or failed from immutable completed commitments. The last real hour of the cycle applies the outcome: secured boiler −0.5 cold/hour, failed boiler +1 cold/hour; secured freight food −1 CR, failed freight food +1 CR. These modifiers combine with existing events. The district shows its last five recorded outcomes. Reads resolve overdue incidents once; a citizen need not be online at completion. Cycles never opened by any read do not receive invented historical incidents. Late arrivals inherit the actual current phase and cannot start a new personal day-one crisis.

## Earned career cases

Each eligible desk offers one case per citizen per cycle. Read its brief for free before choosing a response. Administration/security/shop require the existing earned institution and a cleared ID; underground access requires 3 underground XP or a Rook contact. Free review may happen during ordinary work. The timed response requires off-duty time and uses the short-task slot and common ten-start limit. It grants no accelerated appointment or civic XP.

| Desk / response | Seconds / energy | Reward and consequence |
| --- | --- | --- |
| Administration: verify | 45 / 5 | 3 taxable CR, trust +1, Order +1, freight +1 |
| Administration: hold | 35 / 4 | 2 taxable CR, trust +1, Order +2, patrol +1 |
| Administration: false stamp | 40 / 5 | 5 unreported CR, heat +5, Chaos +3, crime +1 |
| Security: check evidence | 60 / 6 | 4 taxable CR, trust +1, Order +1, patrol +2, relief +1 |
| Security: seize | 45 / 5 | 3 taxable CR, Order +2, patrol +2 |
| Security: bribe | 45 / 5 | 6 unreported CR, heat +7, Chaos +4, crime +2 |
| Shop: crew sale | 35 / 3 | Consume warming pack; 4 taxable CR, trust +1, relief +2 |
| Shop: private sale | 30 / 3 | Consume warming pack; 6 taxable CR |
| Underground: restore manifest | 40 / 4 | Consume trace; 2 taxable CR, trust +1, freight +1 |
| Underground: divert | 50 / 6 | Consume trace; 5 unreported CR, heat +5, Chaos +2, crime +1, underground XP +1 |

The case closes at completion; wages, alignment, XP, and supplies do not arrive early. Case work adds scheduled city and crisis commitments in the starting transaction. These cases use authored municipal/private buyers; citizen buy orders are separate, funded by actual players.

## Earned wardrobe

Municipal appointment awards and equips a Canon administrative uniform. Security recruitment awards and equips a Canon security uniform. Existing earned institutions receive their uniforms on normal save compatibility. Neither uniform is for sale or substitutes for an insulated shroud. The portrait follows the equipped body item; all gender, skin, hair, and build choices remain cosmetic. Selecting Shaved adds no hair layer.
