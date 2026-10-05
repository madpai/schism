CREATE TABLE `projects` (
	`id` text PRIMARY KEY NOT NULL,
	`day` integer NOT NULL,
	`progress` integer DEFAULT 0 NOT NULL,
	CONSTRAINT "project_progress_bounds" CHECK("projects"."progress" >= 0 AND "projects"."progress" <= 12)
);
