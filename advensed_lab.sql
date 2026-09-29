--A
CREATE DATABASE advansed_lab;
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(100),
    salary INTEGER,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100),
    budget INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id INTEGER,
    start_date DATE,
    end_date DATE,
    budget INTEGER,
    CONSTRAINT fk_project_department
        FOREIGN KEY (dept_id)
        REFERENCES departments(dept_id)
);
--B.2
INSERT INTO employees (
    emp_id,
    first_name,
    last_name,
    department
)
VALUES (
    1,
    'Ivan',
    'Petrov',
    'IT'
);
--B.3
INSERT INTO employees (
    first_name,
    last_name,
    department,
    salary,
    hire_date,
    status
)
VALUES (
    'Anna',
    'Sidorova',
    'HR',
    DEFAULT,
    '2026-09-29',
    DEFAULT
);
--B.4
INSERT INTO departments (
    dept_name,
    budget,
    manager_id
)
VALUES
('IT', 1000000, 1),
('HR', 500000, 2),
('Finance', 750000, 3);

INSERT INTO employees (
    first_name,
    last_name,
    department,
    salary,
    hire_date
)
--B.5
VALUES (
    'Alex',
    'Johnson',
    'IT',
    50000 * 1.1,
    CURRENT_DATE
);
--B.6
CREATE TEMP TABLE temp_employees (
    emp_id INTEGER,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(100),
    salary INTEGER,
    hire_date DATE,
    status VARCHAR(20)
);

INSERT INTO temp_employees
SELECT *
FROM employees
WHERE department = 'IT';

--C.7
UPDATE employees
SET salary = salary * 1.10;

--C.8
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';
--C.9
UPDATE employees
SET department =
    CASE
        WHEN salary > 80000 THEN 'Management'
        WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
        ELSE 'Junior'
    END;
--C.10
ALTER TABLE employees
ALTER COLUMN department
SET DEFAULT 'General';

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

--C.11
UPDATE departments d
SET budget =
(
    SELECT AVG(e.salary) * 1.20
    FROM employees e
    WHERE e.department = d.dept_name
);
--C.12
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';
--D.13
SELECT *
FROM employees
WHERE status = 'Terminated';

DELETE FROM employees
WHERE status = 'Terminated';

--D.14
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;
--D.15
DELETE FROM departments
WHERE dept_name NOT IN (
    SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL
);
--D.16
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;
--E.17
INSERT INTO employees (
    first_name,
    last_name,
    department,
    salary,
    hire_date
)
VALUES (
    'John',
    'Smith',
    NULL,
    NULL,
    CURRENT_DATE
);
--E.18
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;
--E.19
DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

--F.20
INSERT INTO employees (
    first_name,
    last_name,
    department,
    salary,
    hire_date
)
VALUES (
    'Michael',
    'Brown',
    'IT',
    60000,
    CURRENT_DATE
)
RETURNING
    emp_id,
    first_name || ' ' || last_name AS full_name;
--F.21
WITH old_data AS (
    SELECT emp_id, salary
    FROM employees
    WHERE department = 'IT'
)
UPDATE employees e
SET salary = salary + 5000
FROM old_data o
WHERE e.emp_id = o.emp_id
RETURNING
    e.emp_id,
    o.salary AS old_salary,
    e.salary AS new_salary;
--F.22
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

--G.23
INSERT INTO employees (
    first_name,
    last_name,
    department,
    salary,
    hire_date
)
SELECT
    'Ivan',
    'Petrov',
    'IT',
    60000,
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1
    FROM employees
    WHERE first_name = 'Ivan'
      AND last_name = 'Petrov'
);
--G.24
UPDATE employees e
SET salary =
    CASE
        WHEN (
            SELECT d.budget
            FROM departments d
            WHERE d.dept_name = e.department
        ) > 100000
        THEN salary * 1.10
        ELSE salary * 1.05
    END;
--G.25
INSERT INTO employees (
    first_name,
    last_name,
    department,
    salary,
    hire_date
)
VALUES
('John', 'Smith', 'IT', 50000, CURRENT_DATE),
('Anna', 'Brown', 'HR', 45000, CURRENT_DATE),
('Mike', 'Johnson', 'Sales', 55000, CURRENT_DATE),
('Kate', 'Wilson', 'IT', 60000, CURRENT_DATE),
('Tom', 'Davis', 'Finance', 65000, CURRENT_DATE);
--G.26
CREATE TABLE employee_archive (
    LIKE employees INCLUDING ALL
);
INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

SELECT * FROM employee_archive;
--G.27
UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE p.budget > 50000
  AND (
      SELECT COUNT(*)
      FROM employees e
      JOIN departments d
        ON e.department = d.dept_name
      WHERE d.dept_id = p.dept_id
  );