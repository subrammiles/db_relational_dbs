-- =====================================================================
-- Sample data. Run after schema.sql.
-- The data is small on purpose so you can check every result by eye,
-- but it contains the "awkward" cases interviewers like to ask about:
--   * an employee with no department          (Tom Wilson, dept_id NULL)
--   * a department with no employees          (Research)
--   * an employee with no email               (Tom Wilson)
--   * duplicate salaries                      (95000 twice, 70000 twice)
--   * customers who never ordered             (Omar Hassan, Sara Lee)
--   * a product that was never ordered        (Desk Lamp)
--   * a customer with no email                (Emma Brown)
--   * cancelled and pending orders
-- =====================================================================

INSERT INTO departments (dept_id, dept_name, location) VALUES
    (1, 'Engineering', 'Bangalore'),
    (2, 'Sales',       'Mumbai'),
    (3, 'HR',          'Delhi'),
    (4, 'Finance',     'Chennai'),
    (5, 'Marketing',   'Bangalore'),
    (6, 'Research',    'Hyderabad');

-- Managers must be inserted before the people who report to them
-- (manager_id is a foreign key to the same table).
INSERT INTO employees (emp_id, first_name, last_name, email, dept_id, manager_id, job_title, salary, hire_date) VALUES
    ( 1, 'Asha',    'Rao',    'asha.rao@corp.com',      1, NULL, 'Chief Executive',     250000, '2015-01-10'),
    ( 2, 'Vikram',  'Singh',  'vikram.singh@corp.com',  1,    1, 'Engineering Manager', 180000, '2016-03-15'),
    ( 3, 'Priya',   'Nair',   'priya.nair@corp.com',    1,    2, 'Senior Engineer',     140000, '2017-07-01'),
    ( 4, 'Rahul',   'Mehta',  'rahul.mehta@corp.com',   1,    2, 'Engineer',             95000, '2020-02-20'),
    ( 5, 'Sneha',   'Iyer',   'sneha.iyer@corp.com',    1,    2, 'Engineer',             95000, '2021-06-11'),
    ( 6, 'Arjun',   'Das',    'arjun.das@corp.com',     1,    3, 'Junior Engineer',      60000, '2023-09-04'),
    ( 7, 'Meera',   'Kapoor', 'meera.kapoor@corp.com',  2,    1, 'Sales Manager',       150000, '2016-11-30'),
    ( 8, 'Karan',   'Joshi',  'karan.joshi@corp.com',   2,    7, 'Sales Executive',      70000, '2019-05-18'),
    ( 9, 'Divya',   'Menon',  'divya.menon@corp.com',   2,    7, 'Sales Executive',      72000, '2022-01-03'),
    (10, 'Rohan',   'Gupta',  'rohan.gupta@corp.com',   2,    7, 'Sales Executive',      70000, '2024-04-22'),
    (11, 'Anita',   'Sharma', 'anita.sharma@corp.com',  3,    1, 'HR Manager',          110000, '2018-08-08'),
    (12, 'Farhan',  'Ali',    'farhan.ali@corp.com',    3,   11, 'Recruiter',            55000, '2022-10-10'),
    (13, 'Lakshmi', 'Pillai', 'lakshmi.pillai@corp.com',4,    1, 'Finance Manager',     130000, '2017-02-14'),
    (14, 'Suresh',  'Kumar',  'suresh.kumar@corp.com',  4,   13, 'Accountant',           65000, '2021-12-01'),
    (15, 'Neha',    'Verma',  'neha.verma@corp.com',    5,    1, 'Marketing Lead',       90000, '2020-07-07'),
    (16, 'Tom',     'Wilson', NULL,                     NULL, 1, 'Consultant',           80000, '2025-01-15');

INSERT INTO customers (customer_id, name, email, city, country, signup_date) VALUES
    ( 1, 'Aarav Shah',   'aarav@mail.com', 'Mumbai',    'India',   '2024-01-05'),
    ( 2, 'Isha Patel',   'isha@mail.com',  'Ahmedabad', 'India',   '2024-02-11'),
    ( 3, 'John Smith',   'john@mail.com',  'London',    'UK',      '2024-03-20'),
    ( 4, 'Maria Garcia', 'maria@mail.com', 'Madrid',    'Spain',   '2024-04-02'),
    ( 5, 'Chen Wei',     'chen@mail.com',  'Shanghai',  'China',   '2024-05-15'),
    ( 6, 'Emma Brown',   NULL,             'London',    'UK',      '2024-06-30'),
    ( 7, 'Ravi Kumar',   'ravi@mail.com',  'Bangalore', 'India',   '2024-08-19'),
    ( 8, 'Lena Fischer', 'lena@mail.com',  'Berlin',    'Germany', '2025-01-10'),
    ( 9, 'Omar Hassan',  'omar@mail.com',  'Dubai',     'UAE',     '2025-03-03'),
    (10, 'Sara Lee',     'sara@mail.com',  'Mumbai',    'India',   '2025-06-21');

INSERT INTO products (product_id, product_name, category, price, stock) VALUES
    ( 1, 'Laptop Pro 14',       'Electronics', 85000,  25),
    ( 2, 'Wireless Mouse',      'Electronics',   800, 200),
    ( 3, 'Mechanical Keyboard', 'Electronics',  4500,  80),
    ( 4, '27in Monitor',        'Electronics', 18000,  40),
    ( 5, 'Office Chair',        'Furniture',   12000,  30),
    ( 6, 'Standing Desk',       'Furniture',   28000,  10),
    ( 7, 'Notebook Pack',       'Stationery',    250, 500),
    ( 8, 'Gel Pen Set',         'Stationery',    150, 800),
    ( 9, 'USB-C Hub',           'Electronics',  2500, 120),
    (10, 'Desk Lamp',           'Furniture',    1800,   0);

INSERT INTO orders (order_id, customer_id, order_date, status) VALUES
    ( 1, 1, '2025-01-10', 'delivered'),
    ( 2, 1, '2025-02-14', 'delivered'),
    ( 3, 2, '2025-02-20', 'delivered'),
    ( 4, 3, '2025-03-05', 'delivered'),
    ( 5, 4, '2025-03-18', 'cancelled'),
    ( 6, 5, '2025-04-01', 'delivered'),
    ( 7, 1, '2025-04-22', 'delivered'),
    ( 8, 6, '2025-05-09', 'delivered'),
    ( 9, 7, '2025-06-15', 'shipped'),
    (10, 3, '2025-07-01', 'delivered'),
    (11, 2, '2025-08-12', 'delivered'),
    (12, 8, '2025-09-03', 'delivered'),
    (13, 5, '2025-10-20', 'shipped'),
    (14, 7, '2025-11-11', 'delivered'),
    (15, 1, '2025-12-24', 'pending'),
    (16, 4, '2026-01-08', 'delivered'),
    (17, 3, '2026-02-14', 'pending'),
    (18, 6, '2026-03-01', 'cancelled');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    ( 1, 1,  1, 85000), ( 1, 2,  1,   800),
    ( 2, 7, 10,   250),
    ( 3, 5,  2, 12000), ( 3, 8,  5,   150),
    ( 4, 4,  2, 18000), ( 4, 3,  1,  4500),
    ( 5, 6,  1, 28000),
    ( 6, 1,  2, 82000),                       -- bulk discount
    ( 7, 9,  3,  2500), ( 7, 2,  2,   800),
    ( 8, 3,  1,  4500),
    ( 9, 1,  1, 85000), ( 9, 4,  1, 18000),
    (10, 7, 20,   250), (10, 8, 10,   150),
    (11, 6,  1, 28000), (11, 5,  1, 12000),
    (12, 2,  4,   800),
    (13, 9,  1,  2500),
    (14, 4,  1, 17500),                       -- discounted
    (15, 3,  2,  4500),
    (16, 1,  1, 85000),
    (17, 8, 20,   150),
    (18, 5,  1, 12000);

INSERT INTO accounts (account_id, owner_name, balance) VALUES
    (1, 'Alice', 5000),
    (2, 'Bob',   2000),
    (3, 'Carol',    0);
