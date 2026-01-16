CREATE DATABASE AirbnbDB;
USE AirbnbDB;

CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each user
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(200) NOT NULL,
    phone VARCHAR(15) UNIQUE,  -- Optional phone number, must be unique if provided
    profile_photo VARCHAR(255),
    is_guest BOOLEAN DEFAULT TRUE,  -- Default role as guest
    is_host BOOLEAN DEFAULT FALSE,  -- Determines if the user is a host
    is_superhost BOOLEAN DEFAULT FALSE,  -- Superhosts are also hosts
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE,
    CHECK (is_guest = TRUE OR is_host = TRUE),  -- Ensures the user has at least one role
    CHECK (is_superhost = FALSE OR is_host = TRUE)  -- Ensures superhosts are also hosts
);

CREATE TABLE Admins (
    admin_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each admin
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(200) NOT NULL,
    admin_level ENUM('basic', 'super') DEFAULT 'basic',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each location
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),  -- State name, optional (for countries without states)
    country VARCHAR(100) NOT NULL
);

CREATE TABLE Neighborhoods (
    neighborhood_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each neighborhood
    location_id INT NOT NULL,  -- References the location this neighborhood belongs to
    name VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    description TEXT NOT NULL,
    UNIQUE (location_id, name),  -- Ensures neighborhood names are unique within a specific location
    FOREIGN KEY (location_id) REFERENCES Locations(location_id) ON DELETE CASCADE
    -- If a location is deleted, its neighborhoods are also removed
);

CREATE TABLE Accommodations (
    accommodation_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each accommodation
    host_id INT NOT NULL,  -- References the user who is hosting the accommodation
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    price_per_night DECIMAL(10,2) NOT NULL CHECK (price_per_night >= 1),
    -- Price per night (ensures natural numbers)
    neighborhood_id INT NULL,
    -- References a neighborhood, nullable (some accommodations may not be in a neighborhood)
    location_id INT NULL,  -- References a location, nullable (used if neighborhood_id is NULL)
    max_guests INT NOT NULL NOT NULL CHECK (max_guests >= 1),
    -- Maximum number of guests allowed (ensures natural numbers)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (host_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    -- If the host is deleted, the accommodation is also removed
    FOREIGN KEY (neighborhood_id) REFERENCES Neighborhoods(neighborhood_id) ON DELETE SET NULL,
    -- If a neighborhood is deleted, the accommodation remains
    FOREIGN KEY (location_id) REFERENCES Locations(location_id) ON DELETE CASCADE
    -- If a location is deleted, related accommodations are removed
);

CREATE TABLE Photos (
    photo_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each photo
    accommodation_id INT NOT NULL,  -- References the accommodation this photo belongs to
    url VARCHAR(255) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (accommodation_id) REFERENCES Accommodations(accommodation_id) ON DELETE CASCADE
    -- If an accommodation is deleted, its photos are also removed
);

CREATE TABLE Bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,  
    guest_id INT NULL,
    /* References the guest making the booking
    Allow NULL so ON DELETE SET NULL works */
    accommodation_id INT NULL,
    /* References the booked accommodation
    Allow NULL so ON DELETE SET NULL works */
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    status ENUM('pending', 'confirmed', 'canceled') DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (guest_id) REFERENCES Users(user_id) ON DELETE SET NULL,  
    -- If a guest is deleted, set guest_id to NULL
    FOREIGN KEY (accommodation_id) REFERENCES Accommodations(accommodation_id) ON DELETE SET NULL,  
    -- If accommodation is deleted, set accommodation_id to NULL
    CHECK (check_out > check_in)  -- Ensures check-out date is later than check-in date
);

CREATE TABLE Payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each payment
    booking_id INT NOT NULL,  -- References the related booking
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 1),  -- Payment amount (must be non-negative)
    method ENUM('credit_card', 'paypal') NOT NULL,
    status ENUM('pending', 'confirmed', 'failed') DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id) ON DELETE CASCADE
    -- If a booking is deleted, related payments are removed
);

CREATE TABLE Reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each review
    booking_id INT NOT NULL,  -- References the related booking
    reviewer_id INT NULL,
    /* References the user leaving the review
    Allow NULL so ON DELETE SET NULL works */
    review_type ENUM('host', 'accommodation', 'guest') NOT NULL,
    rating TINYINT CHECK (rating BETWEEN 1 AND 5) NOT NULL,
    comment TEXT,  -- Optional review comment
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id) ON DELETE CASCADE,
    -- If a booking is deleted, related reviews are also removed
    FOREIGN KEY (reviewer_id) REFERENCES Users(user_id) ON DELETE SET NULL
    -- If a user is deleted, keep the review but set reviewer_id to NULL.
);

CREATE TABLE Messages (
    message_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each message
    sender_id INT NULL,
	/* References the user sending the message
    Allow NULL so ON DELETE SET NULL works */
    receiver_id INT NULL,
	/* References the user receiving the message
    Allow NULL so ON DELETE SET NULL works */
    booking_id INT NULL,  -- Nullable, since some messages may not relate to a booking
    content TEXT NOT NULL,
    sent_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (sender_id) REFERENCES Users(user_id) ON DELETE SET NULL,  
    -- If a user is deleted, keep the message but set sender_id to NULL
    FOREIGN KEY (receiver_id) REFERENCES Users(user_id) ON DELETE SET NULL,  
    -- If a user is deleted, keep the message but set receiver_id to NULL
    FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id) ON DELETE SET NULL  
    -- If a booking is deleted, keep the message but set booking_id to NULL
);

CREATE TABLE Notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each notification
    user_id INT NOT NULL,  -- The user receiving the notification
    type ENUM('booking_update', 'payment_reminder', 'promotion', 'cancellation_update') NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE 
    -- If a user is deleted, their notifications are also deleted
);

CREATE TABLE Amenities (
    amenity_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each amenity
    name VARCHAR(50) NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE Accommodation_Amenities (
    accommodation_id INT NOT NULL,  -- References the accommodation
    amenity_id INT NOT NULL,  -- References the amenity
    is_included BOOLEAN DEFAULT TRUE,
    additional_cost DECIMAL(10,2) DEFAULT 0,
    PRIMARY KEY (accommodation_id, amenity_id),
    -- Composite primary key (each amenity is unique per accommodation)
    FOREIGN KEY (accommodation_id) REFERENCES Accommodations(accommodation_id) ON DELETE CASCADE,
    -- If an accommodation is deleted, its amenities are also removed
    FOREIGN KEY (amenity_id) REFERENCES Amenities(amenity_id) ON DELETE CASCADE
    -- If an amenity is deleted, it is removed from all accommodations
);

CREATE TABLE Policies (
    policy_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each policy
    type ENUM('house_rules', 'cancellation_policy') NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE Accommodation_Policies (
    accommodation_id INT NOT NULL,  -- References the accommodation
    policy_id INT NOT NULL,  -- References the policy
    PRIMARY KEY (accommodation_id, policy_id),
    -- Ensures each accommodation-policy pair is unique
    FOREIGN KEY (accommodation_id) REFERENCES Accommodations(accommodation_id) ON DELETE CASCADE,  
    -- If an accommodation is deleted, its policies are also removed
    FOREIGN KEY (policy_id) REFERENCES Policies(policy_id) ON DELETE CASCADE  
    -- If a policy is deleted, it is removed from all accommodations
);

CREATE TABLE Support_Tickets (
    ticket_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each support ticket
    user_id INT NULL,
	/* References the user who submitted the ticket
    Allow NULL so ON DELETE SET NULL works */
    subject VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    status ENUM('open', 'resolved', 'closed') DEFAULT 'open',  
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved_at DATETIME NULL,
    resolved_by INT NULL, -- Admin responsible
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE SET NULL,  
    -- If a user is deleted, their support tickets are set to NULL
    FOREIGN KEY (resolved_by) REFERENCES Admins(admin_id) ON DELETE SET NULL  
    -- If an admin is deleted, their resolved tickets remain, but `resolved_by` is set to NULL
);

CREATE TABLE Host_Earnings (
    earning_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each earning entry
    booking_id INT NULL,
    /* The booking associated with the earning
    Allow NULL so ON DELETE SET NULL works */
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 1),  -- Payment amount (must be non-negative)
    received_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id) ON DELETE SET NULL
    -- Keeps earnings for analysis even if the host leaves the platform
);

CREATE TABLE Promotions (
    promotion_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each promotion
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL, 
    discount_percent TINYINT CHECK (discount_percent BETWEEN 1 AND 99) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);

CREATE TABLE Promotion_Accommodation (
    promotion_id INT NOT NULL,  -- References a promotion
    accommodation_id INT NOT NULL,  -- References an accommodation
    PRIMARY KEY (promotion_id, accommodation_id),  
    -- Ensures each accommodation can only be linked to a promotion once
    FOREIGN KEY (promotion_id) REFERENCES Promotions(promotion_id) ON DELETE CASCADE,  
    -- If a promotion is deleted, the associated records in this table are also removed
    FOREIGN KEY (accommodation_id) REFERENCES Accommodations(accommodation_id) ON DELETE CASCADE  
    -- If an accommodation is deleted, the related promotions are also removed
);

CREATE TABLE Restricted_Entities (
    restriction_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each restriction
    entity_type ENUM('user', 'accommodation') NOT NULL,
    user_id INT NULL,  -- Stores the ID of the restricted user
    accommodation_id INT NULL,  -- Stores the ID of the restricted accommodation
    reason TEXT NOT NULL,
    banned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NULL,  -- When the restriction expires (NULL means permanent)
    issued_by INT NULL,  -- Admin who issued the restriction
    /* Admin who issued the restriction
    Allow NULL so ON DELETE SET NULL works */
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    -- If the user is deleted, the restriction is also removed
    FOREIGN KEY (accommodation_id) REFERENCES Accommodations(accommodation_id) ON DELETE CASCADE,
    -- If the accommodation is deleted, the restriction is also removed
    FOREIGN KEY (issued_by) REFERENCES Admins(admin_id) ON DELETE SET NULL,  
    -- If the admin is deleted, the restriction remains
    CHECK (
    (user_id IS NOT NULL AND accommodation_id IS NULL) OR 
    (user_id IS NULL AND accommodation_id IS NOT NULL)
    )
);

CREATE TABLE Cancellation (
    cancellation_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each cancellation
    booking_id INT NOT NULL,  -- References the booking that was canceled
    reason TEXT NOT NULL,
    penalty_amount DECIMAL(10,2) DEFAULT 0 CHECK (penalty_amount >= 0),  
    -- Penalty fee applied to the cancellation (must be 0 or positive)
    canceled_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id) ON DELETE CASCADE  
    -- If a booking is deleted, its cancellation record is also removed
);

CREATE TABLE Social_Connections (
    connection_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each social connection
    user_id INT NOT NULL,  -- References the user who linked an external account
    platform ENUM('Facebook', 'Google', 'LinkedIn') NOT NULL, 
    profile_link VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE  
    -- If a user is deleted, their social connections are also removed
);

CREATE TABLE User_Feedback (
    feedback_id INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for each feedback submission
    user_id INT NULL,
    /* References the user providing feedback
    Allow NULL so ON DELETE SET NULL works */
    category ENUM('bug', 'feature_request', 'complaint', 'other') NOT NULL,
    subject VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved_at DATETIME NULL,
    handled_by INT NULL,  -- Admin who handled the feedback (NULL if unassigned)
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE SET NULL,  
    -- If a user is deleted, their feedback remains
    FOREIGN KEY (handled_by) REFERENCES Admins(admin_id) ON DELETE SET NULL  
    -- If an admin is deleted, their handled feedback remains
);