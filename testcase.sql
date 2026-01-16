/* Query: Find Popular Accommodations with Active Hosts and Positive Reviews

Requirements:
	•	The accommodation must have been booked at least twice.
	•	The host must have received at least one review with a rating of 4 or 5.
	•	The guest who booked must have published at least one review.
	•	The booking must be confirmed.
	•	Include accommodation details, host details, number of bookings, and average review rating for the host. */
    
SELECT 
    a.accommodation_id, 
    a.title, 
    a.host_id, 
    u.name AS host_name, 
    COUNT(b.booking_id) AS total_bookings,
    (SELECT AVG(r.rating) 
     FROM Reviews r
     JOIN Bookings b2 ON r.booking_id = b2.booking_id
     WHERE b2.accommodation_id = a.accommodation_id 
     AND r.review_type = 'host'
    ) AS avg_host_rating
FROM Accommodations a
JOIN Users u ON a.host_id = u.user_id
JOIN Bookings b ON a.accommodation_id = b.accommodation_id
WHERE b.status = 'confirmed'
AND a.host_id IN (
    -- Subquery: Find hosts who have received at least one review with a rating of 4 or 5
    SELECT DISTINCT u.user_id
    FROM Users u
    JOIN Accommodations a ON u.user_id = a.host_id
    JOIN Bookings b ON a.accommodation_id = b.accommodation_id
    JOIN Reviews r ON b.booking_id = r.booking_id
    WHERE r.review_type = 'host' AND r.rating >= 4
)
AND b.guest_id IN (
    -- Subquery: Find guests who have published at least one review
    SELECT DISTINCT r.reviewer_id 
    FROM Reviews r
    WHERE r.reviewer_id IS NOT NULL
)
GROUP BY a.accommodation_id, a.title, a.host_id, u.name
HAVING COUNT(b.booking_id) > 1;  
-- Ensure the accommodation has been booked at least twice
