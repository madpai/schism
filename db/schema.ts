import { sqliteTable, text, integer, index, uniqueIndex, check } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';
export const citizens = sqliteTable('citizens', {
  id: text('id').primaryKey(), owner: text('owner').notNull().unique(), name: text('name').notNull(),
  data: text('data').notNull(), version: integer('version').notNull().default(0),
  lastAction: integer('last_action').notNull().default(0), updated: integer('updated').notNull(),
});
export const market = sqliteTable('market', {
  id: text('id').primaryKey(), stock: integer('stock').notNull(), day: integer('day').notNull(),
  delivered: integer('delivered').notNull().default(0),
}, t => [check('market_stock_nonnegative', sql`${t.stock} >= 0`)]);
export const journal = sqliteTable('journal', {
  id: text('id').primaryKey(), citizen: text('citizen').notNull(), body: text('body').notNull(), created: integer('created').notNull(),
}, t => [index('idx_journal_citizen_created').on(t.citizen, t.created)]);
export const posts = sqliteTable('posts', {
  id: text('id').primaryKey(), citizen: text('citizen').notNull(), body: text('body').notNull(), created: integer('created').notNull(),
}, t => [index('idx_posts_created').on(t.created)]);
export const listings = sqliteTable('listings', {
  id: text('id').primaryKey(), seller: text('seller').notNull(), item: text('item').notNull(),
  price: integer('price').notNull(), sold: integer('sold').notNull().default(0), created: integer('created').notNull(),
}, t => [index('idx_listings_sold_created').on(t.sold, t.created)]);
export const guards = sqliteTable('action_guards', {
  id: text('id').primaryKey(), valid: integer('valid').notNull(),
}, t => [check('guard_valid', sql`${t.valid} = 1`)]);
export const projects = sqliteTable('projects', {
  id: text('id').primaryKey(), day: integer('day').notNull(), progress: integer('progress').notNull().default(0),
}, t => [check('project_progress_bounds', sql`${t.progress} >= 0 AND ${t.progress} <= 12`)]);
export const forces = sqliteTable('forces', {
  id: text('id').primaryKey(), day: integer('day').notNull(), balance: integer('balance').notNull().default(0),
  interventions: integer('interventions').notNull().default(0),
}, t => [check('force_balance_bounds', sql`${t.balance} >= -100 AND ${t.balance} <= 100`)]);
export const cityActivity = sqliteTable('city_activity', {
  id:text('id').primaryKey(), citizen:text('citizen').notNull(), day:integer('day').notNull(), completes:integer('completes').notNull(),
  output:integer('output').notNull().default(0), freight:integer('freight').notNull().default(0), crime:integer('crime').notNull().default(0),
  unrest:integer('unrest').notNull().default(0), relief:integer('relief').notNull().default(0), patrols:integer('patrols').notNull().default(0),
},t=>[index('idx_city_activity_day_completes').on(t.day,t.completes)]);
export const maintenanceRuns = sqliteTable('maintenance_runs', {
  id:text('id').primaryKey(), completed:integer('completed').notNull(), citizens:integer('citizens').notNull(),
});

export const neuralMessages = sqliteTable('neural_messages', {
  id:text('id').primaryKey(), citizen:text('citizen').notNull(), channel:text('channel').notNull(), body:text('body').notNull(), created:integer('created').notNull(),
},t=>[index('idx_neural_channel_created').on(t.channel,t.created),index('idx_neural_citizen_created').on(t.citizen,t.created)]);

export const supplyOrders = sqliteTable('supply_orders', {
 id:text('id').primaryKey(), buyer:text('buyer'), item:text('item').notNull(), price:integer('price').notNull(), remaining:integer('remaining').notNull(), quantity:integer('quantity').notNull(), status:integer('status').notNull().default(0), day:integer('day').notNull(), created:integer('created').notNull(),
},t=>[index('idx_supply_orders_status_created').on(t.status,t.created),index('idx_supply_orders_buyer_status').on(t.buyer,t.status),check('supply_order_bounds',sql`${t.remaining} >= 0 AND ${t.remaining} <= ${t.quantity} AND ${t.price} >= 1 AND ${t.price} <= 50 AND ${t.quantity} >= 1 AND ${t.quantity} <= 10 AND ${t.status} IN (0,1,2)`)]);
export const districtCrises = sqliteTable('district_crises', {
 id:text('id').primaryKey(), day:integer('day').notNull(), type:text('type').notNull(), started:integer('started').notNull(), deadline:integer('deadline').notNull(), target:integer('target').notNull(), outcome:text('outcome'), repair:integer('repair').notNull().default(0), diversion:integer('diversion').notNull().default(0),
},t=>[index('idx_district_crises_day').on(t.day),index('idx_district_crises_deadline').on(t.deadline)]);
export const crisisActions = sqliteTable('crisis_actions', {
 id:text('id').primaryKey(), crisis:text('crisis').notNull(), citizen:text('citizen').notNull(), completes:integer('completes').notNull(), repair:integer('repair').notNull().default(0), diversion:integer('diversion').notNull().default(0),
},t=>[index('idx_crisis_actions_completion').on(t.crisis,t.completes),check('crisis_units_nonnegative',sql`${t.repair} >= 0 AND ${t.diversion} >= 0`)]);

export const tenantBlocks = sqliteTable('tenant_blocks', {
 id:text('id').primaryKey(),name:text('name').notNull(),founder:text('founder').notNull().unique(),stock:text('stock').notNull().default('{}'),progress:integer('progress').notNull().default(0),round:integer('round').notNull().default(1),heatUntil:integer('heat_until').notNull().default(0),version:integer('version').notNull().default(0),created:integer('created').notNull(),
},t=>[check('tenant_progress_bounds',sql`${t.progress} >= 0 AND ${t.progress} <= 6`)]);
export const tenantMembers = sqliteTable('tenant_members', {
 citizen:text('citizen').primaryKey(),block:text('block').notNull(),joined:integer('joined').notNull(),
},t=>[index('idx_tenant_members_block').on(t.block)]);
export const tenantMessages = sqliteTable('tenant_messages', {
 id:text('id').primaryKey(),block:text('block').notNull(),citizen:text('citizen').notNull(),body:text('body').notNull(),created:integer('created').notNull(),
},t=>[index('idx_tenant_messages_block_created').on(t.block,t.created),index('idx_tenant_messages_citizen_created').on(t.citizen,t.created)]);
export const tenantTransfers = sqliteTable('tenant_transfers', {
 id:text('id').primaryKey(),block:text('block').notNull(),citizen:text('citizen').notNull(),item:text('item').notNull(),quantity:integer('quantity').notNull(),kind:text('kind').notNull(),created:integer('created').notNull(),
},t=>[index('idx_tenant_transfers_block_created').on(t.block,t.created),check('tenant_transfer_bounds',sql`${t.quantity} >= 1 AND ${t.quantity} <= 5`)]);
export const tenantRepairs = sqliteTable('tenant_repairs', {
 id:text('id').primaryKey(),block:text('block').notNull(),citizen:text('citizen').notNull(),round:integer('round').notNull(),completes:integer('completes').notNull(),
},t=>[index('idx_tenant_repairs_completion').on(t.block,t.round,t.completes)]);
export const recoveryActions = sqliteTable('recovery_actions', {
 id:text('id').primaryKey(),crisis:text('crisis').notNull(),citizen:text('citizen').notNull(),completes:integer('completes').notNull(),
},t=>[index('idx_recovery_actions_completion').on(t.crisis,t.completes)]);
export const districtNews = sqliteTable('district_news', {
 id:text('id').primaryKey(),day:integer('day').notNull(),headline:text('headline').notNull(),body:text('body').notNull(),data:text('data').notNull(),published:integer('published').notNull(),
},t=>[index('idx_district_news_published').on(t.published)]);

export const stairEvents=sqliteTable('stair_events',{
 id:text('id').primaryKey(),citizen:text('citizen').notNull().unique(),block:text('block'),route:text('route').notNull(),method:text('method').notNull(),completes:integer('completes').notNull(),
},t=>[index('idx_stair_events_completion').on(t.completes)]);
export const tenantRequests=sqliteTable('tenant_requests',{
 id:text('id').primaryKey(),block:text('block').notNull(),citizen:text('citizen').notNull(),item:text('item').notNull(),quantity:integer('quantity').notNull(),remaining:integer('remaining').notNull(),purpose:text('purpose').notNull(),created:integer('created').notNull(),
},t=>[index('idx_tenant_requests_block').on(t.block,t.remaining),check('tenant_request_bounds',sql`${t.remaining} >= 0 AND ${t.remaining} <= ${t.quantity} AND ${t.quantity} BETWEEN 1 AND 5`)]);
export const communityReports=sqliteTable('community_reports',{
 id:text('id').primaryKey(),reporter:text('reporter').notNull(),source:text('source').notNull(),message:text('message').notNull(),author:text('author'),body:text('body').notNull(),reason:text('reason').notNull(),status:text('status').notNull().default('open'),resolution:text('resolution'),moderator:text('moderator'),created:integer('created').notNull(),resolved:integer('resolved'),
},t=>[uniqueIndex('idx_reports_unique').on(t.reporter,t.source,t.message),index('idx_reports_status_created').on(t.status,t.created)]);
export const communityHidden=sqliteTable('community_hidden',{
 source:text('source').notNull(),message:text('message').notNull(),moderator:text('moderator').notNull(),created:integer('created').notNull(),
},t=>[uniqueIndex('idx_hidden_source_message').on(t.source,t.message)]);
export const communityMutes=sqliteTable('community_mutes',{
 citizen:text('citizen').primaryKey(),until:integer('until').notNull(),moderator:text('moderator').notNull(),created:integer('created').notNull(),
});
export const requestWindows=sqliteTable('request_windows',{
 owner:text('owner').notNull(),kind:text('kind').notNull(),window:integer('window').notNull(),count:integer('count').notNull(),
},t=>[uniqueIndex('idx_request_window').on(t.owner,t.kind)]);
