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
