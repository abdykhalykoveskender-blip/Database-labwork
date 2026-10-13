CREATE DATABASE Lab5;

--1.1

CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

--1.2

CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

--1.3

CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

--1.4
INSERT INTO employees
VALUES
    (1, 'Ivan', 'Petrov', 25, 300000),
    (2, 'Anna', 'Smith', 40, 450000);

INSERT INTO employees
VALUES (3, 'Alex', 'Brown', 16, 200000);

INSERT INTO employees
VALUES (4, 'John', 'White', 70, 250000);

INSERT INTO employees
VALUES (5, 'Kate', 'Green', 30, 0);

INSERT INTO employees
VALUES (6, 'Mike', 'Black', 35, -1000);


INSERT INTO products_catalog
VALUES
    (1, 'Laptop', 500000, 450000),
    (2, 'Phone', 200000, 180000);

INSERT INTO products_catalog
VALUES (3, 'Tablet', 0, 0);

INSERT INTO products_catalog
VALUES (4, 'Monitor', 100000, 0);

INSERT INTO products_catalog
VALUES (5, 'Keyboard', 10000, 12000);


INSERT INTO bookings
VALUES
    (1, '2026-10-15', '2026-10-20', 2),
    (2, '2026-11-01', '2026-11-05', 8);

INSERT INTO bookings
VALUES (3, '2026-10-15', '2026-10-20', 0);

INSERT INTO bookings
VALUES (4, '2026-10-15', '2026-10-20', 12);

INSERT INTO bookings
VALUES (5, '2026-10-20', '2026-10-15', 3);

INSERT INTO bookings
VALUES (6, '2026-10-15', '2026-10-15', 2);

--2.1

CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

--2.2

CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

--2.3

INSERT INTO customers
VALUES
    (1, 'ivan@gmail.com', '87001234567', '2026-10-01'),
    (2, 'anna@gmail.com', '87007654321', '2026-10-05');

INSERT INTO customers
VALUES (NULL, 'alex@gmail.com', '87001112233', '2026-10-06');

INSERT INTO customers
VALUES (3, NULL, '87001112233', '2026-10-06');

INSERT INTO customers
VALUES (4, 'kate@gmail.com', '87004445566', NULL);

INSERT INTO customers
VALUES (5, 'mike@gmail.com', NULL, '2026-10-10');


INSERT INTO inventory
VALUES
    (1, 'Laptop', 10, 450000, '2026-10-13 10:00:00'),
    (2, 'Mouse', 25, 5000, '2026-10-13 11:00:00');

INSERT INTO inventory
VALUES (NULL, 'Keyboard', 10, 15000, CURRENT_TIMESTAMP);

INSERT INTO inventory
VALUES (3, NULL, 10, 15000, CURRENT_TIMESTAMP);

INSERT INTO inventory
VALUES (4, 'Monitor', NULL, 100000, CURRENT_TIMESTAMP);

INSERT INTO inventory
VALUES (5, 'Headphones', 5, NULL, CURRENT_TIMESTAMP);

INSERT INTO inventory
VALUES (6, 'Webcam', 7, 20000, NULL);

INSERT INTO inventory
VALUES (7, 'USB Cable', 0, 2000, CURRENT_TIMESTAMP);

INSERT INTO inventory
VALUES (8, 'Speaker', -3, 30000, CURRENT_TIMESTAMP);

INSERT INTO inventory
VALUES (9, 'Adapter', 5, 0, CURRENT_TIMESTAMP);

--3.1


CREATE TABLE users (
    user_id INTEGER,
    username TEXT,
    email TEXT,
    created_at TIMESTAMP,
    CONSTRAINT unique_username UNIQUE (username),
    CONSTRAINT unique_email UNIQUE (email)
);

--3.2

CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    UNIQUE (student_id, course_code, semester)
);
--3.3

INSERT INTO users
VALUES
    (1, 'ivan123', 'ivan@gmail.com', CURRENT_TIMESTAMP),
    (2, 'anna456', 'anna@gmail.com', CURRENT_TIMESTAMP);

INSERT INTO users
VALUES (3, 'ivan123', 'alex@gmail.com', CURRENT_TIMESTAMP);

INSERT INTO users
VALUES (4, 'alex789', 'ivan@gmail.com', CURRENT_TIMESTAMP);

INSERT INTO users
VALUES (5, 'mike555', 'mike@gmail.com', CURRENT_TIMESTAMP);


INSERT INTO course_enrollments
VALUES
    (1, 101, 'CS101', 'Fall 2026'),
    (2, 101, 'CS102', 'Fall 2026'),
    (3, 101, 'CS101', 'Spring 2027');

INSERT INTO course_enrollments
VALUES (4, 101, 'CS101', 'Fall 2026');

--4.1

CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments
VALUES
    (1, 'IT', 'Almaty'),
    (2, 'Finance', 'Astana'),
    (3, 'HR', 'Shymkent');

INSERT INTO departments
VALUES (1, 'Marketing', 'Aktau');

INSERT INTO departments
VALUES (NULL, 'Sales', 'Atyrau');

--4.2

CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

INSERT INTO student_courses
VALUES
    (101, 10, '2026-09-01', 'A'),
    (101, 20, '2026-09-02', 'B'),
    (102, 10, '2026-09-03', 'A');

INSERT INTO student_courses
VALUES (101, 10, '2026-09-05', 'C');

--5.1

CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

INSERT INTO employees_dept
VALUES
    (1, 'Ivan', 1, '2026-01-15'),
    (2, 'Anna', 2, '2026-02-10');

INSERT INTO employees_dept
VALUES (3, 'Alex', 99, '2026-03-01');

--5.2

CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

INSERT INTO authors
VALUES
    (1, 'J.K. Rowling', 'United Kingdom'),
    (2, 'George Orwell', 'United Kingdom'),
    (3, 'Abai Kunanbayev', 'Kazakhstan');

INSERT INTO publishers
VALUES
    (1, 'Bloomsbury', 'London'),
    (2, 'Penguin Books', 'London'),
    (3, 'Atamura', 'Almaty');

INSERT INTO books
VALUES
    (1, 'Harry Potter', 1, 1, 1997, '9780747532699'),
    (2, 'Animal Farm', 2, 2, 1945, '9780451526342'),
    (3, 'Words of Edification', 3, 3, 1890, '9786010000001');

SELECT * FROM authors;
SELECT * FROM publishers;
SELECT * FROM books;
--5.3

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id)
        ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id)
        ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

INSERT INTO categories
VALUES
    (1, 'Electronics'),
    (2, 'Books');

INSERT INTO products_fk
VALUES
    (1, 'Laptop', 1),
    (2, 'Keyboard', 1),
    (3, 'Novel', 2);

INSERT INTO orders
VALUES
    (101, '2026-10-01'),
    (102, '2026-10-05');

INSERT INTO order_items
VALUES
    (1, 101, 1, 1),
    (2, 101, 2, 2),
    (3, 102, 3, 1);


DELETE FROM categories
WHERE category_id = 1;

DELETE FROM orders
WHERE order_id = 101;

SELECT * FROM order_items;

--6.1

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL
        REFERENCES customers(customer_id) ON DELETE RESTRICT,
    order_date DATE NOT NULL,
    total_amount NUMERIC(10, 2) NOT NULL CHECK (total_amount >= 0),
    status TEXT NOT NULL CHECK (
        status IN (
            'pending',
            'processing',
            'shipped',
            'delivered',
            'cancelled'
        )
    )
);

CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL
        REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL
        REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0)
);


INSERT INTO customers
    (customer_id, name, email, phone, registration_date)
VALUES
    (1, 'Ivan Petrov', 'ivan@gmail.com', '87001111111', '2026-01-10'),
    (2, 'Anna Smith', 'anna@gmail.com', '87002222222', '2026-01-15'),
    (3, 'Alex Brown', 'alex@gmail.com', NULL, '2026-02-01'),
    (4, 'Maria Green', 'maria@gmail.com', '87004444444', '2026-02-12'),
    (5, 'John White', 'john@gmail.com', '87005555555', '2026-03-05');


INSERT INTO products
    (product_id, name, description, price, stock_quantity)
VALUES
    (1, 'Laptop', 'Laptop for work and study', 450000, 10),
    (2, 'Mouse', 'Wireless computer mouse', 8000, 50),
    (3, 'Keyboard', 'Mechanical keyboard', 25000, 30),
    (4, 'Monitor', '27-inch computer monitor', 120000, 15),
    (5, 'Headphones', 'Wireless headphones', 35000, 20);


INSERT INTO orders
    (order_id, customer_id, order_date, total_amount, status)
VALUES
    (101, 1, '2026-10-01', 466000, 'delivered'),
    (102, 2, '2026-10-02', 25000, 'shipped'),
    (103, 3, '2026-10-03', 120000, 'processing'),
    (104, 4, '2026-10-04', 35000, 'pending'),
    (105, 5, '2026-10-05', 16000, 'cancelled');


INSERT INTO order_details
    (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES
    (1, 101, 1, 1, 450000),
    (2, 101, 2, 2, 8000),
    (3, 102, 3, 1, 25000),
    (4, 103, 4, 1, 120000),
    (5, 104, 5, 1, 35000);


SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM order_details;


SELECT
    o.order_id,
    c.name AS customer_name,
    o.order_date,
    o.total_amount,
    o.status
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
ORDER BY o.order_id;


SELECT
    od.order_id,
    p.name AS product_name,
    od.quantity,
    od.unit_price,
    od.quantity * od.unit_price AS subtotal
FROM order_details od
JOIN products p
    ON od.product_id = p.product_id
ORDER BY od.order_id;


INSERT INTO customers
VALUES (6, 'Test User', 'ivan@gmail.com', NULL, '2026-10-10');


INSERT INTO products
VALUES (6, 'Bad Product', 'Invalid price', -100, 10);


INSERT INTO products
VALUES (7, 'Bad Stock', 'Invalid stock', 1000, -5);


INSERT INTO orders
VALUES (106, 999, '2026-10-10', 5000, 'pending');


INSERT INTO orders
VALUES (107, 1, '2026-10-10', 5000, 'returned');


INSERT INTO order_details
VALUES (6, 102, 2, 0, 8000);


INSERT INTO customers
VALUES (6, NULL, 'new@gmail.com', NULL, '2026-10-10');

DELETE FROM products
WHERE product_id = 1;

DELETE FROM orders
WHERE order_id = 101;

SELECT *
FROM order_details
WHERE order_id = 101;
