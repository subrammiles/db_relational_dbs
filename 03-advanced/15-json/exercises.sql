-- 15 · Exercises with solutions
-- An events table with a JSON payload, as you'd get from a web or app tracker.

CREATE TEMP TABLE events (
    event_id    INT PRIMARY KEY,
    created_at  TIMESTAMPTZ NOT NULL,
    payload     JSONB NOT NULL
);

INSERT INTO events VALUES
    (1, '2025-05-01 10:00+00', '{"type": "page_view", "user": {"id": 1, "country": "IN"}, "page": "/home"}'),
    (2, '2025-05-01 10:01+00', '{"type": "add_to_cart", "user": {"id": 1, "country": "IN"}, "items": [{"sku": "LAP-1", "qty": 1}, {"sku": "MOU-2", "qty": 2}]}'),
    (3, '2025-05-01 11:00+00', '{"type": "page_view", "user": {"id": 2, "country": "UK"}, "page": "/products"}'),
    (4, '2025-05-02 09:30+00', '{"type": "purchase", "user": {"id": 1, "country": "IN"}, "amount": 86600, "items": [{"sku": "LAP-1", "qty": 1}, {"sku": "MOU-2", "qty": 2}]}'),
    (5, '2025-05-02 12:00+00', '{"type": "page_view", "user": {"id": 3, "country": "US"}, "page": "/home"}'),
    (6, '2025-05-03 08:00+00', '{"type": "purchase", "user": {"id": 2, "country": "UK"}, "amount": 4500, "items": [{"sku": "KEY-3", "qty": 1}]}');

-- 1. Number of events per type.
SELECT payload ->> 'type' AS event_type, COUNT(*) AS events
FROM events
GROUP BY 1
ORDER BY events DESC;

-- 2. Total purchase amount per country.
SELECT payload -> 'user' ->> 'country' AS country, SUM((payload ->> 'amount')::NUMERIC) AS revenue
FROM events
WHERE payload ->> 'type' = 'purchase'
GROUP BY 1
ORDER BY revenue DESC;

-- 3. Units purchased per SKU (unnest the items array).
SELECT item ->> 'sku' AS sku, SUM((item ->> 'qty')::INT) AS units
FROM events
CROSS JOIN LATERAL jsonb_array_elements(payload -> 'items') AS item
WHERE payload ->> 'type' = 'purchase'
GROUP BY 1
ORDER BY units DESC;

-- 4. Users who viewed '/home' and later purchased.
SELECT DISTINCT (v.payload -> 'user' ->> 'id')::INT AS user_id
FROM events v
JOIN events p
  ON p.payload -> 'user' ->> 'id' = v.payload -> 'user' ->> 'id'
 AND p.payload ->> 'type' = 'purchase'
 AND p.created_at > v.created_at
WHERE v.payload @> '{"type": "page_view", "page": "/home"}';

-- 5. Add a GIN index that would speed up question 4's containment filter.
CREATE INDEX events_payload_gin ON events USING GIN (payload jsonb_path_ops);

-- 6. One JSON summary per user: {"user": 1, "events": 3, "types": ["add_to_cart", ...]}
SELECT jsonb_build_object(
           'user',   (payload -> 'user' ->> 'id')::INT,
           'events', COUNT(*),
           'types',  jsonb_agg(DISTINCT payload ->> 'type')
       ) AS summary
FROM events
GROUP BY payload -> 'user' ->> 'id'
ORDER BY payload -> 'user' ->> 'id';
