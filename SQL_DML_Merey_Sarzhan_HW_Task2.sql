-- Task 2: Create and Analyze 'table_to_delete'
-- Step 1: Create a large table with dummy data to test storage behavior
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;

-- Step 2: Check space consumption before any operations
SELECT *, pg_size_pretty(total_bytes) AS total,
             pg_size_pretty(index_bytes) AS INDEX,
             pg_size_pretty(toast_bytes) AS toast,
             pg_size_pretty(table_bytes) AS TABLE
FROM (
    SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
    FROM (
        SELECT c.oid,nspname AS table_schema,
                     relname AS TABLE_NAME,
                     c.reltuples AS row_estimate,
                     pg_total_relation_size(c.oid) AS total_bytes,
                     pg_indexes_size(c.oid) AS index_bytes,
                     pg_total_relation_size(reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';

-- Step 3 DELETE 1/3 of records and measure impact
-- execute time 3.192s
-- 575mb
-- after VACUUM FULL VERBOSE table_to_delete; it became 383mb
DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;

-- Step 4 Issue the following TRUNCATE operation
-- truncate 0.045s
-- 8192 bites, it became even smaller


