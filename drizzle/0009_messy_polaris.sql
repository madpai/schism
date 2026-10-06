CREATE TABLE `camp_production` (
	`id` text PRIMARY KEY NOT NULL,
	`citizen` text NOT NULL,
	`sentence` text NOT NULL,
	`goods` text NOT NULL,
	`quantity` integer NOT NULL,
	`completes` integer NOT NULL,
	CONSTRAINT "camp_quantity" CHECK("camp_production"."quantity" = 1)
);
--> statement-breakpoint
CREATE INDEX `idx_camp_production_completes` ON `camp_production` (`completes`);--> statement-breakpoint
CREATE TABLE `device_demand` (
	`id` text PRIMARY KEY NOT NULL,
	`remaining` integer NOT NULL,
	CONSTRAINT "device_demand_nonnegative" CHECK("device_demand"."remaining" >= 0)
);
--> statement-breakpoint
CREATE TABLE `device_offers` (
	`id` text PRIMARY KEY NOT NULL,
	`seller` text NOT NULL,
	`data` text NOT NULL,
	`price` integer NOT NULL,
	`status` integer DEFAULT 0 NOT NULL,
	`created` integer NOT NULL,
	CONSTRAINT "device_offer_price" CHECK("device_offers"."price" BETWEEN 1 AND 50)
);
--> statement-breakpoint
CREATE INDEX `idx_device_offers_status_created` ON `device_offers` (`status`,`created`);