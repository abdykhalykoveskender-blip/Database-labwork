-- ---------- Part 1: Setup ----------
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id INT,
    salary DECIMAL(10,2),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
CREATE TABLE projects (
    proj_id INT PRIMARY KEY,
    proj_name VARCHAR(100),
    budget DECIMAL(12,2),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

INSERT INTO departments VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');

INSERT INTO employees VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000);

INSERT INTO projects VALUES
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102);
-- 2.1
CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'employees';
-- Answer: 2 indexes: employees_pkey (created automatically by the PRIMARY KEY) and emp_salary_idx.

-- 2.2
CREATE INDEX emp_dept_idx ON employees(dept_id);

SELECT * FROM employees WHERE dept_id = 101;
-- Answer: Indexing foreign key columns speeds up JOINs on that column, filtering by it, and the FK checks performed when parent rows are updated or deleted.

-- 2.3
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
-- Answer: departments_pkey, employees_pkey, projects_pkey were created automatically (PRIMARY KEY). emp_salary_idx and emp_dept_idx were created manually.
-- 3.1
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

SELECT emp_name, salary FROM employees WHERE dept_id = 101 AND salary > 52000;
-- Answer: Not really useful for a query filtering only by salary. The index is sorted by dept_id first (leftmost-prefix rule), so without a condition on dept_id it cannot be searched efficiently by salary alone.

-- 3.2
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

-- Query 1
SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
-- Query 2
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;
-- Answer: The column order in the INDEX matters; the order of conditions in WHERE does not (both queries are equivalent). The first index column decides which queries the index can serve efficiently: (dept_id, salary) suits equality on dept_id plus a range on salary; (salary, dept_id) suits filtering mainly by salary.
-- 4.1
ALTER TABLE employees ADD COLUMN email VARCHAR(100);
UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

-- This should fail with a unique violation error
INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
-- Error: duplicate key value violates unique constraint "emp_email_unique_idx"
-- DETAIL: Key (email)=(john.smith@company.com) already exists.

-- 4.2
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';
-- Answer: Yes. PostgreSQL automatically created a unique B-tree index (employees_phone_key) to enforce the UNIQUE constraint.

-- 5.1
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name, salary FROM employees ORDER BY salary DESC;
-- Answer: The index already stores salaries in descending order, so PostgreSQL can read rows in that order directly and skip a separate sort step.

-- 5.2
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT proj_name, budget FROM projects ORDER BY budget NULLS FIRST;

-- 6.1
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';
-- Answer: Without the index PostgreSQL does a sequential scan and computes LOWER(emp_name) for every row in the table.

-- 6.2
ALTER TABLE employees ADD COLUMN hire_date DATE;
UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date FROM employees WHERE EXTRACT(YEAR FROM hire_date) = 2020;

-- 7.1
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

-- 7.2
DROP INDEX emp_salary_dept_idx;
-- Answer: A redundant or unused index wastes disk space and slows down INSERT, UPDATE and DELETE, because it must be maintained on every change.

-- 7.3
REINDEX INDEX employees_salary_index;
-- Answer: REINDEX is useful after bulk inserts, when an index becomes bloated after many updates/deletes, or when an index is corrupted.

-- ---------- Part 8: Practical Scenarios ----------
-- 8.1
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

-- Index for the WHERE clause
CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;
-- Index for the JOIN: emp_dept_idx (already created)
-- Index for ORDER BY: emp_salary_desc_idx (already created)

-- 8.2
CREATE INDEX proj_high_budget_idx ON projects(budget) WHERE budget > 80000;

SELECT proj_name, budget FROM projects WHERE budget > 80000;
-- Answer: A partial index is smaller, faster to scan and cheaper to maintain, because it contains entries only for the rows that match its condition.

-- 8.3
EXPLAIN SELECT * FROM employees WHERE salary > 52000;
-- Answer: On such a tiny table the output is usually "Seq Scan". The planner estimates that reading the whole table is cheaper than using the index. On large tables with a selective condition it would choose an Index Scan (or Bitmap Index Scan).

-- 9.1
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

SELECT * FROM departments WHERE dept_name = 'IT';
-- Answer: Use HASH only when you need pure equality (=) lookups. For ranges, sorting and everything else use B-tree, which is also the default and more versatile.

-- 9.2
CREATE INDEX proj_name_btree_idx ON projects(proj_name);
CREATE INDEX proj_name_hash_idx ON projects USING HASH (proj_name);

-- Equality search (both can be used)
SELECT * FROM projects WHERE proj_name = 'Website Redesign';
-- Range search (only B-tree can be used)
SELECT * FROM projects WHERE proj_name > 'Database';

-- 10.1
SELECT schemaname, tablename, indexname,
       pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
-- Answer: With so little data most indexes are about the same size (one or two pages). Larger ones are typically multicolumn or text-column indexes (e.g. on proj_name or (dept_id, salary)) because their keys are wider, and hash indexes with a fixed minimum structure. Check your own output to name the exact largest one.

-- 10.2
DROP INDEX IF EXISTS proj_name_hash_idx;

-- 10.3
CREATE VIEW index_documentation AS
SELECT tablename, indexname, indexdef,
       'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE '%salary%';

SELECT * FROM index_documentation;

-- ---------- Summary Questions ----------
-- 1. What is the default index type in PostgreSQL?
--    B-tree.
-- 2. Name three scenarios where you should create an index:
--    (a) columns frequently used in WHERE conditions;
--    (b) foreign key columns and columns used in JOIN conditions;
--    (c) columns used in ORDER BY, or that must be unique.
-- 3. Name two scenarios where you should NOT create an index:
--    (a) very small tables (a sequential scan is already fast);
--    (b) columns with low selectivity (e.g. boolean) or tables with very frequent writes
--        and rare reads.
-- 4. What happens to indexes when you INSERT, UPDATE, or DELETE data?
--    The indexes are updated automatically along with the table, which makes writes slower.
-- 5. How can you check if a query is using an index?
--    Run EXPLAIN (or EXPLAIN ANALYZE) and look for Index Scan, Index Only Scan or
--    Bitmap Index Scan instead of Seq Scan.

-- ---------- Additional Challenges ----------
-- 1. Index for finding employees hired in a specific month
CREATE INDEX emp_hire_month_idx ON employees(EXTRACT(MONTH FROM hire_date));
SELECT emp_name, hire_date FROM employees WHERE EXTRACT(MONTH FROM hire_date) = 6;

-- 2. Composite unique index on dept_id and email
CREATE UNIQUE INDEX emp_dept_email_unique_idx ON employees(dept_id, email);

-- 3. EXPLAIN ANALYZE with and without indexes
EXPLAIN ANALYZE SELECT * FROM employees WHERE salary > 52000;
SET enable_seqscan = off;
EXPLAIN ANALYZE SELECT * FROM employees WHERE salary > 52000;
RESET enable_seqscan;

-- 4. Covering index
CREATE INDEX emp_covering_idx ON employees(dept_id) INCLUDE (emp_name, salary);
EXPLAIN SELECT emp_name, salary FROM employees WHERE dept_id = 101;

-- ---------- Reflection ----------
-- Indexes should be created on columns that are frequently used in WHERE, JOIN and ORDER BY
-- clauses of queries on large tables. They speed up reads but slow down writes and use disk
-- space, so not every column should be indexed and unused indexes should be dropped.
-- EXPLAIN should be used to verify that an index is actually being used.