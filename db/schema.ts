import { sqliteTable, text, integer, index, check } from 'drizzle-orm/sqlite-core';
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
