-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 30, 2025 at 10:24 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `blood_donation`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `search_donors` (IN `p_blood_group` VARCHAR(5), IN `p_location` VARCHAR(100))   BEGIN
    SELECT id, name, contact, blood_group, location
    FROM donors
    WHERE 
        (p_blood_group IS NULL OR blood_group = p_blood_group)
        AND (p_location IS NULL OR location = p_location);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `blood_requests`
--

CREATE TABLE `blood_requests` (
  `id` int(11) NOT NULL,
  `hospital_id` int(11) DEFAULT NULL,
  `blood_group` varchar(5) NOT NULL,
  `location` varchar(100) NOT NULL,
  `status` enum('Pending','In Progress','Completed') DEFAULT 'Pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `blood_requests`
--

INSERT INTO `blood_requests` (`id`, `hospital_id`, `blood_group`, `location`, `status`, `created_at`) VALUES
(1, 1, 'A+', 'Mumbai', 'Pending', '2025-03-27 04:47:37');

-- --------------------------------------------------------

--
-- Table structure for table `donors`
--

CREATE TABLE `donors` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `contact` varchar(20) NOT NULL,
  `blood_group` varchar(5) NOT NULL,
  `location` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `donors`
--

INSERT INTO `donors` (`id`, `name`, `contact`, `blood_group`, `location`, `created_at`) VALUES
(1, 'John Doe', '1234567890', 'A+', 'Mumbai', '2025-03-27 04:47:37'),
(2, 'Jane Smith', '9876543210', 'B-', 'Delhi', '2025-03-27 04:47:37'),
(3, 'Harish', '8825890559', 'A+', 'Namakkal', '2025-03-27 04:48:52'),
(4, 'Indrajith', '9787734799', 'B+', 'Karur', '2025-03-27 04:49:13'),
(5, 'Jainishanth', '8556258952', 'O+', 'Karur', '2025-03-27 04:49:35'),
(6, 'johny', '2565502512', 'AB+', 'Chennai', '2025-03-27 05:01:26'),
(7, 'madhan', '6374885789', 'B+', 'Namakkal', '2025-03-27 08:11:59'),
(8, 'jack', '5221235621', 'B+', 'Namakkal', '2025-03-27 08:21:07'),
(9, 'Sangeetha', '9487708293', 'O+', 'Namakkal', '2025-03-29 04:37:52'),
(10, 'kumarasamy', '9486027193', 'AB+', 'Namakkal', '2025-03-29 15:57:09');

--
-- Triggers `donors`
--
DELIMITER $$
CREATE TRIGGER `validate_donor_registration` BEFORE INSERT ON `donors` FOR EACH ROW BEGIN
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
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `donor_matches`
--

CREATE TABLE `donor_matches` (
  `id` int(11) NOT NULL,
  `request_id` int(11) DEFAULT NULL,
  `donor_id` int(11) DEFAULT NULL,
  `match_status` enum('Pending','Confirmed','Rejected') DEFAULT 'Pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `hospitals`
--

CREATE TABLE `hospitals` (
  `id` int(11) NOT NULL,
  `name` varchar(200) NOT NULL,
  `location` varchar(200) NOT NULL,
  `contact` varchar(20) NOT NULL,
  `verified` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `hospitals`
--

INSERT INTO `hospitals` (`id`, `name`, `location`, `contact`, `verified`, `created_at`) VALUES
(1, 'City General Hospital', 'Mumbai', '9876543210', 1, '2025-03-27 04:47:37'),
(2, 'Central Medical Center', 'Delhi', '8765432109', 1, '2025-03-27 04:47:37'),
(14, 'AGS Hospital', 'Namakkal', '8525897452', 1, '2025-03-29 04:40:05'),
(15, 'Kanmani Hospital', 'Namakkal', '8987754262', 1, '2025-03-29 04:51:48'),
(16, 'RK hospital', 'Namakkal', '8525864552', 1, '2025-03-29 15:58:58');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `blood_requests`
--
ALTER TABLE `blood_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `hospital_id` (`hospital_id`),
  ADD KEY `idx_blood_requests_status` (`status`);

--
-- Indexes for table `donors`
--
ALTER TABLE `donors`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `contact` (`contact`),
  ADD KEY `idx_donors_blood_group` (`blood_group`),
  ADD KEY `idx_donors_location` (`location`);

--
-- Indexes for table `donor_matches`
--
ALTER TABLE `donor_matches`
  ADD PRIMARY KEY (`id`),
  ADD KEY `request_id` (`request_id`),
  ADD KEY `donor_id` (`donor_id`);

--
-- Indexes for table `hospitals`
--
ALTER TABLE `hospitals`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `contact` (`contact`),
  ADD UNIQUE KEY `unique_hospital` (`name`,`location`,`contact`),
  ADD KEY `idx_hospitals_verified` (`verified`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `blood_requests`
--
ALTER TABLE `blood_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `donors`
--
ALTER TABLE `donors`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `donor_matches`
--
ALTER TABLE `donor_matches`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `hospitals`
--
ALTER TABLE `hospitals`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `blood_requests`
--
ALTER TABLE `blood_requests`
  ADD CONSTRAINT `blood_requests_ibfk_1` FOREIGN KEY (`hospital_id`) REFERENCES `hospitals` (`id`);

--
-- Constraints for table `donor_matches`
--
ALTER TABLE `donor_matches`
  ADD CONSTRAINT `donor_matches_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `blood_requests` (`id`),
  ADD CONSTRAINT `donor_matches_ibfk_2` FOREIGN KEY (`donor_id`) REFERENCES `donors` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
