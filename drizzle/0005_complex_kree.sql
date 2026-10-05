CREATE TABLE `neural_messages` (
	`id` text PRIMARY KEY NOT NULL,
	`citizen` text NOT NULL,
	`channel` text NOT NULL,
	`body` text NOT NULL,
	`created` integer NOT NULL
);
--> statement-breakpoint
CREATE INDEX `idx_neural_channel_created` ON `neural_messages` (`channel`,`created`);--> statement-breakpoint
CREATE INDEX `idx_neural_citizen_created` ON `neural_messages` (`citizen`,`created`);