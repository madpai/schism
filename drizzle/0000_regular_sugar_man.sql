CREATE TABLE `citizens` (
	`id` text PRIMARY KEY NOT NULL,
	`owner` text NOT NULL,
	`name` text NOT NULL,
	`data` text NOT NULL,
	`version` integer DEFAULT 0 NOT NULL,
	`last_action` integer DEFAULT 0 NOT NULL,
	`updated` integer NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `citizens_owner_unique` ON `citizens` (`owner`);--> statement-breakpoint
CREATE TABLE `action_guards` (
	`id` text PRIMARY KEY NOT NULL,
	`valid` integer NOT NULL,
	CONSTRAINT "guard_valid" CHECK("action_guards"."valid" = 1)
);
--> statement-breakpoint
CREATE TABLE `journal` (
	`id` text PRIMARY KEY NOT NULL,
	`citizen` text NOT NULL,
	`body` text NOT NULL,
	`created` integer NOT NULL
);
--> statement-breakpoint
CREATE INDEX `idx_journal_citizen_created` ON `journal` (`citizen`,`created`);--> statement-breakpoint
CREATE TABLE `listings` (
	`id` text PRIMARY KEY NOT NULL,
	`seller` text NOT NULL,
	`item` text NOT NULL,
	`price` integer NOT NULL,
	`sold` integer DEFAULT 0 NOT NULL,
	`created` integer NOT NULL
);
--> statement-breakpoint
CREATE INDEX `idx_listings_sold_created` ON `listings` (`sold`,`created`);--> statement-breakpoint
CREATE TABLE `market` (
	`id` text PRIMARY KEY NOT NULL,
	`stock` integer NOT NULL,
	`day` integer NOT NULL,
	CONSTRAINT "market_stock_nonnegative" CHECK("market"."stock" >= 0)
);
--> statement-breakpoint
CREATE TABLE `posts` (
	`id` text PRIMARY KEY NOT NULL,
	`citizen` text NOT NULL,
	`body` text NOT NULL,
	`created` integer NOT NULL
);
--> statement-breakpoint
CREATE INDEX `idx_posts_created` ON `posts` (`created`);