# Life in the Ninth Stratum

This file describes the shipped v0.5 rules. Player values come from the server. The game has asynchronous multiplayer; it does not simulate a real-time movement or combat world.

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

Security patrols take 45 real minutes and 24 energy, pay 20 gross credits, earn 1 trust and 2 Order alignment, and contribute 2 patrols. Shop sessions consume one owned ration or fragment and take 30 real minutes; they pay 7 or 8 gross credits respectively. Existing official/shop/property owners retain their institutions, with current ID rules governing operations.

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
