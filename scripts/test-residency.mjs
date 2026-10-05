import assert from 'node:assert/strict';
import {harness} from './test-harness.mjs';
import {act,world} from '../worker/game.js';
import {CITY_HOUR_MS,CITY_DAY_MS,defaultAppearance,accrueTax} from '../worker/residency.js';
let checks=0;const check=(condition,label)=>{assert.ok(condition,label);checks++;};const reject=async(op,pattern)=>{await assert.rejects(op,pattern);checks++;};
{
 const h=harness();h.now+=CITY_DAY_MS*40;const first=await h.read('new');
 check(first.world.day===41&&!first.citizen.registered,'New account enters the existing server day');
 await reject(()=>h.register('new','<script>'),/name/);
 await reject(()=>h.start('new',{action:'register',name:'Valid',appearance:{...defaultAppearance,skin:'injected'}}),/appearance/);
 await reject(()=>h.start('new',{action:'register',name:'Valid',appearance:[]}),/appearance/);
 const appearance={gender:'Woman',skin:'Ebony',hair:'Copper',style:'Braids',frame:'Broad'};
 let s=await h.start('new',{action:'register',name:'Mara Kess',appearance});
 check(s.citizen.name==='Mara Kess'&&JSON.stringify(s.citizen.appearance)===JSON.stringify(appearance),'Full character appearance and name are server-saved');
 check(s.citizen.credits===0&&s.citizen.alignment===0&&s.citizen.rep===0,'Arrival is broke and neutral');
 check(s.citizen.rentDebt===0&&s.citizen.nextRentAt-h.now===CITY_DAY_MS,'New arrival receives a free bunk and the shared six-hour bill clock');
 check(s.citizen.daysInCity===0&&s.citizen.arrivalDay===41,'Residence age and server day are independent');
 await reject(()=>h.register('new','Again'),/already/);
 await h.start('new',{action:'appearance',appearance:{...appearance,hair:'Silver'}});s=await h.read('new');check(s.citizen.appearance.hair==='Silver'&&s.citizen.name==='Mara Kess','Appearance editing preserves identity');
 await h.register('other','Other Name');check((await h.read('other')).citizen.appearance.hair==='Black','Separate accounts do not share appearance');
 h.now+=86400000;s=await h.read('new');check(s.citizen.daysInCity===1&&s.world.day===45,'Residence days are elapsed 24-hour account days');
}
{
 const h=harness();await h.fixture('worker',{credits:100,energy:100,health:100,fullness:100,warmth:100});
 let s=await h.start('worker',{action:'work',id:'sorting'}),ends=s.citizen.activity.endsAt,day=s.world.day;
 check(ends-h.now===2*CITY_HOUR_MS,'Two-hour shifts take thirty real minutes');
 check(s.citizen.credits===100&&s.citizen.taxDebt===0&&s.citizen.shifts===0,'No early wages, XP, or tax');
 await reject(()=>h.start('worker',{action:'crime',id:'steal'}),/busy/);
 await reject(()=>h.start('worker',{action:'career_claim',id:'mnemonic'}),/busy/);
 await h.start('worker',{action:'buy',id:'soup'});h.now=ends-1;s=await h.read('worker');check(s.citizen.credits===95&&s.citizen.activity,'Shopping works during an assignment and cannot reveal pay early');
 h.now=ends;const reads=await Promise.all([h.read('worker'),h.read('worker'),h.read('worker')]);
 check(reads.every(s=>s.citizen.credits===103&&s.citizen.shifts===1),'Concurrent completion reads grant rewards once');
 check(reads.every(s=>s.citizen.careers.mnemonic.xp===4&&!s.citizen.activity),'Career settlement is durable and idempotent');
 check(reads.every(s=>s.log.filter(l=>l.body.startsWith('Completed regular shift')).length===1),'Concurrent completion journals the result exactly once');
 s=await h.read('worker');check(s.world.day===day,'Working cannot fast-forward the server');
 check(s.cityLife.metrics.output===2,'Completed work contributes to shared production');
 await h.patch('worker',{energy:100,fullness:100,warmth:100});for(let i=0;i<3;i++)await h.action('worker',{action:'work',id:'sorting'});
 s=await h.read('worker');check(s.citizen.labor.hours===8,'Work hours are recorded across assignments');
 await reject(()=>h.start('worker',{action:'work',id:'cleaning'}),/permit/);
 check(s.jobs.every(j=>j.quotes[0].blocked),'Quotes expose the exhausted daily permit');
 h.now+=CITY_DAY_MS;await h.patch('worker',{energy:100,health:100,taxDebt:0,taxHold:false});s=await h.start('worker',{action:'work',id:'cleaning'});check(s.citizen.labor.hours===1,'Permit resets only with shared city day');
}
{
 const h=harness();await h.fixture('taxpayer',{credits:100,energy:100,fullness:100,warmth:100});
 await h.action('taxpayer',{action:'work',id:'sorting'});let s=await h.action('taxpayer',{action:'work',id:'sorting'});
 check(s.citizen.taxDebt===1&&s.citizen.taxRemainder===92&&s.citizen.taxEarned===16,'Twelve-percent tax carries fractions across wages');
 check(s.citizen.credits===116,'Tax is owed rather than silently withheld');
 h.now=s.citizen.taxDeadline;s=await h.read('taxpayer');check(s.citizen.taxHold&&s.idFlags.some(f=>f.id==='tax'),'Overdue tax flags the ID');
 await reject(()=>h.start('taxpayer',{action:'work',id:'sorting'}),/flagged/);
 await reject(()=>h.start('taxpayer',{action:'event_work',id:'output'}),/cleared/);
 await reject(()=>h.start('taxpayer',{action:'clearance'}),/tax debt/);
 s=await h.start('taxpayer',{action:'tax'});check(s.citizen.taxDebt===0&&s.citizen.taxHold&&s.citizen.taxPaid===1,'Paying the debt retains the administrative hold');
 await reject(()=>h.start('taxpayer',{action:'work',id:'salvage'}),/flagged/);
 await h.patch('taxpayer',{energy:100});const credits=(await h.read('taxpayer')).citizen.credits;s=await h.start('taxpayer',{action:'clearance'});
 check(s.citizen.taxHold&&s.citizen.credits===credits-2&&s.citizen.activity.hours===1,'Registry review reserves fee and keeps the gate closed while waiting');
 s=await h.finish('taxpayer');check(!s.citizen.taxHold&&s.idFlags.length===0,'Completed review clears the flag');
 s=await h.start('taxpayer',{action:'work',id:'sorting'});check(s.citizen.activity.action==='work','Cleared ID opens factory entry');
 await h.fixture('indigent',{credits:0,energy:100,taxHold:true,taxDebt:0});s=await h.start('indigent',{action:'clearance'});check(s.citizen.activity.hours===2&&s.citizen.energy<87,'Indigence appeal substitutes time and energy for fee');await h.finish('indigent');
 const ledger={taxEarned:0,taxDebt:0,taxRemainder:0};for(let i=0;i<100;i++)accrueTax(ledger,1);check(ledger.taxDebt===12&&ledger.taxRemainder===0,'Fractional taxes cannot be bypassed by splitting payments');
}
{
 const h=harness();await h.fixture('shopper',{credits:100,energy:100,fullness:100,warmth:100,bread:1});await h.fixture('buyer',{credits:100});
 await h.action('shopper',{action:'list',id:'bread',price:10});const listing=(await h.read('shopper')).listings[0];
 await h.start('shopper',{action:'work',id:'sorting'});await h.start('buyer',{action:'trade',id:listing.id});let s=await h.finish('shopper');
 check(s.citizen.credits===118,'Incoming trade payment survives shift completion');
 check(s.citizen.taxDebt===2&&s.citizen.taxRemainder===16&&s.citizen.taxEarned===18,'Trade plus wages accrue one combined tax ledger');
 await h.fixture('poor',{credits:0,health:10,energy:0,fullness:0,warmth:0});s=await h.start('poor',{action:'relief'});check(s.citizen.health>=25&&s.citizen.energy>=20&&s.citizen.fullness===24,'Emergency relief makes an exhausted broke citizen playable');
 check(s.citizen.credits===0&&s.citizen.bread===0,'Relief is not sellable income');await reject(()=>h.start('poor',{action:'relief'}),/One emergency/);
}
{
 const h=harness();await h.fixture('runner',{credits:0,energy:100,health:100,fullness:100,warmth:100});
 const original=crypto.getRandomValues.bind(crypto);crypto.getRandomValues=a=>{a.fill(0xffffffff);return a;};
 try{let s=await h.action('runner',{action:'crime',id:'smuggle'});check(s.citizen.credits===24&&s.citizen.taxDebt===0&&s.citizen.taxEarned===0,'Unreported criminal income offers a tax-free alternative');check(s.citizen.criminal.xp===6&&s.citizen.criminal.successes===1&&s.citizen.alignment===-3,'Crime builds underground standing and Chaos alignment');for(let i=0;i<2;i++){await h.patch('runner',{energy:100});await h.action('runner',{action:'crime',id:'steal'});}await reject(()=>h.start('runner',{action:'crime',id:'steal'}),/Three criminal/);s=await h.read('runner');check(s.cityLife.events.some(e=>e.id==='raids'),'Criminal operations cause a shared lockdown');}finally{crypto.getRandomValues=original;}
 await h.fixture('caught',{credits:30,energy:100,health:100,fullness:100,warmth:100});crypto.getRandomValues=a=>{a.fill(0);return a;};
 try{let s=await h.action('caught',{action:'crime',id:'steal'});check(s.citizen.credits===23&&s.citizen.criminalHold&&s.citizen.detainedUntil>h.now,'Arrest takes a fine, marks ID, and imposes real detention');await reject(()=>h.start('caught',{action:'work',id:'sorting'}),/sentence/);await reject(()=>h.start('caught',{action:'clearance'}),/sentence/);h.now=s.citizen.detainedUntil;s=await h.read('caught');check(s.citizen.criminalHold,'Serving detention does not erase the arrest hold');await reject(()=>h.start('caught',{action:'work',id:'sorting'}),/flagged/);s=await h.action('caught',{action:'clearance'});check(!s.citizen.criminalHold,'Administrative review restores access after a served sentence');}finally{crypto.getRandomValues=original;}
}
{
 const h=harness();await h.fixture('organizer',{union:true,energy:100,health:100,fullness:100,warmth:100});await h.fixture('observer');
 for(let i=0;i<3;i++){await h.patch('organizer',{energy:100});await h.action('organizer',{action:'organize'});}
 let s=await h.read('observer');check(s.cityLife.events.some(e=>e.id==='strike')&&s.world.wageModifier===2,'Collective organizing changes everyone’s wages');
 const before=s.jobs.find(j=>j.id==='sorting').quotes[0].pay;
 check(before===10,'Published wages include the city contract');
 await h.fixture('boiler',{energy:100,scrap:2,fullness:100,warmth:100});await h.action('boiler',{action:'event_work',id:'relief'});await h.action('boiler',{action:'event_work',id:'relief'});s=await h.read('observer');check(s.cityLife.metrics.relief===4&&s.world.coldModifier===-1,'Boiler crews improve district cold exposure');
 await h.fixture('freight',{energy:100,fullness:100,warmth:100});await h.start('freight',{action:'event_work',id:'freight'});const finishAt=(await h.read('freight')).citizen.activity.endsAt;h.now=finishAt;
 s=await h.read('observer');check(s.cityLife.metrics.freight===3&&s.cityLife.events.some(e=>e.id==='arrival'),'A player’s freight shift helps everybody without requiring that player to return');
 const stock=s.goods.find(g=>g.id==='bread').stock;for(let i=0;i<4;i++)await h.read('observer');check((await h.read('observer')).goods.find(g=>g.id==='bread').stock===stock,'Repeated reads do not duplicate delivered food');
 h.now+=CITY_DAY_MS;s=await h.read('observer');check(Object.values(s.cityLife.metrics).every(n=>n===0),'Daily district metrics reset on the common clock');
 const late=harness();late.now=Date.UTC(2026,9,5,3,30);await late.fixture('factory',{energy:100,fullness:100,warmth:100});s=await late.read('factory');check(s.cityLife.events.some(e=>e.id==='shortfall')&&s.cityLife.events.some(e=>e.id==='freight'),'Neglected production and freight cause city-wide shortages');
 check(s.goods.find(g=>g.id==='bread').price===5&&s.jobs.find(j=>j.id==='sorting').quotes[0].pay===7,'Neglect makes food expensive while cutting wages');
 for(let i=0;i<2;i++)await late.action('factory',{action:'event_work',id:'output'});s=await late.read('factory');check(s.cityLife.events.some(e=>e.id==='surplus')&&!s.cityLife.events.some(e=>e.id==='shortfall'),'Citizens can resolve production failure');
}
{
 const h=harness();await h.fixture('recruit',{credits:1000,rep:100,energy:100,health:100,fullness:100,warmth:100,alignment:100,shifts:100,careers:{mnemonic:{xp:0,shifts:0},civic:{xp:180,shifts:30},transit:{xp:0,shifts:0},recovery:{xp:0,shifts:0}}});
 await reject(()=>h.start('recruit',{action:'security'}),/7 days/);await reject(()=>h.start('recruit',{action:'official'}),/2 days/);await reject(()=>h.start('recruit',{action:'business'}),/1 day/);
 await h.patch('recruit',{joined:h.now-7*86400000,alignment:0});await reject(()=>h.start('recruit',{action:'security'}),/Order/);
 await h.patch('recruit',{alignment:40,taxHold:true});await reject(()=>h.start('recruit',{action:'security'}),/cleared/);
 await h.patch('recruit',{taxHold:false});let s=await h.start('recruit',{action:'security'});check(s.citizen.security&&s.citizen.role==='Canon security recruit','Long service, civic training, Order, and clean papers unlock security');
 s=await h.action('recruit',{action:'security_work'});check(s.cityLife.metrics.patrols===2&&s.citizen.credits===1020&&s.citizen.taxDebt===2,'Security duty contributes patrols and taxable pay');
 await h.fixture('legacy',{registered:undefined,credits:73,role:'Municipal official',official:true,coat:true,joined:h.now-3*86400000});s=await h.read('legacy');check(s.citizen.registered&&s.citizen.credits===73&&s.citizen.official&&s.citizen.coat&&s.citizen.daysInCity===3,'Existing characters keep possessions, institutions, and original residency age');
 check(h.db.sqlite.prepare('SELECT count(*) n FROM action_guards').get().n===0,'New civic actions leave no abandoned transaction guards');
}
console.log(`Passed ${checks} residency/economy checks: registration, shared time, income tax, gate holds, clearance, crime, relief, shared causality and late security progression.`);
