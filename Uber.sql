-- Uber India Ride Analytics – July 2024 (Bangalore)
-- MySQL. Source table: bookings (loaded from Bookings.xlsx, sheet "July")

-- 0. Database
CREATE DATABASE IF NOT EXISTS Uber;
USE Uber;

-- ------------------------------------------------------------
-- Cleaning
-- ------------------------------------------------------------

-- 1. Drop the empty spreadsheet rows that came in under the data
DELETE FROM bookings
WHERE Booking_ID IS NULL OR Booking_ID = '';

-- 2. Cleaned view: "No" placeholders -> NULL / 0, one timestamp instead of Date + Time
CREATE OR REPLACE VIEW bookings_clean AS
SELECT
    Booking_ID,
    Booking_Status,
    Customer_ID,
    Vehicle_Type,
    Pickup_Location,
    Drop_Location,
    STR_TO_DATE(CONCAT(Date, ' ', Time), '%Y-%m-%d %H:%i:%s')           AS Booking_TS,
    CASE WHEN V_TAT = 'No' THEN 0 ELSE CAST(V_TAT AS DECIMAL(10,2)) END  AS V_TAT,
    CASE WHEN C_TAT = 'No' THEN 0 ELSE CAST(C_TAT AS DECIMAL(10,2)) END  AS C_TAT,
    CASE WHEN Booking_Value = 'No' THEN 0
         ELSE CAST(Booking_Value AS DECIMAL(12,2)) END                   AS Booking_Value,
    CASE WHEN Payment_Method = 'No' THEN NULL ELSE Payment_Method END    AS Payment_Method,
    CASE WHEN Ride_Distance = 'No' THEN 0
         ELSE CAST(Ride_Distance AS DECIMAL(10,2)) END                   AS Ride_Distance,
    Canceled_Rides_by_Customer,
    Canceled_Rides_by_Driver,
    Incomplete_Rides,
    Incomplete_Rides_Reason,
    Driver_Ratings,
    Customer_Rating
FROM bookings;

-- 3. Fix the corrupted neighbourhood names in the source ("Nogar" / "Nohalli" / "BaNo...")
UPDATE bookings SET Pickup_Location = REPLACE(Pickup_Location, 'Nogar', 'Nagar'),
                    Drop_Location   = REPLACE(Drop_Location,   'Nogar', 'Nagar');
UPDATE bookings SET Pickup_Location = REPLACE(Pickup_Location, 'Nohalli', 'nahalli'),
                    Drop_Location   = REPLACE(Drop_Location,   'Nohalli', 'nahalli');
UPDATE bookings SET Pickup_Location = REPLACE(Pickup_Location, 'BaNoshankari', 'Banashankari'),
                    Drop_Location   = REPLACE(Drop_Location,   'BaNoshankari', 'Banashankari');
UPDATE bookings SET Pickup_Location = REPLACE(Pickup_Location, 'PadmaNobhaNagar', 'Padmanabhanagar'),
                    Drop_Location   = REPLACE(Drop_Location,   'PadmaNobhaNagar', 'Padmanabhanagar');

-- 4. Row-count check before/after cleaning
SELECT COUNT(*) AS total_rows,
       SUM(Booking_Status = 'Success') AS completed,
       ROUND(100 * SUM(Booking_Status = 'Success') / COUNT(*), 1) AS completion_pct
FROM bookings_clean;

-- ------------------------------------------------------------
-- Aggregations used by the Power BI visuals
-- ------------------------------------------------------------

-- 5. Requests by hour of day
SELECT HOUR(Booking_TS) AS hour_of_day, COUNT(*) AS requests
FROM bookings_clean
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- 6. Requests by day
SELECT DATE(Booking_TS) AS booking_date, DAYNAME(Booking_TS) AS weekday, COUNT(*) AS requests
FROM bookings_clean
GROUP BY booking_date, weekday
ORDER BY booking_date;

-- 7. Top pickup locations
SELECT Pickup_Location, COUNT(*) AS pickups
FROM bookings_clean
GROUP BY Pickup_Location
ORDER BY pickups DESC
LIMIT 8;

-- 8. Outcome breakdown as share of all requests
SELECT Booking_Status,
       COUNT(*) AS requests,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM bookings_clean), 1) AS pct_of_requests
FROM bookings_clean
GROUP BY Booking_Status
ORDER BY requests DESC;

-- 9. Revenue and average fare by service tier (completed trips only)
SELECT Vehicle_Type,
       COUNT(*)                         AS completed_trips,
       SUM(Booking_Value)               AS revenue,
       ROUND(AVG(Booking_Value), 0)     AS avg_fare,
       ROUND(AVG(Ride_Distance), 1)     AS avg_distance_km
FROM bookings_clean
WHERE Booking_Status = 'Success'
GROUP BY Vehicle_Type
ORDER BY revenue DESC;

-- 10. Payment method mix (completed trips)
SELECT Payment_Method, COUNT(*) AS trips,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM bookings_clean
WHERE Booking_Status = 'Success'
GROUP BY Payment_Method
ORDER BY trips DESC;

-- ------------------------------------------------------------
-- Smaller questions
-- ------------------------------------------------------------

-- 11. Average ride distance per vehicle type
SELECT Vehicle_Type, ROUND(AVG(Ride_Distance), 1) AS avg_distance_km
FROM bookings_clean
GROUP BY Vehicle_Type;

-- 12. Top 5 customers by ride count
SELECT Customer_ID, COUNT(*) AS total_rides
FROM bookings_clean
GROUP BY Customer_ID
ORDER BY total_rides DESC
LIMIT 5;

-- 13. Driver cancellations due to personal or car issues
SELECT COUNT(*) AS driver_cancel_personal_car
FROM bookings_clean
WHERE Canceled_Rides_by_Driver = 'Personal & Car related issue';

-- 14. Driver rating range for Uber Black
SELECT MAX(Driver_Ratings) AS max_rating, MIN(Driver_Ratings) AS min_rating
FROM bookings_clean
WHERE Vehicle_Type = 'Uber Black';

-- 15. Average customer rating per vehicle type
SELECT Vehicle_Type, ROUND(AVG(Customer_Rating), 2) AS avg_customer_rating
FROM bookings_clean
GROUP BY Vehicle_Type;

-- 16. Incomplete rides with reasons
SELECT Booking_ID, Incomplete_Rides_Reason
FROM bookings_clean
WHERE Incomplete_Rides = 'Yes';
