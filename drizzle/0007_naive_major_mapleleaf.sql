CREATE TABLE `district_news` (
	`id` text PRIMARY KEY NOT NULL,
	`day` integer NOT NULL,
	`headline` text NOT NULL,
	`body` text NOT NULL,
	`data` text NOT NULL,
	`published` integer NOT NULL
);
--> statement-breakpoint
CREATE INDEX `idx_district_news_published` ON `district_news` (`published`);--> statement-breakpoint
CREATE TABLE `recovery_actions` (
	`id` text PRIMARY KEY NOT NULL,
	`crisis` text NOT NULL,
	`citizen` text NOT NULL,
	`completes` integer NOT NULL
);
--> statement-breakpoint
CREATE INDEX `idx_recovery_actions_completion` ON `recovery_actions` (`crisis`,`completes`);--> statement-breakpoint
CREATE TABLE `tenant_blocks` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`founder` text NOT NULL,
	`stock` text DEFAULT '{}' NOT NULL,
	`progress` integer DEFAULT 0 NOT NULL,
	`round` integer DEFAULT 1 NOT NULL,
	`heat_until` integer DEFAULT 0 NOT NULL,
	`version` integer DEFAULT 0 NOT NULL,
	`created` integer NOT NULL,
	CONSTRAINT "tenant_progress_bounds" CHECK("tenant_blocks"."progress" >= 0 AND "tenant_blocks"."progress" <= 6)
);
--> statement-breakpoint
CREATE UNIQUE INDEX `tenant_blocks_founder_unique` ON `tenant_blocks` (`founder`);--> statement-breakpoint
CREATE TABLE `tenant_members` (
	`citizen` text PRIMARY KEY NOT NULL,
	`block` text NOT NULL,
	`joined` integer NOT NULL
);
--> statement-breakpoint
CREATE INDEX `idx_tenant_members_block` ON `tenant_members` (`block`);--> statement-breakpoint
CREATE TABLE `tenant_messages` (
	`id` text PRIMARY KEY NOT NULL,
	`block` text NOT NULL,
	`citizen` text NOT NULL,
	`body` text NOT NULL,
	`created` integer NOT NULL
);
--> statement-breakpoint
CREATE INDEX `idx_tenant_messages_block_created` ON `tenant_messages` (`block`,`created`);--> statement-breakpoint
CREATE INDEX `idx_tenant_messages_citizen_created` ON `tenant_messages` (`citizen`,`created`);--> statement-breakpoint
CREATE TABLE `tenant_repairs` (
	`id` text PRIMARY KEY NOT NULL,
	`block` text NOT NULL,
	`citizen` text NOT NULL,
	`round` integer NOT NULL,
	`completes` integer NOT NULL
);
--> statement-breakpoint
CREATE INDEX `idx_tenant_repairs_completion` ON `tenant_repairs` (`block`,`round`,`completes`);--> statement-breakpoint
CREATE TABLE `tenant_transfers` (
	`id` text PRIMARY KEY NOT NULL,
	`block` text NOT NULL,
	`citizen` text NOT NULL,
	`item` text NOT NULL,
	`quantity` integer NOT NULL,
	`kind` text NOT NULL,
	`created` integer NOT NULL,
	CONSTRAINT "tenant_transfer_bounds" CHECK("tenant_transfers"."quantity" >= 1 AND "tenant_transfers"."quantity" <= 5)
);
--> statement-breakpoint
CREATE INDEX `idx_tenant_transfers_block_created` ON `tenant_transfers` (`block`,`created`);