# CS50 SQL Final Project – Self-Learning Ledger

## Project Overview

This project implements a **Self-Learning Ledger**, a database system to track skills, courses, specializations, certificates, projects, and learning roadmaps. It is designed to:

* Store and manage **skills**, **courses**, **specializations**, **certificates**, **projects**, and **learning roadmaps**.
* Track which skills are taught in courses, demonstrated in projects, or validated by certificates.
* Monitor **portfolio progress**, **skill coverage**, and total learning hours using pre-defined **views**.
* Automatically update skill levels and manage course completion using **triggers**.

The project is built entirely with **PostgreSQL** and automated using **Docker**.

---

## Demo Video
[![Watch the Demo Video](https://img.youtube.com/vi/L-BXBjZc3SU/maxresdefault.jpg)](https://youtu.be/L-BXBjZc3SU)


## Project Structure

```
CS50-SQL-and-Databases/
│
├─ docker-compose.yml
├─ Dockerfile
├─ README.md
├─ queries.sql                # Annotated set of common SQL queries
├─ 01-schema.sql              # Database schema (tables, views, triggers, indexes)
├─ 02-init-data.sql           # ETL scripts for loading data from CSV
└─ data/
    ├─ skills.csv
    ├─ courses.csv
    ├─ specializations.csv
    ├─ certificates.csv
    ├─ projects.csv
    ├─ course_skills.csv
    ├─ project_skills.csv
    ├─ certificate_skills.csv
    ├─ specialization_courses.csv
    └─ roadmap_learning_units.csv
```

---

## Step 1 – Schema Design

The database schema was carefully designed with the following core entities:

1. **skills** – Canonical skills tracked across learning activities.
2. **courses** – Individual courses, with completion status and learning hours.
3. **specializations** – Collections of courses.
4. **certificates** – Formal achievements tied to courses or specializations.
5. **projects** – Demonstrated skills through hands-on work.
6. **roadmaps** – Learning plans that group courses and specializations.

Relationship tables were created to handle **many-to-many relationships**:

* `course_skills`, `certificate_skills`, `project_skills`
* `specialization_courses`, `roadmap_learning_units`

**Constraints and Triggers**:

* Ensured data integrity using **foreign keys** and **CHECK constraints**.
* Automatically update skill levels based on project/course participation.
* Prevent deletion of core skills linked to certificates.
* Automatically mark courses as completed based on their end date.

**Views**:

* `roadmap_skills` – Aggregates skills for each roadmap.
* `skill_coverage` – Shows how well skills are represented across courses/projects/certificates.
* `total_learning_hours` – Calculates total learning hours.
* `roadmap_progress` – Shows skill completion percentage in roadmaps.
* `portfolio_summary` – Summary of total skills, projects, certificates, and courses.

---

## Step 2 – ETL: Collecting and Preparing Data

The project uses CSV files as the source for **initial data**.

**Steps:**

1. **Data Collection**:

   * Gathered information on courses, specializations, certificates, projects, and skills.
2. **Data Cleaning**:

   * Standardized column names and removed duplicates.
   * Ensured dates were consistent (`YYYY-MM-DD`) and valid.
3. **Organizing Data**:

   * Split data into separate CSVs corresponding to tables in the schema.
4. **Validation**:

   * Checked foreign key relationships before import.
   * Ensured that specializations referenced valid courses and roadmaps contained valid learning units.
5. **ETL Preparation**:

   * Prepared `02-init-data.sql` with `COPY` commands to load CSVs into the database.

---

## Step 3 – Docker Setup

The database is containerized with **Docker** for portability and reproducibility.

**Docker Steps**:

1. **Install Docker**:
   Follow [Docker installation guide](https://docs.docker.com/get-docker/).

2. **Pull PostgreSQL Image**:
   The Dockerfile automatically uses the PostgreSQL 18 image.

   ```bash
   docker pull postgres:18
   ```

3. **Docker Compose**:
   The `docker-compose.yml` file defines the database service:

   ```yaml
   services:
     selflearnledger-db:
       image: postgres:18
       container_name: selflearnledger-db
       environment:
         POSTGRES_USER: postgres
         POSTGRES_PASSWORD: password
         POSTGRES_DB: selflearnledger
       volumes:
         - ./data:/data
         - ./01-schema.sql:/docker-entrypoint-initdb.d/01-schema.sql
         - ./02-init-data.sql:/docker-entrypoint-initdb.d/02-init-data.sql
       ports:
         - "5432:5432"
   ```

4. **Dockerfile** (Optional Automation):

   * Automates installation of dependencies, copying SQL files, and initializing the database.

   ```dockerfile
   FROM postgres:18
   ENV POSTGRES_USER=postgres
   ENV POSTGRES_PASSWORD=password
   ENV POSTGRES_DB=selflearnledger
   COPY ./01-schema.sql /docker-entrypoint-initdb.d/
   COPY ./02-init-data.sql /docker-entrypoint-initdb.d/
   ```

---

## Step 4 – Loading Data

1. Start the database with Docker Compose:

   ```bash
   docker compose up
   ```
2. The database container will:

   * Initialize PostgreSQL.
   * Create tables, views, triggers, and indexes from `01-schema.sql`.
   * Load CSV data using `02-init-data.sql`.
3. Verify data load:

   ```bash
   docker exec -it selflearnledger-db psql -U postgres -d selflearnledger
   \dt   -- list tables
   SELECT COUNT(*) FROM skills; -- confirm data exists
   ```

---

## Step 5 – Using `queries.sql`

The `queries.sql` file demonstrates typical operations on the database:

* SELECT queries to retrieve skills, project contributions, roadmap progress, etc.
* INSERT, UPDATE, DELETE operations to manage skills.
* Advanced analytics queries using **views** for skill coverage and portfolio strength.

Run queries inside the container:

```bash
docker exec -it selflearnledger-db psql -U postgres -d selflearnledger -f queries.sql
```

---

## Step 6 – Summary of Technologies & Concepts

* **PostgreSQL** – Database engine
* **Docker** – Containerization for portability
* **SQL** – DDL, DML, Views, Aggregations
* **Triggers & Functions** – Automatic skill level updates and course completion
* **ETL Process** – Data collection, cleaning, transformation, and loading from CSV
* **CS50 Final Project Requirements** – Fully annotated queries demonstrating database usage

---

## Step 7 – Future Improvements

* Add **user authentication** and **activity tracking**.
* Implement a **web dashboard** to visualize roadmaps, skills, and portfolio progress.
* Expand **ETL pipelines** for automated updates from external sources (e.g., online course providers).

---

## Step 8 – References

* CS50 SQL & Databases Final Project Specification
* PostgreSQL Documentation: [https://www.postgresql.org/docs/](https://www.postgresql.org/docs/)
* Docker Documentation: [https://docs.docker.com/](https://docs.docker.com/)

---
