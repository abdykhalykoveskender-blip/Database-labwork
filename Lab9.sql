--2.1
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT)
RETURNS INT AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT end_date - start_date
    INTO v_days
    FROM rentals
    WHERE rental_id = p_rental_id;

    RETURN v_days;
END;
$$ LANGUAGE plpgsql;

SELECT rental_days(2);    -- Expected: 5
SELECT rental_days(11);   -- Expected: 8
SELECT rental_days(19);   -- Expected: NULL
SELECT rental_days(999);  -- Expected: NULL

--2.2
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT)
RETURNS INT AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

SELECT member_rental_count(1);
SELECT member_rental_count(5);
SELECT member_rental_count(6);
SELECT member_rental_count(99);

--2.3
CREATE OR REPLACE FUNCTION station_city(p_station_id INT)
RETURNS VARCHAR AS $$
DECLARE
    v_city VARCHAR(40);
BEGIN
    SELECT city
    INTO v_city
    FROM stations
    WHERE station_id = p_station_id;

    RETURN v_city;
END;
$$ LANGUAGE plpgsql;

SELECT station_city(30);
SELECT station_city(77);

--2.4
SELECT rental_id, member_id, rental_days(rental_id) AS duration_days
FROM rentals
WHERE rental_days(rental_id) > 4
ORDER BY duration_days DESC;

-- 3.1
CREATE OR REPLACE FUNCTION fee_with_discount(
    p_fee NUMERIC,
    p_percent NUMERIC
)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(p_fee * (1 - p_percent / 100), 2);
END;
$$ LANGUAGE plpgsql;

SELECT fee_with_discount(74.00, 15);

--3.2
CREATE OR REPLACE FUNCTION member_stats(
    p_member_id INT,
    OUT rental_cnt INT,
    OUT total_fee NUMERIC,
    OUT last_start DATE
) AS $$
BEGIN
    SELECT COUNT(*)::INT,
           COALESCE(SUM(fee), 0),
           MAX(start_date)
    INTO rental_cnt, total_fee, last_start
    FROM rentals
    WHERE member_id = p_member_id;
END;
$$ LANGUAGE plpgsql;

SELECT member_stats(3);
SELECT * FROM member_stats(3);
SELECT * FROM member_stats(6);

-- 3.3:
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC) AS $$
BEGIN
    p_fee := p_fee + 5.00;
END;
$$ LANGUAGE plpgsql;

SELECT apply_late_fee(fee)
FROM rentals
WHERE rental_id = 1;

--3.4
CREATE OR REPLACE FUNCTION fee_summary(
    VARIADIC p_fees NUMERIC[],
    OUT total NUMERIC,
    OUT average NUMERIC,
    OUT largest NUMERIC
) AS $$
BEGIN
    SELECT COALESCE(SUM(p_fees[g.i]), 0),
           ROUND(AVG(p_fees[g.i]), 2),
           MAX(p_fees[g.i])
    INTO total, average, largest
    FROM generate_subscripts(p_fees, 1) AS g(i);
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50);
SELECT * FROM fee_summary();

--3.5
--a IN: the row id is supplied for lookup and is not changed.
--b INOUT: the caller supplies a balance and receives its updated value.
--c VARIADIC: it accepts a variable number of station ids in an array.
--d OUT: multiple statistics can be returned from one function call.

--4.1
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1);
SELECT total_fees(6);

-- 4.2
CREATE OR REPLACE FUNCTION total_fees(
    p_member_id INT,
    p_from_date DATE
)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1, DATE '2024-01-01');
SELECT total_fees(1, DATE '2025-01-01');

--4.3
CREATE OR REPLACE FUNCTION total_fees(
    p_member_id INT,
    p_from_date DATE DEFAULT DATE '2025-01-01'
)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION total_fees(INTEGER);
SELECT total_fees(1);

--4.5
CREATE OR REPLACE FUNCTION total_fees(p_member_name VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(r.fee), 0)
    INTO v_total
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    WHERE m.full_name = p_member_name;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees('Aisha Nurlanova');
SELECT total_fees(1);

-- 5.1
CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR)
RETURNS TABLE (
    found_id INT,
    found_model VARCHAR,
    found_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model::VARCHAR, b.daily_rate
    FROM bikes b
    WHERE b.model ILIKE p_pattern
    ORDER BY b.bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_bikes('%road%');
SELECT * FROM find_bikes('%Mini');

-- 5.2
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE (
    rental_id INT,
    bike_model VARCHAR,
    station_name VARCHAR,
    duration_days INT,
    fee NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT r.rental_id,
           b.model::VARCHAR,
           s.station_name::VARCHAR,
           (r.end_date - r.start_date)::INT,
           r.fee
    FROM rentals r
    JOIN bikes b ON b.bike_id = r.bike_id
    LEFT JOIN stations s ON s.station_id = b.station_id
    WHERE r.member_id = p_member_id
    ORDER BY r.start_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM member_history(3);
--5.3
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (
    result_bike_id INT,
    result_model VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model::VARCHAR
    FROM bikes b
    WHERE b.station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);
DROP FUNCTION bike_list(INT);

CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (
    bike_id INT,
    model VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model::VARCHAR
    FROM bikes AS b
    WHERE b.station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

--5.4
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (
    s_name VARCHAR,
    s_bikes INT,
    s_free INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name::VARCHAR,
           COUNT(b.bike_id)::INT,
           (s.capacity - COUNT(b.bike_id)::INT)::INT
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.city = p_city
    GROUP BY s.station_id, s.station_name, s.capacity
    ORDER BY s.station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM station_board('Almaty');
SELECT * FROM station_board('Astana');

-- 6.1
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*)::INT INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END rental_report;
$$;

-- 6.2
DO $$
<<rental_report>>
DECLARE
    fee_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO fee_total FROM rentals;
    RAISE NOTICE 'Outer total before subblock: %', fee_total;

    DECLARE
        fee_total NUMERIC;
    BEGIN
        SELECT COALESCE(SUM(fee), 0)
        INTO fee_total
        FROM rentals
        WHERE start_date >= DATE '2025-01-01';

        RAISE NOTICE 'Subblock total: %', fee_total;
        RAISE NOTICE 'Outer total from subblock: %', rental_report.fee_total;
    END;

    RAISE NOTICE 'Outer total after subblock: %', fee_total;
END rental_report;
$$;
--6.3
DO $$
DECLARE
    shared_value INT := 10;
BEGIN
    DECLARE
    BEGIN
        RAISE NOTICE 'First subblock sees: %', shared_value;
    END;

    DECLARE
    BEGIN
        RAISE NOTICE 'Second subblock sees: %', shared_value;
    END;
END;
$$;

-- 6.4
CREATE OR REPLACE FUNCTION fee_split(
    p_from_date DATE,
    OUT before_total NUMERIC,
    OUT after_total NUMERIC
) AS $$
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO before_total
    FROM rentals
    WHERE start_date < p_from_date;

    SELECT COALESCE(SUM(fee), 0)
    INTO after_total
    FROM rentals
    WHERE start_date >= p_from_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fee_split(DATE '2025-01-01');
-- 7.1
CREATE OR REPLACE FUNCTION station_load(
    p_station_id INT,
    OUT bikes_parked INT,
    OUT capacity_pct NUMERIC
) AS $$
DECLARE
    v_capacity INT;
BEGIN
    SELECT s.capacity, COUNT(b.bike_id)::INT
    INTO v_capacity, bikes_parked
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.station_id = p_station_id
    GROUP BY s.capacity;

    IF v_capacity = 0 THEN
        capacity_pct := NULL;
    ELSE
        capacity_pct := ROUND(bikes_parked::NUMERIC * 100 / v_capacity, 1);
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT s.station_id, s.station_name, l.*
FROM stations s, LATERAL station_load(s.station_id) l
ORDER BY s.station_id;

-- 7.2
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE (
    member_name VARCHAR,
    rental_count BIGINT,
    amount_spent NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name::VARCHAR,
           COUNT(r.rental_id),
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    GROUP BY m.member_id, m.full_name
    ORDER BY COALESCE(SUM(r.fee), 0) DESC, m.member_id
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM top_members();
SELECT * FROM top_members(6);

--7.3
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE (
    member_name VARCHAR,
    bike_model VARCHAR,
    duration_days INT,
    amount_owed NUMERIC,
    rental_status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name::VARCHAR,
           b.model::VARCHAR,
           (COALESCE(r.end_date, CURRENT_DATE) - r.start_date)::INT,
           ROUND(
               (COALESCE(r.end_date, CURRENT_DATE) - r.start_date)
               * b.daily_rate,
               2
           ),
           (CASE WHEN r.end_date IS NULL THEN 'OPEN' ELSE 'CLOSED' END)::VARCHAR
    FROM rentals r
    JOIN members m ON m.member_id = r.member_id
    JOIN bikes b ON b.bike_id = r.bike_id
    WHERE r.rental_id = p_rental_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM rental_invoice(11);

SELECT * FROM rental_invoice(19);

-- 7.4
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR)
RETURNS TABLE (
    member_count BIGINT,
    rental_count BIGINT,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id),
           COUNT(r.rental_id),
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION city_report(
    p_city VARCHAR,
    p_from_date DATE
)
RETURNS TABLE (
    member_count BIGINT,
    rental_count BIGINT,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id),
           COUNT(r.rental_id),
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r
      ON r.member_id = m.member_id
     AND r.start_date >= p_from_date
    WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM city_report('Almaty');
SELECT * FROM city_report('Almaty', DATE '2025-01-01');