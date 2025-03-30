-- Create Database
CREATE DATABASE blood_donation;
USE blood_donation;

-- Donors Table
CREATE TABLE donors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact VARCHAR(20) NOT NULL UNIQUE,
    blood_group VARCHAR(5) NOT NULL,
    location VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Hospitals Table (Updated)
CREATE TABLE hospitals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    location VARCHAR(200) NOT NULL,
    contact VARCHAR(20) NOT NULL UNIQUE,
    verified BOOLEAN DEFAULT TRUE,  -- Default to TRUE when inserted
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_hospital (name, location, contact)  -- Prevent duplicate hospital entries
);

-- Blood Requests Table
CREATE TABLE blood_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hospital_id INT,
    blood_group VARCHAR(5) NOT NULL,
    location VARCHAR(100) NOT NULL,
    status ENUM('Pending', 'In Progress', 'Completed') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id)
);

-- Donor Matching Table
CREATE TABLE donor_matches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT,
    donor_id INT,
    match_status ENUM('Pending', 'Confirmed', 'Rejected') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES blood_requests(id),
    FOREIGN KEY (donor_id) REFERENCES donors(id)
);

-- Indexes for Performance
CREATE INDEX idx_donors_blood_group ON donors(blood_group);
CREATE INDEX idx_donors_location ON donors(location);
CREATE INDEX idx_blood_requests_status ON blood_requests(status);
CREATE INDEX idx_hospitals_verified ON hospitals(verified);

-- Stored Procedure for Donor Search (Remains the same)
DELIMITER //
CREATE PROCEDURE search_donors(
    IN p_blood_group VARCHAR(5),
    IN p_location VARCHAR(100)
)
BEGIN
    SELECT id, name, contact, blood_group, location
    FROM donors
    WHERE 
        (p_blood_group IS NULL OR blood_group = p_blood_group)
        AND (p_location IS NULL OR location = p_location);
END //
DELIMITER ;

-- Trigger to Validate Donor Registration
DELIMITER //
CREATE TRIGGER validate_donor_registration
BEFORE INSERT ON donors
FOR EACH ROW
BEGIN
    -- Validate Blood Group
    IF NEW.blood_group NOT IN ('A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-') THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Invalid blood group';
    END IF;

    -- Validate Contact Number
    IF NEW.contact REGEXP '^[0-9]{10}$' = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid contact number';
    END IF;
END //
DELIMITER ;

-- Sample Data Insertion
INSERT INTO hospitals (name, location, contact) VALUES 
('City General Hospital', 'Mumbai', '9876543210'),
('Central Medical Center', 'Delhi', '8765432109');

INSERT INTO donors (name, contact, blood_group, location) VALUES 
('John Doe', '1234567890', 'A+', 'Mumbai'),
('Jane Smith', '9876543210', 'B-', 'Delhi');

INSERT INTO blood_requests (hospital_id, blood_group, location) VALUES 
(1, 'A+', 'Mumbai');