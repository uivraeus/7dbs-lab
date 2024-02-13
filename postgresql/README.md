# PostgreSQL

## Notes from Day 1

* "Proper" way of defining `events.venue_id`?
  * type?
  * w or w/o `FOREIGN KEY`?
* There are three match types
  * MATCH FULL (all match or all null)
  * MATCH PARTIAL (not yet implemented?)
  * MATCH SIMPLE (default)

### Scratch pad

```sql
CREATE TABLE countries (
  country_code char(2) PRIMARY KEY,
  country_name text UNIQUE
);

INSERT INTO countries (country_code, country_name)
VALUES ('us', 'United States'), ('mx', 'Mexico'), ('au', 'Australia'),
       ('gb', 'United Kingdom'), ('de', 'Germany'), ('ll', 'Loompaland');

INSERT INTO countries
VALUES ('uk', 'United Kingdom');

SELECT  *
FROM countries;

DELETE FROM countries
WHERE  country_code = 'll';

CREATE TABLE cities (
  name text NOT NULL,
  postal_code varchar(9) CHECK (postal_code <> ''),
  country_code char(2) REFERENCES countries,
  PRIMARY KEY (country_code, postal_code)
);

INSERT INTO cities
VALUES ('Toronto', 'M4C1B5', 'ca');

INSERT INTO cities
VALUES ('Portland', '87200', 'us');

UPDATE cities
SET postal_code = '97206'
WHERE name = 'Portland';

SELECT cities.*, country_name
FROM cities INNER JOIN countries /*can skip INNER here*/
  ON cities.country_code = countries.country_code;

CREATE TABLE venues (
  venue_id SERIAL PRIMARY KEY,
  name varchar(255),
  street_address text,
  type char(7) CHECK ( type in ('public','private') ) DEFAULT 'public',
  postal_code varchar(9),
  country_code char(2),
  FOREIGN KEY (country_code, postal_code)
    REFERENCES cities (country_code, postal_code) MATCH FULL /*both exists or both NULL */
);

INSERT INTO venues (name, postal_code, country_code)
VALUES ('Crystal Ballroom', '97206', 'us');

SELECT v.venue_id, v.name, c.name
FROM venues v INNER JOIN cities AS c /* AS is optional */
  ON v.postal_code=c.postal_code AND v.country_code=c.country_code;

INSERT INTO venues (name, postal_code, country_code)
VALUES ('Voodoo Doughnut', '97206', 'us') RETURNING venue_id;

CREATE TABLE events(
  event_id SERIAL PRIMARY KEY,
  title varchar(255),
  starts timestamp,
  ends timestamp,
  venue_id INTEGER REFERENCES venues 
);

INSERT INTO events (title, starts, ends, venue_id)
VALUES
  ('Fight Club', '2018-02-15 17:30:00', '2018-02-15 19:30:00', 2);
INSERT INTO events (title, starts, ends)
VALUES
  ('April Fools Day', '2018-04-01 00:00:00', '2018-04-01 23:59:59'),
  ('Chritmas Day', '2018-02-15 19:30:00', '2018-12-25 23:59:59');

UPDATE events
SET title = 'Christman Day', starts = '2018-12-25 00:00:00'
WHERE title = 'Chritmas Day';

SELECT e.title, v.name
FROM events e JOIN venues v
  ON e.venue_id = v.venue_id;

SELECT e.title, v.name
FROM events e LEFT JOIN venues v
  ON e.venue_id = v.venue_id;

CREATE INDEX events_title
  ON events USING hash (title);

SELECT *
FROM events
WHERE starts >= '2018-04-01';

CREATE INDEX events_starts
  ON events USING btree (starts);

/* assume relnamespace=2200 for all "my tables"? */
SELECT relname,relkind,relname,relnamespace,relpages,reltuples,relhasindex,relnatts,relchecks
FROM pg_class
WHERE relkind='r' AND relname NOT LIKE 'pg_%' AND relname NOT LIKE 'sql_%'; 

SELECT c.country_name
FROM countries c
WHERE c.country_code = (
  SELECT v.country_code
  FROM events e JOIN venues v ON e.venue_id = v.venue_id
  WHERE e.title='Fight Club'
);

ALTER TABLE venues
ADD COLUMN  IF NOT EXISTS active BOOLEAN DEFAULT TRUE;
```

## Notes from Day 2

* Update of VIEW works for me (add colors to Christmas Day)
  * After 9.3; https://www.postgresql.org/docs/current/sql-createview.html#SQL-CREATEVIEW-UPDATABLE-VIEWS
  * No need for custom RULE

### Scratch pad

```sql
INSERT INTO countries (country_code, country_name)
  VALUES ('se', 'Sweden');

INSERT INTO cities (name, postal_code, country_code)
  VALUES ('Gothenburg', '41320', 'se');

INSERT INTO venues (name, street_address, type, postal_code, country_code)
  VALUES ('My Place', 'Dalheimersgatan 4A', 'private', '41320', 'se');

INSERT INTO events (title, starts, ends, venue_id)
  VALUES ('Moby','2018-02-06 21:00:00','2018-02-06 23:00:00', (
    SELECT venue_id
    FROM venues
    WHERE name = 'Crystal Ballroom'
  ));

INSERT INTO events (title, starts, ends, venue_id)
  VALUES ('Wedding','2018-02-26 21:00:00','2018-02-26 23:00:00', (
    SELECT venue_id
    FROM venues
    WHERE name = 'Voodoo Doughnut'
  )), ('Dinner with Mom','2018-02-26 18:00:00','2018-02-26 20:30:00', (
    SELECT venue_id
    FROM venues
    WHERE name = 'My Place'
  )), ('Valentine''s Day','2018-02-14 00:00:00','2018-02-14 23:59:59', NULL);

SELECT count(title)
FROM events
WHERE title LIKE '%Day%';

SELECT min(starts), max(ends)
FROM events INNER JOIN venues
  ON events.venue_id = venues.venue_id
WHERE venues.name = 'Crystal Ballroom';

SELECT venue_id, count(*)
FROM events
GROUP BY venue_id;

SELECT venue_id
FROM events
GROUP BY venue_id
HAVING count(*) >= 2 AND venue_id IS NOT NULL;

SELECT venue_id FROM events GROUP BY venue_id;

SELECT DISTINCT venue_id FROM events;

/* invalid query, title not in GROUP BY */
SELECT title, venue_id, count(*)
FROM events
GROUP BY venue_id;

SELECT title, venue_id, count(*)
 OVER (PARTITION BY venue_id)
FROM events
ORDER BY venue_id;

SELECT title, count(*)
 OVER (PARTITION BY venue_id)
FROM events;

BEGIN TRANSACTION;
 DELETE FROM events;
ROLLBACK; /* kill transaction */
SELECT * FROM events;

\i add_event.sql

SELECT add_event('House Party', '2018-05-03 23:00:00','2018-05-04 02:00:00','Run''s House','97206','us');

CREATE TABLE logs (
  event_id integer,
  old_title varchar(255),
  old_starts timestamp,
  old_ends timestamp,
  logged_at timestamp DEFAULT current_timestamp
);

\i log_event.sql

CREATE TRIGGER log_events
  AFTER UPDATE ON events
  FOR EACH ROW EXECUTE PROCEDURE log_event();

UPDATE events
SET ends='2018-05-04 01:00:00'
WHERE title='House Party';

SELECT event_id, old_title, old_ends, logged_at
FROM logs;

\i holiday_view_1.sql

SELECT name, to_char(date, 'Month DD, YYYY') as date
FROM holidays
WHERE date <= '2018-04-01';

ALTER TABLE events
ADD colors text ARRAY;

CREATE OR REPLACE VIEW holidays AS
  SELECT event_id AS holiday_id, title AS name, starts AS date, colors
  FROM events
  WHERE title LIKE '%Day%' AND venue_id IS NULL;

UPDATE events
SET title = 'Christmas Day'
WHERE title = 'Christman Day';

/* invalid according to the book - but it works for me (pg16) */
UPDATE holidays SET colors = '{"red","green"}' WHERE name = 'Christmas Day';

EXPLAIN VERBOSE
  SELECT *
  FROM holidays;

SELECT extract(year from starts) AS year, extract(month from starts) AS month, count(*)
FROM events
GROUP BY year, month
ORDER BY year, month;

CREATE TEMPORARY TABLE month_count(month INT);
INSERT INTO month_count VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12); 

/* Required to enable crosstab */
CREATE EXTENSION tablefunc;

SELECT * FROM crosstab(
  'SELECT extract(year from starts) AS year, extract(month from starts) AS month, count(*)
  FROM events
  GROUP BY year, month
  ORDER BY year, month',
  'SELECT * FROM month_count'
) AS (
  year int,
  jan int, feb int, mar int, apr int, may int, jun int,
  jul int, aug int, sep int, oct int, nov int, dec int
) ORDER BY YEAR;

CREATE RULE delete_venues AS ON DELETE TO venues DO INSTEAD
  UPDATE venues
  SET active = FALSE
  WHERE venue_id = OLD.venue_id;

/* to see my rule */
\d venues

INSERT INTO venues (name,postal_code,country_code) VALUES ('Dummy','41320','se');
DELETE FROM venues WHERE name='Dummy';

SELECT * FROM crosstab(
  'SELECT extract(year from starts) AS year, extract(month from starts) AS month, count(*)
  FROM events
  GROUP BY year, month
  ORDER BY year, month',
  'SELECT generate_series(1,12)'
) AS (
  year int,
  jan int, feb int, mar int, apr int, may int, jun int,
  jul int, aug int, sep int, oct int, nov int, dec int
) ORDER BY YEAR;

SELECT extract(week from starts) AS week, extract(day from starts) AS day, count(*)
FROM events
WHERE extract(year from starts) = '2018'
  AND extract(month from starts) = 2
GROUP BY week, day
ORDER BY week, day;

INSERT INTO events (title, starts, ends)
VALUES
  ('Sunday-school', '2018-02-04 08:30:00', '2018-02-04 08:30:00'),
  ('Sunday-school', '2018-02-11 08:30:00', '2018-02-11 08:30:00'),
  ('Sunday-school', '2018-02-18 08:30:00', '2018-02-18 08:30:00'),
  ('Sunday-school', '2018-02-25 08:30:00', '2018-02-25 08:30:00');

INSERT INTO events (title, starts, ends)
VALUES
  ('Sunday-school detention', '2018-02-18 08:30:00', '2018-02-18 08:30:00');


/* 'week' is actually 'ISO week' so 'isodow' makes more sense than 'dow'
 * [https://www.postgresql.org/docs/current/functions-datetime.html]
 *
 * -> show weeks as Mon->Sun
 */
SELECT * FROM crosstab(
  '
  SELECT extract(week from starts) AS week, extract(isodow from starts) AS isodow, count(*)
  FROM events
  WHERE extract(year from starts) = ''2018''
    AND extract(month from starts) = 2
  GROUP BY week, isodow
  ORDER BY week, isodow
  ',
  '
  SELECT generate_series(1,7)
  '
) AS (
  week int,
  Monday int, Tuesday int , Wednesday int, Thursday int, Friday int, Saturday int, Sunday int
) ORDER BY week;
```
