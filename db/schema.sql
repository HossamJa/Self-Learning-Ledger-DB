-- #1- Core Entities (Tables)

-- 1. skills: Stores canonical skills.
CREATE TABLE "skills" (
    "id" SERIAL,
    "name" VARCHAR(54) NOT NULL UNIQUE,
    "category" VARCHAR(32),
    "description" VARCHAR(128),
    "level" SMALLINT DEFAULT 1 CHECK (level BETWEEN 1 AND 5),
    PRIMARY KEY("id")
);

-- 2. courses: Individual courses taken.
CREATE TABLE "courses" (
    "id" SERIAL,
    "title" VARCHAR(64) NOT NULL,
    "provider" VARCHAR(32) NOT NULL,
    "hours" INT,
    "start_date" DATE,
    "end_date" DATE,
    "completed" BOOLEAN DEFAULT FALSE,
    "url" TEXT,
    PRIMARY KEY("id"),
    CHECK ("end_date" IS NULL OR "end_date" >= "start_date")
);

-- 3. specializations (Grouped courses)
CREATE TABLE "specializations" (
    "id" SERIAL,
    "title" VARCHAR(74) NOT NULL,
    "provider" VARCHAR(32) NOT NULL,
    "description" TEXT,
	"url" TEXT,
	"start_date" DATE,
	"end_date" DATE,
    PRIMARY KEY("id"),
	CHECK ("end_date" IS NULL OR "end_date" >= "start_date")
);

-- 4. certificates: Formal certificates. 
-- 	A cert can belong to a course, specialization, or an exam.
CREATE TABLE "certificates" (
    "id" SERIAL,
    "title" VARCHAR(64) NOT NULL,
	"provider" VARCHAR(32) NOT NULL,
	"description" TEXT,	
    "issue_date" DATE,
    "credential_url" TEXT,
	"course_id" INT REFERENCES "courses"("id") ON DELETE CASCADE,
	"specialization_id" INT REFERENCES "specializations"("id") ON DELETE CASCADE,
    CONSTRAINT "certificate_owner_check"
	CHECK (
		("course_id" IS NOT NULL AND "specialization_id" IS NULL)
		OR
		("course_id" IS NULL AND "specialization_id" IS NOT NULL)
	),
	PRIMARY KEY("id")
);

-- 5. projects: Projects built.
CREATE TABLE "projects" (
    "id" SERIAL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "github_url" TEXT,
    "start_date" DATE,
    "end_date" DATE,
    "status" VARCHAR(20) CHECK (status IN ('planned', 'in_progress', 'completed')),
    "course_id" INT REFERENCES "courses"("id") ON DELETE CASCADE,
	"specialization_id" INT REFERENCES "specializations"("id") ON DELETE CASCADE,
	PRIMARY KEY("id"),
    CHECK ("end_date" IS NULL OR "end_date" >= "start_date")
);

-- 6. roadmaps: Learning plans.
CREATE TABLE "roadmaps" (
    "id" SERIAL,
    "name" VARCHAR(64) NOT NULL,
    "domain" VARCHAR(24),
    "start_date" DATE,
    "end_date" DATE,
    "description" TEXT,
    "status" VARCHAR(20),
    PRIMARY KEY("id"),
    CHECK ("end_date" IS NULL OR "end_date" >= "start_date")
);

-- #2- Relationship Tables

/*
1. course_skills
    A course teaches many skills.
    A skill can be taught by many courses.
*/
CREATE TABLE "course_skills" (
    "skill_id" INT REFERENCES "skills"("id") ON DELETE CASCADE,
    "course_id" INT REFERENCES "courses"("id") ON DELETE CASCADE,
    PRIMARY KEY ("skill_id", "course_id")
);

/*
2. certificate_skills
    A certificate validates many skills.
*/
CREATE TABLE "certificate_skills" (
    "skill_id" INT REFERENCES "skills"("id") ON DELETE CASCADE,
    "certificate_id" INT REFERENCES "certificates"("id") ON DELETE CASCADE,
    PRIMARY KEY("skill_id", "certificate_id")
);

/*
3. project_skills
    A project demonstrates many skills.
*/
CREATE TABLE "project_skills" (
    "skill_id" INT REFERENCES "skills"("id") ON DELETE CASCADE,
    "project_id" INT REFERENCES "projects"("id") ON DELETE CASCADE,
    PRIMARY KEY("skill_id", "project_id")
);

/*
4. specialization_courses
    Which courses belong to a specialization.
	One course may belong to multiple specializations
*/
CREATE TABLE "specialization_courses" (
    "course_id" INT REFERENCES "courses"("id") ON DELETE CASCADE,
    "specialization_id" INT REFERENCES "specializations"("id") ON DELETE CASCADE,
    PRIMARY KEY("course_id","specialization_id")
);

/*
5. roadmap_learning_units
    Defines which learning units (courses or specializations)
    are included in each roadmap.
    
    A roadmap may include multiple courses and/or specializations.
    Each row represents exactly one learning unit inside a roadmap.
*/

CREATE TABLE "roadmap_learning_units" (
    "id" SERIAL,
    "roadmap_id" INT NOT NULL REFERENCES "roadmaps"("id") ON DELETE CASCADE,
    "course_id" INT REFERENCES "courses"("id") ON DELETE CASCADE,
    "specialization_id" INT REFERENCES "specializations"("id") ON DELETE CASCADE,
    CHECK (
        ("course_id" IS NOT NULL AND "specialization_id" IS NULL)
        OR
        ("course_id" IS NULL AND "specialization_id" IS NOT NULL)
    ),
	PRIMARY KEY("id")
);

-- #3- Views

/*
0. roadmap_skills view
    Derive roadmap skills dynamically:
    - Roadmap contains a specialization → which contains courses 
    - Roadmap contains a course → which contain skills
*/

CREATE VIEW "roadmap_skills" AS

-- Skills from direct courses in roadmap
SELECT
    "roadmap_learning_units"."roadmap_id",
    "course_skills"."skill_id"
FROM "roadmap_learning_units"
JOIN "course_skills"
    ON "roadmap_learning_units"."course_id" = "course_skills"."course_id"
WHERE "roadmap_learning_units"."course_id" IS NOT NULL

UNION

-- Skills from specializations in roadmap
SELECT
    "roadmap_learning_units"."roadmap_id",
    "course_skills"."skill_id"
FROM "roadmap_learning_units"
JOIN "specialization_courses"
    ON "roadmap_learning_units"."specialization_id" = "specialization_courses"."specialization_id"
JOIN "course_skills"
    ON "specialization_courses"."course_id" = "course_skills"."course_id"
WHERE "roadmap_learning_units"."specialization_id" IS NOT NULL;


/*
1. skill_coverage view
    Shows how many sources validate each skill.
*/
CREATE VIEW "skill_coverage" AS
SELECT
    "skills"."id",
    "skills"."name",
    COUNT(DISTINCT "course_skills"."course_id") AS "courses_count",
    COUNT(DISTINCT "project_skills"."project_id") AS "projects_count",
    COUNT(DISTINCT "certificate_skills"."certificate_id") AS "certificates_count"
FROM "skills"
LEFT JOIN "course_skills" ON "skills"."id" = "course_skills"."skill_id"
LEFT JOIN "project_skills" ON "skills"."id" = "project_skills"."skill_id"
LEFT JOIN "certificate_skills" ON "skills"."id" = "certificate_skills"."skill_id"
GROUP BY "skills"."id";

/*
2. total_learning_hours view
*/
CREATE VIEW "total_learning_hours" AS
SELECT SUM("hours") AS "total_hours"
FROM "courses";

/*
3. roadmap_progress view
    Shows % of roadmap skills demonstrated in projects
*/

CREATE VIEW "roadmap_progress" AS 
SELECT 
    "roadmaps"."id" AS "roadmap_id",
    "roadmaps"."name" AS "roadmap_name",
    COUNT(DISTINCT "project_skills"."skill_id") AS "demonstrated_skills",
    COUNT(DISTINCT "roadmap_skills"."skill_id") AS "total_roadmap_skills",
    CASE
        WHEN COUNT(DISTINCT "roadmap_skills"."skill_id") = 0 THEN 0
        ELSE ROUND(
            COUNT(DISTINCT "project_skills"."skill_id")::decimal
            / COUNT(DISTINCT "roadmap_skills"."skill_id") * 100, 2
        )
    END AS "progress_percentage"
FROM "roadmaps"
LEFT JOIN "roadmap_skills" ON "roadmaps"."id" = "roadmap_skills"."roadmap_id"
LEFT JOIN "project_skills" ON "roadmap_skills"."skill_id" = "project_skills"."skill_id"
GROUP BY "roadmaps"."id";

/*
4. portfolio_summary view
Shows:
    * total skills
    * total projects
    * total certificates
    * total courses
*/
CREATE VIEW "portfolio_summary" AS 
SELECT 
    (SELECT COUNT(*) FROM "skills") AS "total_skills",
    (SELECT COUNT(*) FROM "projects") AS "total_projects",
    (SELECT COUNT(*) FROM "certificates") AS "total_certificates",
    (SELECT COUNT(*) FROM "courses") AS "total_courses";

-- #4- Triggers

/*
1. Auto-update skill level trigger
When a skill appears in:
   * 3+ courses
   * 2+ projects
Automatically increase its level.
*/

-- Create Function
CREATE OR REPLACE FUNCTION "update_skill_level"()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE skills
    SET level = (
        SELECT 
            CASE
                WHEN 
                    (SELECT COUNT(*) FROM "course_skills" 
                     WHERE "skill_id" = NEW."skill_id") >= 3
                 AND
                    (SELECT COUNT(*) FROM "project_skills" 
                     WHERE "skill_id" = NEW."skill_id") >= 2
                THEN 5

                WHEN 
                    (SELECT COUNT(*) FROM "project_skills" 
                     WHERE "skill_id" = NEW."skill_id") >= 2
                THEN 4

                WHEN 
                    (SELECT COUNT(*) FROM "course_skills" 
                     WHERE "skill_id" = NEW."skill_id") >= 3
                THEN 3

                ELSE 1
            END
    )
    WHERE id = NEW."skill_id";

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create Trigger
CREATE TRIGGER "skill_level_trigger"
AFTER INSERT ON "course_skills"
FOR EACH ROW
EXECUTE FUNCTION "update_skill_level"();

CREATE TRIGGER "skill_level_trigger_projects"
AFTER INSERT ON "project_skills"
FOR EACH ROW
EXECUTE FUNCTION "update_skill_level"();


/*
2. Prevent deleting core skills
Trigger that prevents deletion if:
    * Skill is used in a certificate
*/

-- Create Trigger
CREATE OR REPLACE FUNCTION "prevent_skill_delete"()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM "certificate_skills"
        WHERE "skill_id" = OLD.id
    ) THEN
        RAISE EXCEPTION 
        'Cannot delete skill. It is linked to a certificate.';
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create Trigger
CREATE TRIGGER "prevent_deleting_core_skills"
BEFORE DELETE ON "skills"
FOR EACH ROW
EXECUTE FUNCTION "prevent_skill_delete"();


/*
3. Automatically mark course as completed
*/

-- Create Function
CREATE OR REPLACE FUNCTION "auto_mark_completed"()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW."end_date" IS NOT NULL THEN
        NEW."completed" := TRUE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create Trigger
CREATE TRIGGER "mark_course_as_completed"
BEFORE UPDATE ON "courses"
FOR EACH ROW
EXECUTE FUNCTION "auto_mark_completed"();


-- #5- Indexes
CREATE INDEX "idx_course_skills_skill" ON "course_skills"("skill_id");
CREATE INDEX "idx_project_skills_skill" ON "project_skills"("skill_id");
CREATE INDEX "idx_certificate_skills_skill" ON "certificate_skills"("skill_id");
CREATE INDEX "idx_courses_completed" ON "courses"("completed");
CREATE INDEX "idx_projects_status" ON "projects"("status");
CREATE INDEX "idx_roadmaps_status" ON "roadmaps"("status");
