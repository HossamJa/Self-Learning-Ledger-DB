/*
Query 1:
List all distinct skills demonstrated by projects
that were completed in the year 2025.
*/
SELECT DISTINCT s.id, s.name, p.name AS project_name
FROM skills s
JOIN project_skills ps ON s.id = ps.skill_id
JOIN projects p ON ps.project_id = p.id
WHERE p.status = 'completed'
  AND EXTRACT(YEAR FROM p.end_date) = 2025
ORDER BY s.name;

/*
Query 2:
Find skills that are taught in 3 or more courses.
*/
SELECT s.id, s.name, COUNT(cs.course_id) AS course_count
FROM skills s
JOIN course_skills cs ON s.id = cs.skill_id
GROUP BY s.id
HAVING COUNT(cs.course_id) >= 3
ORDER BY course_count DESC;

/*
Query 3:
Find skills that exist in the system
but are NOT linked to any project.
*/
SELECT s.id, s.name
FROM skills s
LEFT JOIN project_skills ps ON s.id = ps.skill_id
WHERE ps.project_id IS NULL
ORDER BY s.name;

/*
Query 4:
Calculate total learning hours associated with each roadmap,
based on courses teaching roadmap-targeted skills.
*/
SELECT r.id,
       r.name AS roadmap_name,
       SUM(c.hours) AS total_study_hours
FROM roadmaps r
JOIN roadmap_skills rs ON r.id = rs.roadmap_id
JOIN course_skills cs ON rs.skill_id = cs.skill_id
JOIN courses c ON cs.course_id = c.id
GROUP BY r.id
ORDER BY total_study_hours DESC;

/*
Query 5:
Display each certificate and how many skills it validates.
*/
SELECT c.id,
       c.title,
       COUNT(cs.skill_id) AS validated_skills_count
FROM certificates c
LEFT JOIN certificate_skills cs 
       ON c.id = cs.certificate_id
GROUP BY c.id
ORDER BY validated_skills_count DESC;

/*
Query 6:
Find the 5 skills most frequently demonstrated in projects.
*/
SELECT s.id,
       s.name,
       COUNT(ps.project_id) AS project_usage_count
FROM skills s
JOIN project_skills ps ON s.id = ps.skill_id
GROUP BY s.id
ORDER BY project_usage_count DESC
LIMIT 5;

/*
Query 7:
Calculate a weighted portfolio strength score per skill.
Weight:
• Each project = 3 points
• Each certificate = 2 points
• Each course = 1 point
*/
SELECT s.id,
       s.name,
       (
           COUNT(DISTINCT ps.project_id) * 3 +
           COUNT(DISTINCT certs.certificate_id) * 2 +
           COUNT(DISTINCT cs.course_id) * 1
       ) AS strength_score
FROM skills s
LEFT JOIN project_skills ps ON s.id = ps.skill_id
LEFT JOIN certificate_skills certs ON s.id = certs.skill_id
LEFT JOIN course_skills cs ON s.id = cs.skill_id
GROUP BY s.id
ORDER BY strength_score DESC;

/*
Query 8:
Insert a new skill into the system.
*/
INSERT INTO skills (name, category, description, level)
VALUES ('Quantum Computing Basics', 'Computer Science', 'Introductory skill in quantum computing', 1);

/*
Query 9:
Update the level of a skill after mastering it in multiple projects.
*/
UPDATE skills
SET level = 4
WHERE name = 'Python Programming';

/*
Query 10:
Delete a skill that is not linked to any course, project, or certificate.
*/
DELETE FROM skills s
WHERE NOT EXISTS (
    SELECT 1 FROM course_skills cs WHERE cs.skill_id = s.id
) AND NOT EXISTS (
    SELECT 1 FROM project_skills ps WHERE ps.skill_id = s.id
) AND NOT EXISTS (
    SELECT 1 FROM certificate_skills c_s WHERE c_s.skill_id = s.id
);

/*
Query 11:
Retrieve all courses under a specialization with their skills.
*/
SELECT sp.title AS specialization, c.title AS course, s.name AS skill
FROM specializations sp
JOIN specialization_courses sc ON sp.id = sc.specialization_id
JOIN courses c ON sc.course_id = c.id
JOIN course_skills cs ON c.id = cs.course_id
JOIN skills s ON cs.skill_id = s.id
ORDER BY sp.title, c.title;

/*
Query 12:
Mark a course as completed if its end_date has passed.
*/
UPDATE courses
SET completed = TRUE
WHERE end_date <= CURRENT_DATE
  AND completed = FALSE;
