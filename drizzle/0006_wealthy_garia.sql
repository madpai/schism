CREATE TABLE `crisis_actions` (
	`id` text PRIMARY KEY NOT NULL,
	`crisis` text NOT NULL,
	`citizen` text NOT NULL,
	`completes` integer NOT NULL,
	`repair` integer DEFAULT 0 NOT NULL,
	`diversion` integer DEFAULT 0 NOT NULL,
	CONSTRAINT "crisis_units_nonnegative" CHECK("crisis_actions"."repair" >= 0 AND "crisis_actions"."diversion" >= 0)
);
--> statement-breakpoint
CREATE INDEX `idx_crisis_actions_completion` ON `crisis_actions` (`crisis`,`completes`);--> statement-breakpoint
CREATE TABLE `district_crises` (
	`id` text PRIMARY KEY NOT NULL,
	`day` integer NOT NULL,
	`type` text NOT NULL,
	`started` integer NOT NULL,
	`deadline` integer NOT NULL,
	`target` integer NOT NULL,
	`outcome` text,
	`repair` integer DEFAULT 0 NOT NULL,
	`diversion` integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE INDEX `idx_district_crises_day` ON `district_crises` (`day`);--> statement-breakpoint
CREATE INDEX `idx_district_crises_deadline` ON `district_crises` (`deadline`);--> statement-breakpoint
CREATE TABLE `supply_orders` (
	`id` text PRIMARY KEY NOT NULL,
	`buyer` text,
	`item` text NOT NULL,
	`price` integer NOT NULL,
	`remaining` integer NOT NULL,
	`quantity` integer NOT NULL,
	`status` integer DEFAULT 0 NOT NULL,
	`day` integer NOT NULL,
	`created` integer NOT NULL,
	CONSTRAINT "supply_order_bounds" CHECK("supply_orders"."remaining" >= 0 AND "supply_orders"."remaining" <= "supply_orders"."quantity" AND "supply_orders"."price" >= 1 AND "supply_orders"."price" <= 50 AND "supply_orders"."quantity" >= 1 AND "supply_orders"."quantity" <= 10 AND "supply_orders"."status" IN (0,1,2))
);
--> statement-breakpoint
CREATE INDEX `idx_supply_orders_status_created` ON `supply_orders` (`status`,`created`);--> statement-breakpoint
CREATE INDEX `idx_supply_orders_buyer_status` ON `supply_orders` (`buyer`,`status`);