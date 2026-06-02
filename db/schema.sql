-- CREATE DATABASE
DROP DATABASE IF EXISTS appointment_system;
CREATE DATABASE appointment_system;
USE appointment_system;

-- DROP TABLES
DROP TABLE IF EXISTS waitlist;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS timeslots;
DROP TABLE IF EXISTS professors;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS departments;

-- CREATE TABLES

-- user email
CREATE TABLE user_email (
	user_id INT UNIQUE PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL
);

-- User Details Table
CREATE TABLE user_details (
	user_id INT UNIQUE PRIMARY KEY,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM ('STUDENT','PROFESSOR') NOT NULL,
    phone_number VARCHAR(11) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
	FOREIGN KEY (user_id) REFERENCES user_email(user_id)
    ON DELETE CASCADE

);

-- student
CREATE TABLE student (
    student_id INT UNIQUE PRIMARY KEY,
    year INT NOT NULL CHECK (year BETWEEN 1 AND 4),
    FOREIGN KEY (student_id) REFERENCES user_email(user_id)
    ON DELETE CASCADE
);

-- professor
CREATE TABLE professor_department (
    professor_id INT PRIMARY KEY,
    department VARCHAR(100) NOT NULL,
    FOREIGN KEY (professor_id) REFERENCES user_email(user_id)
    ON DELETE CASCADE
);

CREATE TABLE professor_office (
    professor_id INT PRIMARY KEY,
    office_location VARCHAR(100) NOT NULL,
    FOREIGN KEY (professor_id) REFERENCES professor_department(professor_id)
    ON DELETE CASCADE
);

CREATE TABLE professor_timetable (
    timetable_id INT PRIMARY KEY AUTO_INCREMENT,
    professor_id INT NOT NULL,
    FOREIGN KEY (professor_id) REFERENCES professor_department(professor_id)
    ON DELETE CASCADE
);

-- timetable
CREATE TABLE timetable (
    timetable_id INT PRIMARY KEY,
    day ENUM ('Monday', 'Tuesday', 'Wednesday', 
    'Thursday', 'Friday', 'Saturday', 'Sunday'),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_busy BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (timetable_id) REFERENCES professor_timetable(timetable_id)
    ON DELETE CASCADE
);

CREATE TABLE timeslot (
    slot_id INT PRIMARY KEY AUTO_INCREMENT,
    slot_date DATE NOT NULL,
    professor_id INT NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status ENUM ('FREE', 'PARTIALLY_BOOKED', 
    'LOCKED', 'CANCELLED', 'FROZEN') NOT NULL,
    reserved_count INT NOT NULL DEFAULT 0,
    current_bookings INT NOT NULL DEFAULT 0,
    max_capacity INT DEFAULT 3 CHECK(max_capacity BETWEEN 1 AND 3) ,
    is_manually_blocked_by_prof BOOLEAN NOT NULL DEFAULT FALSE,
	FOREIGN KEY (professor_id) REFERENCES professor_department(professor_id) 
    ON DELETE CASCADE
    );

-- appointments

CREATE TABLE student_appointment (
    appointment_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    slot_id INT NOT NULL,
    FOREIGN KEY (student_id) REFERENCES student(student_id) ON DELETE CASCADE,
    FOREIGN KEY (slot_id) REFERENCES timeslot(slot_id) ON DELETE CASCADE
);

CREATE TABLE appointment_details (
    appointment_id INT PRIMARY KEY,
    status ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'WAITLISTED', 'RESERVED') NOT NULL,
    reason ENUM ('CLEARANCE', 'PAPER_RECHECK', 'THESIS_FYP', 'GRADE_APPEAL', 'ATTENDANCE_SHORTAGE',
    'COURSE_REGISTRATION','RECOMMENDATION_LETTER', 'GENERAL_ADVICE') NOT NULL,
    note VARCHAR(255) NULL,
    rejection_reason VARCHAR(300),
    created_at DATETIME NOT NULL,
    rescheduled_from INT,
    FOREIGN KEY (appointment_id) REFERENCES student_appointment(appointment_id)
    ON DELETE CASCADE,
    FOREIGN KEY (rescheduled_from) REFERENCES appointment_details(appointment_id)
    ON DELETE SET NULL
);

-- waitlist
CREATE TABLE waitlisted_student (
    waitlist_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    FOREIGN KEY (student_id) REFERENCES student(student_id)
    ON DELETE CASCADE
); 

CREATE TABLE waitlist_details (
    waitlist_id INT PRIMARY KEY,
    priority_score INT NOT NULL CHECK (priority_score BETWEEN 0 AND 100),
    joined_at DATETIME NOT NULL,
    slot_id INT NOT NULL,
    FOREIGN KEY (slot_id) REFERENCES timeslot(slot_id) ON DELETE CASCADE,
	FOREIGN KEY (waitlist_id) REFERENCES waitlisted_student(waitlist_id)
    ON DELETE CASCADE
);

-- inserting dummy values:

-- user email
INSERT INTO user_email (email) VALUES
('anabi.bscs25seecs@seecs.edu.pk'),
('mali.bba23nbs@nbs.edu.pk'),
('ahassan.bsme22smme@smme.edu.pk'),
('akhan.bsmath24sns@sns.edu.pk'),
('asiddiq.bese22seecs@seecs.edu.pk'),
('mraza.bba25nbs@nbs.edu.pk'),
('htariq.bsme24smme@smme.edu.pk'),
('skhan.bsphy23sns@sns.edu.pk'),
('zahmed.bscs22seecs@seecs.edu.pk'),
('ofarooq.bese24seecs@seecs.edu.pk'),
('raza.ali@seecs.edu.pk'),
('nadia.rehman@seecs.edu.pk'),
('usman.majeed@seecs.edu.pk'),
('ayesha.siddiqui@nbs.edu.pk'),
('bilal.ahmed@smme.edu.pk'),
('sana.fatima@seecs.edu.pk'),
('salman.saeed@seecs.edu.pk'),
('kamran.javed@nbs.edu.pk'),
('fatima.malik@sns.edu.pk'),
('waqas.qureshi@sns.edu.pk');
 
-- 2. User Details (using auto-generated user_ids 1-20)
INSERT INTO user_details 
(user_id, password_hash, role, phone_number, first_name, last_name)
VALUES
(1,'P@ss01','STUDENT','03001112233','Arham','Nabi'),
(2,'Mry!23','STUDENT','03332223344','Maryam','Ali'),
(3,'Al!99x','STUDENT','03213334455','Ali','Hassan'),
(4,'Kh@n44','STUDENT','03454445566','Ahmed','Khan'),
(5,'Ab00b*','STUDENT','03125556677','Abubakar','Siddiq'),
(6,'Rz@88a','STUDENT','03006667788','Mohsin','Raza'),
(7,'Trq#07','STUDENT','03337778899','Hassan','Tariq'),
(8,'Sr@123','STUDENT','03218889900','Sara','Khan'),
(9,'Zn^99z','STUDENT','03459990011','Zain','Ahmed'),
(10,'Omr$10','STUDENT','03120001122','Omar','Farooq'),
(11,'ProfRz1','PROFESSOR','03011112222','Raza','Ali'),
(12,'Ndi@22','PROFESSOR','03342223333','Nadia','Rehman'),
(13,'Usm!33','PROFESSOR','03223334444','Usman','Majeed'),
(14,'Aysh44','PROFESSOR','03464445555','Ayesha','Siddiqui'),
(15,'Bll#55','PROFESSOR','03135556666','Bilal','Ahmed'),
(16,'Sn@66x','PROFESSOR','03026667777','Sana','Fatima'),
(17,'Slmn77','PROFESSOR','03357778888','Salman','Saeed'),
(18,'Kmr^88','PROFESSOR','03238889999','Kamran','Javed'),
(19,'Ftm$99','PROFESSOR','03479990000','Fatima','Malik'),
(20,'Wqs*00','PROFESSOR','03140001111','Waqas','Qureshi');
 
-- 3. Student
INSERT INTO student (student_id, year) VALUES
(1,1),(2,3),(3,4),(4,2),(5,4),(6,1),(7,2),(8,3),(9,4),(10,2);
 
-- 4. Professor Department
INSERT INTO professor_department (professor_id, department) VALUES
(11,'Computer Science'),
(12,'Computer Science'),
(13,'Electrical Engineering'),
(14,'Business Administration'),
(15,'Mechanical Engineering'),
(16,'Computer Science'),
(17,'Electrical Engineering'),
(18,'Business Administration'),
(19,'Mathematics'),
(20,'Physics');
 
-- 5. Professor Office
INSERT INTO professor_office (professor_id, office_location) VALUES
(11,'SEECS-101'),
(12,'SEECS-102'),
(13,'SEECS-201'),
(14,'NBS-301'),
(15,'SMME-105'),
(16,'SEECS-103'),
(17,'SEECS-202'),
(18,'NBS-302'),
(19,'SNS-401'),
(20,'SNS-402');
 
-- 6. Professor Timetable 
INSERT INTO professor_timetable (professor_id) VALUES
(11),(11),(12),(12),(13),(14),(15),(16),(17),(18);
 
-- 7. Timetable
INSERT INTO timetable (timetable_id, day, start_time, end_time, is_busy) VALUES
(1,'Monday','09:00:00','10:00:00',TRUE),
(2,'Tuesday','13:00:00','14:00:00',TRUE),
(3,'Monday','10:00:00','11:00:00',TRUE),
(4,'Wednesday','08:00:00','09:00:00',TRUE),
(5,'Thursday','11:00:00','12:00:00',TRUE),
(6,'Friday','09:00:00','12:00:00',TRUE),
(7,'Monday','14:00:00','16:00:00',TRUE),
(8,'Tuesday','09:00:00','11:00:00',TRUE),
(9,'Wednesday','14:00:00','15:00:00',TRUE),
(10,'Thursday','10:00:00','12:00:00',TRUE);
 
-- 8. Timeslot 
INSERT INTO timeslot 
(slot_date, professor_id, start_time, end_time, status, reserved_count, current_bookings, max_capacity, is_manually_blocked_by_prof)
VALUES
('2026-04-20',11,'11:00:00','11:30:00','PARTIALLY_BOOKED',0,1,3,FALSE),
('2026-04-20',11,'11:30:00','12:00:00','LOCKED',0,3,3,FALSE),
('2026-04-21',11,'14:00:00','14:30:00','FREE',0,0,3,FALSE),
('2026-04-20',12,'11:00:00','11:30:00','FREE',0,0,3,FALSE),
('2026-04-21',12,'14:00:00','14:30:00','PARTIALLY_BOOKED',0,0,3,FALSE),
('2026-04-21',11,'10:00:00','10:30:00','FROZEN',0,1,3,FALSE),
('2026-04-22',12,'09:00:00','09:30:00','CANCELLED',0,0,3,FALSE),
('2026-04-22',12,'09:30:00','10:00:00','PARTIALLY_BOOKED',0,2,3,FALSE),
('2026-04-22',11,'11:00:00','11:30:00','LOCKED',0,3,3,FALSE),
('2026-04-22',11,'11:30:00','12:00:00','FREE',0,0,3,FALSE),
('2026-04-23',12,'10:00:00','10:30:00','FREE',0,0,3,FALSE),
('2026-04-26',12,'09:00:00','09:30:00','LOCKED',0,3,3,FALSE),
('2026-04-26',12,'10:00:00','10:30:00','CANCELLED',0,0,3,FALSE),
('2026-04-26',12,'10:30:00','11:00:00','FROZEN',0,1,3,FALSE),
('2026-04-26',12,'11:00:00','11:30:00','PARTIALLY_BOOKED',1,1,3,FALSE),
('2026-04-26',12,'11:30:00','12:00:00','PARTIALLY_BOOKED',0,1,3,FALSE);
 
-- 9. Student Appointment 
INSERT INTO student_appointment (student_id, slot_id) VALUES
(3,1),(8,2),(9,2),(10,2),(7,4),
(3,7),(3,8),(2,8),(5,8),(6,6),
(1,6),(4,4),(2,2),(5,2),(6,2),
(3,9),(8,9),(9,9),(10,9),(4,9),
(1,9),(6,3),

(1,12),(2,12),(3,12),(4,12),
(5,13),(6,13),(8,14),(9,15),
(5,15),(6,16);
 
-- 10. Appointment Details
INSERT INTO appointment_details 
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from) 
VALUES
(1,'APPROVED','COURSE_REGISTRATION',NULL,NULL,'2026-04-18 09:00:00',NULL),
(2,'APPROVED','THESIS_FYP',NULL,NULL,'2026-04-18 09:05:00',NULL),
(3,'APPROVED','PAPER_RECHECK',NULL,NULL,'2026-04-18 09:10:00',NULL),
(4,'APPROVED','RECOMMENDATION_LETTER',NULL,NULL,'2026-04-18 09:15:00',NULL),
(5,'REJECTED','GENERAL_ADVICE','Sir, I have been rejected twice. This is regarding my thesis topic selection which is time-sensitive as the deadline is approaching. Please consider this request.','Please attend next week','2026-04-18 09:20:00',NULL),
(6,'CANCELLED','GENERAL_ADVICE',NULL,NULL,'2026-04-18 09:25:00',NULL),
(7,'PENDING','GENERAL_ADVICE',NULL,NULL,'2026-04-18 10:00:00',6),
(8,'RESERVED','GENERAL_ADVICE',NULL,NULL,'2026-04-18 10:15:00',NULL),
(9,'RESERVED','GENERAL_ADVICE',NULL,NULL,'2026-04-18 10:20:00',NULL),
(10,'PENDING','GENERAL_ADVICE',NULL,NULL,'2026-04-18 10:30:00',NULL),
(11,'APPROVED','COURSE_REGISTRATION',NULL,NULL,'2026-04-18 10:35:00',NULL),
(12,'REJECTED','ATTENDANCE_SHORTAGE',NULL,NULL,'2026-04-18 10:40:00',NULL),
(13,'WAITLISTED','THESIS_FYP',NULL,NULL,'2026-04-18 09:30:00',NULL),
(14,'WAITLISTED','GENERAL_ADVICE',NULL,NULL,'2026-04-18 09:25:00',NULL),
(15,'WAITLISTED','CLEARANCE',NULL,NULL,'2026-04-18 09:40:00',NULL),
(16,'WAITLISTED','PAPER_RECHECK',NULL,NULL,'2026-04-18 08:00:00',NULL),
(17,'WAITLISTED','GRADE_APPEAL',NULL,NULL,'2026-04-18 08:05:00',NULL),
(18,'WAITLISTED','THESIS_FYP',NULL,NULL,'2026-04-18 08:10:00',NULL),
(19,'WAITLISTED','ATTENDANCE_SHORTAGE',NULL,NULL,'2026-04-18 08:15:00',NULL),
(20,'WAITLISTED','COURSE_REGISTRATION',NULL,NULL,'2026-04-18 08:20:00',NULL),
(21,'WAITLISTED','PAPER_RECHECK',NULL,NULL,'2026-04-18 08:25:00',NULL),
(22,'WAITLISTED','CLEARANCE',NULL,NULL,'2026-04-18 09:45:00',NULL),
(23,'CANCELLED','GENERAL_ADVICE',NULL,NULL,'2026-04-25 08:00:00',NULL),
(24,'APPROVED','GENERAL_ADVICE',NULL,NULL,'2026-04-25 08:05:00',NULL),
(25,'APPROVED','GENERAL_ADVICE',NULL,NULL,'2026-04-25 08:10:00',NULL),
(26,'APPROVED','CLEARANCE',NULL,NULL,'2026-04-25 08:15:00',NULL),
(27,'CANCELLED','PAPER_RECHECK',NULL,NULL,'2026-04-25 09:00:00',NULL),
(28,'CANCELLED','PAPER_RECHECK',NULL,NULL,'2026-04-25 09:05:00',NULL),
(29,'PENDING','THESIS_FYP',NULL,NULL,'2026-04-25 10:00:00',NULL),
(30,'APPROVED','GENERAL_ADVICE',NULL,NULL,'2026-04-25 10:00:00',NULL),
(31,'RESERVED','PAPER_RECHECK',NULL,NULL,'2026-04-25 12:00:00',NULL),
(32,'APPROVED','PAPER_RECHECK',NULL,NULL,'2026-04-25 12:05:00',NULL);
 
-- 11. Waitlisted Student
INSERT INTO waitlisted_student (student_id) VALUES
(2),(5),(6),(3),(8),(9),(10),(4),(1),(6),(7);
 
-- 12. Waitlist Details 
INSERT INTO waitlist_details 
(waitlist_id, priority_score, joined_at, slot_id) 
VALUES
(1,85,'2026-04-18 09:30:00',2),
(2,60,'2026-04-18 09:25:00',2),
(3,95,'2026-04-18 09:40:00',2),
(4,90,'2026-04-18 08:00:00',9),
(5,75,'2026-04-18 08:05:00',9),
(6,80,'2026-04-18 08:10:00',9),
(7,70,'2026-04-18 08:15:00',9),
(8,65,'2026-04-18 08:20:00',9),
(9,100,'2026-04-18 08:25:00',9),
(10,95,'2026-04-18 09:45:00',3),
(11,60,'2026-04-25 08:20:00',12);
 
