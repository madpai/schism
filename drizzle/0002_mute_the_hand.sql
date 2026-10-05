CREATE TABLE `forces` (
	`id` text PRIMARY KEY NOT NULL,
	`day` integer NOT NULL,
	`balance` integer DEFAULT 0 NOT NULL,
	`interventions` integer DEFAULT 0 NOT NULL,
	CONSTRAINT "force_balance_bounds" CHECK("forces"."balance" >= -100 AND "forces"."balance" <= 100)
);
