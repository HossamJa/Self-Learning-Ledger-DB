
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

DROP TRIGGER IF EXISTS skill_level_trigger ON course_skills;

-- #5- Indexes
CREATE INDEX "idx_course_skills_skill" ON "course_skills"("skill_id");
CREATE INDEX "idx_project_skills_skill" ON "project_skills"("skill_id");
CREATE INDEX "idx_certificate_skills_skill" ON "certificate_skills"("skill_id");
CREATE INDEX "idx_courses_completed" ON "courses"("completed");
CREATE INDEX "idx_projects_status" ON "projects"("status");
CREATE INDEX "idx_roadmaps_status" ON "roadmaps"("status");
