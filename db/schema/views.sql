
-- #3- Views

/*
0. roadmap_skills view
    Derive roadmap skills dynamically:
    - Roadmap contains a specialization → which contains courses 
    - Roadmap contains a course → which contain skills
*/

CREATE OR REPLACE VIEW "roadmap_skills" AS

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
CREATE OR REPLACE VIEW "skill_coverage" AS
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
CREATE OR REPLACE VIEW "total_learning_hours" AS
SELECT SUM("hours") AS "total_hours"
FROM "courses";

/*
3. roadmap_progress view
    Shows % of roadmap skills demonstrated in projects
*/

CREATE OR REPLACE VIEW "roadmap_progress" AS 
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
CREATE OR REPLACE VIEW "portfolio_summary" AS 
SELECT 
    (SELECT COUNT(*) FROM "skills") AS "total_skills",
    (SELECT COUNT(*) FROM "projects") AS "total_projects",
    (SELECT COUNT(*) FROM "certificates") AS "total_certificates",
    (SELECT COUNT(*) FROM "courses") AS "total_courses";