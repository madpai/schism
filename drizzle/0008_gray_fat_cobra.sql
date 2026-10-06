CREATE TABLE `community_hidden` (
	`source` text NOT NULL,
	`message` text NOT NULL,
	`moderator` text NOT NULL,
	`created` integer NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `idx_hidden_source_message` ON `community_hidden` (`source`,`message`);--> statement-breakpoint
CREATE TABLE `community_mutes` (
	`citizen` text PRIMARY KEY NOT NULL,
	`until` integer NOT NULL,
	`moderator` text NOT NULL,
	`created` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `community_reports` (
	`id` text PRIMARY KEY NOT NULL,
	`reporter` text NOT NULL,
	`source` text NOT NULL,
	`message` text NOT NULL,
	`author` text,
	`body` text NOT NULL,
	`reason` text NOT NULL,
	`status` text DEFAULT 'open' NOT NULL,
	`resolution` text,
	`moderator` text,
	`created` integer NOT NULL,
	`resolved` integer
);
--> statement-breakpoint
CREATE UNIQUE INDEX `idx_reports_unique` ON `community_reports` (`reporter`,`source`,`message`);--> statement-breakpoint
CREATE INDEX `idx_reports_status_created` ON `community_reports` (`status`,`created`);--> statement-breakpoint
CREATE TABLE `request_windows` (
	`owner` text NOT NULL,
	`kind` text NOT NULL,
	`window` integer NOT NULL,
	`count` integer NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `idx_request_window` ON `request_windows` (`owner`,`kind`);--> statement-breakpoint
CREATE TABLE `stair_events` (
	`id` text PRIMARY KEY NOT NULL,
	`citizen` text NOT NULL,
	`block` text,
	`route` text NOT NULL,
	`method` text NOT NULL,
	`completes` integer NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `stair_events_citizen_unique` ON `stair_events` (`citizen`);--> statement-breakpoint
CREATE INDEX `idx_stair_events_completion` ON `stair_events` (`completes`);--> statement-breakpoint
CREATE TABLE `tenant_requests` (
	`id` text PRIMARY KEY NOT NULL,
	`block` text NOT NULL,
	`citizen` text NOT NULL,
	`item` text NOT NULL,
	`quantity` integer NOT NULL,
	`remaining` integer NOT NULL,
	`purpose` text NOT NULL,
	`created` integer NOT NULL,
	CONSTRAINT "tenant_request_bounds" CHECK("tenant_requests"."remaining" >= 0 AND "tenant_requests"."remaining" <= "tenant_requests"."quantity" AND "tenant_requests"."quantity" BETWEEN 1 AND 5)
);
--> statement-breakpoint
CREATE INDEX `idx_tenant_requests_block` ON `tenant_requests` (`block`,`remaining`);