-- =====================================
-- CORE TABLES (No Dependencies)
-- =====================================

COPY skills(name, category, description, level)
FROM '/data/skills.csv'
DELIMITER ','
CSV HEADER;

COPY courses(title, provider, hours, start_date, end_date, completed, url)
FROM '/data/courses.csv'
DELIMITER ','
CSV HEADER;

COPY specializations(title, provider, description, url, start_date, end_date)
FROM '/data/specializations.csv'
DELIMITER ','
CSV HEADER;

COPY roadmaps(name, domain, start_date, end_date, description, status)
FROM '/data/roadmaps.csv'
DELIMITER ','
CSV HEADER;

-- =====================================
-- DEPENDENT CORE TABLES
-- =====================================

COPY certificates(title, provider, description, issue_date, credential_url, course_id, specialization_id)
FROM '/data/certificates.csv'
DELIMITER ','
CSV HEADER;

COPY projects(name, description, github_url, start_date, end_date, status, course_id, specialization_id)
FROM '/data/projects.csv'
DELIMITER ','
CSV HEADER;

-- =====================================
-- RELATIONSHIP TABLES
-- =====================================

COPY course_skills(skill_id, course_id)
FROM '/data/course_skills.csv'
DELIMITER ','
CSV HEADER;

COPY certificate_skills(skill_id, certificate_id)
FROM '/data/certificate_skills.csv'
DELIMITER ','
CSV HEADER;

COPY project_skills(skill_id, project_id)
FROM '/data/project_skills.csv'
DELIMITER ','
CSV HEADER;

COPY specialization_courses(course_id, specialization_id)
FROM '/data/specialization_courses.csv'
DELIMITER ','
CSV HEADER;

COPY roadmap_learning_units(roadmap_id, course_id, specialization_id)
FROM '/data/roadmap_learning_units.csv'
DELIMITER ','
CSV HEADER;
