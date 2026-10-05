CREATE TABLE `city_activity` (
	`id` text PRIMARY KEY NOT NULL,
	`citizen` text NOT NULL,
	`day` integer NOT NULL,
	`completes` integer NOT NULL,
	`output` integer DEFAULT 0 NOT NULL,
	`freight` integer DEFAULT 0 NOT NULL,
	`crime` integer DEFAULT 0 NOT NULL,
	`unrest` integer DEFAULT 0 NOT NULL,
	`relief` integer DEFAULT 0 NOT NULL,
	`patrols` integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE INDEX `idx_city_activity_day_completes` ON `city_activity` (`day`,`completes`);--> statement-breakpoint
ALTER TABLE `market` ADD `delivered` integer DEFAULT 0 NOT NULL;