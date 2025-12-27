-- temp series month

WITH days AS (
  SELECT generate_series(
    date_trunc('day', now() AT TIME ZONE 'UTC') - interval '29 days',
    date_trunc('day', now() AT TIME ZONE 'UTC'),
    interval '1 day'
  ) AS day_ts
)
SELECT
  d.day_ts AS measured_date,
  s.name   AS station,
  AVG(m.temperature_c) AS temperature_c
FROM days d
CROSS JOIN weather_station s
LEFT JOIN weather_measurement m
  ON m.station_id = s.id
 AND date_trunc('day', m.measured_at AT TIME ZONE 'UTC') = d.day_ts
GROUP BY d.day_ts, s.name
ORDER BY d.day_ts, s.name;

-- count conditions

WITH rng AS (
  SELECT date_trunc('month', now()) - interval '1 month' AS start_ts,
         date_trunc('month', now())                         AS end_ts
)
SELECT
  m.condition AS condition,
  COUNT(*)    AS count
FROM weather_measurement m
JOIN rng r
  ON m.measured_at >= r.start_ts
 AND m.measured_at <  r.end_ts
GROUP BY m.condition
ORDER BY count DESC;

-- avg windspeed

WITH hours AS (
  SELECT generate_series(
    date_trunc('hour', now() AT TIME ZONE 'UTC') - interval '47 hours',
    date_trunc('hour', now() AT TIME ZONE 'UTC'),
    interval '1 hour'
  ) AS hour_ts
),
station_hour AS (
  SELECT
    h.hour_ts,
    s.id AS station_id,
    AVG(m.wind_speed_ms) AS station_avg
  FROM hours h
  CROSS JOIN weather_station s
  LEFT JOIN weather_measurement m
    ON m.station_id = s.id
   AND date_trunc('hour', m.measured_at AT TIME ZONE 'UTC') = h.hour_ts
  GROUP BY h.hour_ts, s.id
)
SELECT
  sh.hour_ts AS measured_at,
  AVG(sh.station_avg) AS wind_speed_ms
FROM station_hour sh
GROUP BY sh.hour_ts
ORDER BY sh.hour_ts;

-- avg msrmt table 1 month

WITH rng AS (
  SELECT date_trunc('month', now()) - interval '1 month' AS start_ts,
         date_trunc('month', now())                         AS end_ts
)
SELECT
  s.id   AS station_id,
  s.name AS station,
  AVG(m.temperature_c)    AS avg_temperature_c,
  AVG(m.humidity_pct)     AS avg_humidity_pct,
  AVG(m.pressure_hpa)     AS avg_pressure_hpa,
  AVG(m.wind_speed_ms)    AS avg_wind_speed_ms,
  CASE
    WHEN degrees(atan2(AVG(sin(radians(m.wind_dir_deg))), AVG(cos(radians(m.wind_dir_deg))))) < 0
    THEN degrees(atan2(AVG(sin(radians(m.wind_dir_deg))), AVG(cos(radians(m.wind_dir_deg))))) + 360
    ELSE degrees(atan2(AVG(sin(radians(m.wind_dir_deg))), AVG(cos(radians(m.wind_dir_deg)))))
  END                     AS avg_wind_dir_deg,
  AVG(m.precipitation_mm) AS avg_precipitation_mm
FROM weather_measurement m
JOIN weather_station s ON s.id = m.station_id
JOIN rng r
  ON m.measured_at >= r.start_ts
 AND m.measured_at <  r.end_ts
GROUP BY s.id, s.name
ORDER BY s.name;

-- temp series 48h

WITH hours AS (
  SELECT generate_series(
    date_trunc('hour', now() AT TIME ZONE 'UTC') - interval '47 hours',
    date_trunc('hour', now() AT TIME ZONE 'UTC'),
    interval '1 hour'
  ) AS hour_ts
)
SELECT
  h.hour_ts AS measured_at,
  s.name AS station,
  AVG(m.temperature_c) AS temperature_c
FROM hours h
CROSS JOIN weather_station s
LEFT JOIN weather_measurement m
  ON m.station_id = s.id
 AND date_trunc('hour', m.measured_at AT TIME ZONE 'UTC') = h.hour_ts
GROUP BY h.hour_ts, s.name
ORDER BY h.hour_ts, s.name;

-- temp series 60sec

WITH seconds AS (
  SELECT generate_series(
    date_trunc('second', now() AT TIME ZONE 'UTC') - interval '60 seconds',
    date_trunc('second', now() AT TIME ZONE 'UTC'),
    interval '1 second'
  ) AS second_ts
)
SELECT
  s.second_ts AS measured_at,
  ws.name     AS station,
  AVG(m.temperature_c) AS temperature_c
FROM seconds s
CROSS JOIN weather_station ws
LEFT JOIN weather_measurement m
  ON m.station_id = ws.id
 AND date_trunc('second', m.measured_at AT TIME ZONE 'UTC') = s.second_ts
GROUP BY s.second_ts, ws.name
ORDER BY s.second_ts, ws.name;