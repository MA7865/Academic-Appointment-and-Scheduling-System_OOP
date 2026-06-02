-- ============================================================
-- EXTENDED DUMMY DATA — Appointment System Audit History
-- Builds on existing data (timeslots 1–16, appointments 1–32)
-- Generated: 2026-04-27
-- ============================================================
-- Scenarios covered:
--   A. Rescheduling chain  (cancelled → re-booked → cancelled → re-booked)
--   B. Waitlist → promoted → APPROVED  (student cancels, top waitlister auto-promoted)
--   C. Rejected → re-applies to different slot (same professor)
--   D. Professor cancels slot → RESERVED offers → one APPROVED, one expires
--   E. Student cancels then re-books same professor
--   F. Slot progression FREE → PARTIALLY_BOOKED → FROZEN mid-review
--   G. Professor manually blocks a slot
-- ============================================================

USE appointment_system;

-- ============================================================
-- NEW TIMESLOTS  (IDs 17–28)
-- ============================================================

INSERT INTO timeslot
(slot_id, slot_date, professor_id, start_time, end_time, status,
 reserved_count, current_bookings, max_capacity, is_manually_blocked_by_prof)
VALUES

-- CASE A: Rescheduling chain slots (prof 11)
(17, '2026-04-28', 11, '09:00:00', '09:30:00', 'PARTIALLY_BOOKED', 0, 1, 3, FALSE),
-- slot 18: the intermediate reschedule target (now cancelled by student again)
(18, '2026-04-30', 11, '09:00:00', '09:30:00', 'FREE',             0, 0, 3, FALSE),
-- slot 19: final reschedule landing slot
(19, '2026-05-01', 11, '09:00:00', '09:30:00', 'PARTIALLY_BOOKED', 0, 1, 3, FALSE),

-- CASE B: Waitlist promotion (prof 12) — ends LOCKED after promotion fills it back to 3
(20, '2026-04-29', 12, '11:00:00', '11:30:00', 'LOCKED',           0, 3, 3, FALSE),

-- CASE C: Rejected then re-applies (prof 13)
(21, '2026-04-29', 13, '10:00:00', '10:30:00', 'PARTIALLY_BOOKED', 0, 1, 3, FALSE),
(22, '2026-04-29', 13, '10:30:00', '11:00:00', 'PARTIALLY_BOOKED', 0, 2, 3, FALSE),

-- CASE D: Prof cancels slot → cascade → reserved offers
(23, '2026-05-01', 11, '11:00:00', '11:30:00', 'CANCELLED',        0, 0, 3, FALSE),
-- Alternative slots offered to displaced students
(24, '2026-05-02', 11, '09:00:00', '09:30:00', 'PARTIALLY_BOOKED', 0, 1, 3, FALSE),
(25, '2026-05-02', 11, '09:30:00', '10:00:00', 'FREE',             0, 0, 3, FALSE),

-- CASE E: Student cancels then re-books same professor (prof 12)
(26, '2026-05-02', 12, '14:00:00', '14:30:00', 'PARTIALLY_BOOKED', 0, 1, 3, FALSE),

-- CASE F: FREE → PARTIALLY_BOOKED → FROZEN mid-review (prof 11)
(27, '2026-05-03', 11, '10:00:00', '10:30:00', 'FROZEN',           0, 2, 3, FALSE),

-- CASE G: Manually blocked slot (prof 12) — never bookable
(28, '2026-05-03', 12, '09:00:00', '09:30:00', 'LOCKED',           0, 0, 3, TRUE);


-- ============================================================
-- CASE A — RESCHEDULING CHAIN
-- student 3 (Ali Hassan, Year 4) books prof 11 for PAPER_RECHECK
-- Chain: appt 33 (original APPROVED) 
--        → appt 34 (CANCELLED, reschedule triggered)      [rescheduled_from = NULL, this is the root]
--        → appt 35 (PENDING on slot 18, rescheduled_from = 33)
--        → appt 36 (CANCELLED again)
--        → appt 37 (PENDING on slot 19, rescheduled_from = 35) — final active booking
-- Timeline: Apr 20 original → Apr 28 first reschedule → Apr 30 second try → May 1 final
-- ============================================================

-- Step 1: student 3 books slot 17 (Apr 28)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(33, 3, 17);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(33, 'APPROVED', 'PAPER_RECHECK',
 'I would like to discuss my mid-term paper recheck.',
 NULL, '2026-04-25 10:00:00', NULL);

-- Step 2: student 3 reschedules → slot 17 appt CANCELLED, new PENDING on slot 18
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(34, 3, 17);  -- cancellation record for the original slot 17 booking

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(34, 'CANCELLED', 'PAPER_RECHECK',
 'Student rescheduled to a later date.',
 NULL, '2026-04-27 09:00:00', NULL);

-- New booking on slot 18 (Apr 30), referencing the cancelled appt 33 as origin
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(35, 3, 18);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(35, 'CANCELLED', 'PAPER_RECHECK',
 'Student rescheduled again due to clash.',
 NULL, '2026-04-27 09:05:00', 33);

-- Step 3: student 3 reschedules again → slot 18 appt CANCELLED, new PENDING on slot 19
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(36, 3, 19);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(36, 'PENDING', 'PAPER_RECHECK',
 'Final reschedule — requesting May 1 slot.',
 NULL, '2026-04-27 11:00:00', 35);


-- ============================================================
-- CASE B — WAITLIST → AUTO-PROMOTION → APPROVED
-- slot 20 (Apr 29, prof 12): 3 students approved → LOCKED
-- student 1 cancels → slot drops to PARTIALLY_BOOKED
-- top waitlisted student (student 5, priority 90, final year) auto-promoted → APPROVED
-- slot returns to LOCKED
-- ============================================================

-- Three students originally fill slot 20 to capacity
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(37, 1, 20),
(38, 2, 20),
(39, 4, 20);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(37, 'CANCELLED', 'GENERAL_ADVICE',
 NULL,
 NULL, '2026-04-26 08:00:00', NULL),   -- student 1 cancels their confirmed spot

(38, 'APPROVED', 'THESIS_FYP',
 'Regarding FYP topic finalisation.',
 NULL, '2026-04-26 08:05:00', NULL),

(39, 'APPROVED', 'COURSE_REGISTRATION',
 'Need help with elective selection.',
 NULL, '2026-04-26 08:10:00', NULL);

-- Two students on the waitlist for slot 20
-- student 5: Year 4 → FINAL_YEAR priority → score 90
-- student 7: Year 2 → NORMAL priority → score 60
INSERT INTO waitlisted_student (waitlist_id, student_id) VALUES
(12, 5),
(13, 7);

INSERT INTO waitlist_details (waitlist_id, priority_score, joined_at, slot_id) VALUES
(12, 90, '2026-04-26 09:00:00', 20),
(13, 60, '2026-04-26 09:05:00', 20);

-- student 1 cancels (appt 37 already CANCELLED above)
-- System auto-promotes student 5 (highest priority on waitlist)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(40, 5, 20);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(40, 'APPROVED', 'CLEARANCE',
 'Auto-promoted from waitlist after student 1 cancellation.',
 NULL, '2026-04-26 09:30:00', NULL);

-- Note: slot 20 is back to LOCKED (current_bookings = 3: appts 38, 39, 40)
-- waitlist entries 12 and 13 would be cleaned up; 13 (student 7) remains pending removal
-- For audit purposes we keep them; a real trigger would delete waitlist_id 12


-- ============================================================
-- CASE C — REJECTED → RE-APPLIES TO DIFFERENT SLOT (same professor 13)
-- student 6 (Mohsin Raza, Year 1) rejected on slot 21
-- Barred from slot 21 permanently
-- Re-applies on slot 22 (same professor, different time) → APPROVED
-- ============================================================

-- student 6 books slot 21 (Apr 29, prof 13, 10:00–10:30)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(41, 6, 21);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(41, 'REJECTED', 'GRADE_APPEAL',
 'Requesting discussion on mid-term grade.',
 'Please bring your exam paper and attend during designated office hours instead.',
 '2026-04-27 10:00:00', NULL);

-- student 6 re-applies on slot 22 (same prof 13, 10:30–11:00) — different slot, allowed
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(42, 6, 22);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(42, 'APPROVED', 'GRADE_APPEAL',
 'Following up on grade appeal — paper now in hand.',
 NULL, '2026-04-27 11:30:00', NULL);

-- One more student on slot 21 (to make it PARTIALLY_BOOKED as per slot status)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(43, 9, 21);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(43, 'APPROVED', 'THESIS_FYP',
 'FYP milestone review.',
 NULL, '2026-04-27 10:30:00', NULL);

-- Another student on slot 22 to reach current_bookings=2
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(44, 8, 22);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(44, 'APPROVED', 'ATTENDANCE_SHORTAGE',
 'Attendance shortage discussion.',
 NULL, '2026-04-27 10:45:00', NULL);


-- ============================================================
-- CASE D — PROFESSOR CANCELS SLOT → CASCADE → RESERVED OFFERS
-- slot 23 (May 1, prof 11): 2 students APPROVED → prof cancels entire slot
-- Both appointments cascade to CANCELLED
-- System finds slots 24 and 25 as alternatives
-- student 8: offered slot 24 → RESERVED → accepts → APPROVED
-- student 9: offered slot 25 → RESERVED → does NOT respond in 24h → expires (CANCELLED)
-- ============================================================

-- Original approved appointments on slot 23 (before cancellation)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(45, 8, 23),
(46, 9, 23);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(45, 'CANCELLED', 'RECOMMENDATION_LETTER',
 'Professor cancelled the entire slot.',
 NULL, '2026-04-28 09:00:00', NULL),

(46, 'CANCELLED', 'THESIS_FYP',
 'Professor cancelled the entire slot.',
 NULL, '2026-04-28 09:05:00', NULL);

-- System offers student 8 → slot 24 (RESERVED, reserved_count incremented to 1 in slot table)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(47, 8, 24);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(47, 'APPROVED', 'RECOMMENDATION_LETTER',
 'Slot reserved after professor cancelled slot 23. Student accepted within 24h.',
 NULL, '2026-04-28 10:00:00', 45);
-- Note: slot 24 reserved_count goes 1→0, current_bookings goes 0→1 on acceptance.
-- Final state of slot 24 already reflects this: current_bookings=1, reserved_count=0.

-- System offers student 9 → slot 25 (RESERVED, but student never responds → expires)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(48, 9, 25);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(48, 'CANCELLED', 'THESIS_FYP',
 'Reserved slot offer expired — student did not respond within 24 hours. Hold released.',
 NULL, '2026-04-29 10:00:00', 46);
-- Note: slot 25 reserved_count returns to 0 after expiry. Slot stays FREE (no bookings).


-- ============================================================
-- CASE E — STUDENT CANCELS THEN RE-BOOKS SAME PROFESSOR
-- student 10 (Omar Farooq, Year 2) books prof 12, slot 26 (May 2)
-- Gets approved, then cancels
-- No waitlist on slot 26 → no promotion needed
-- student 10 re-books the same slot again → new PENDING → APPROVED
-- ============================================================

-- First booking
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(49, 10, 26);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(49, 'CANCELLED', 'GENERAL_ADVICE',
 'Student voluntarily cancelled confirmed appointment.',
 NULL, '2026-04-28 14:00:00', NULL);

-- Re-booking of same slot by same student (allowed since the slot is free again and
-- no time-window conflict with other approved appointments)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(50, 10, 26);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(50, 'APPROVED', 'GENERAL_ADVICE',
 'Re-booked after earlier cancellation.',
 NULL, '2026-04-29 09:00:00', NULL);


-- ============================================================
-- CASE F — SLOT PROGRESSION: FREE → PARTIALLY_BOOKED → FROZEN
-- slot 27 (May 3, prof 11, 10:00–10:30)
-- student 2 and student 4 book → APPROVED (current_bookings = 2)
-- student 7 books → PENDING
-- Professor freezes slot mid-review (status = FROZEN in timeslot table)
-- No new bookings accepted; student 7 stays PENDING awaiting decision
-- ============================================================

INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(51, 2, 27),
(52, 4, 27),
(53, 7, 27);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(51, 'APPROVED', 'PAPER_RECHECK',
 'Mid-term paper recheck.',
 NULL, '2026-04-29 10:00:00', NULL),

(52, 'APPROVED', 'COURSE_REGISTRATION',
 'Elective registration query.',
 NULL, '2026-04-29 10:05:00', NULL),

(53, 'PENDING', 'GENERAL_ADVICE',
 'General academic guidance request — awaiting professor review.',
 NULL, '2026-04-29 10:10:00', NULL);

-- Slot 27 is now FROZEN (professor froze it mid-review after 2 approvals)
-- Status already set to FROZEN in the timeslot INSERT above.
-- Student 7's appointment (53) stays PENDING — still reviewable by prof.
-- No new students can book slot 27 while FROZEN.


-- ============================================================
-- CASE G — PROFESSOR MANUALLY BLOCKS A SLOT
-- slot 28 (May 3, prof 12): is_manually_blocked_by_prof = TRUE, status = LOCKED
-- No student appointments exist — this slot was never visible for booking.
-- Included to demonstrate the manual block audit trail.
-- ============================================================

-- No student_appointment or appointment_details rows needed.
-- The timeslot INSERT above (slot_id=28) fully captures this case.
-- Any query checking "why is this slot locked?" sees is_manually_blocked_by_prof = TRUE.


-- ============================================================
-- SUMMARY OF FINAL SLOT STATES (for reference)
-- ============================================================
-- slot 17: PARTIALLY_BOOKED | bookings=1 | appt 33(APPROVED), 34(CANCELLED)
-- slot 18: FREE             | bookings=0 | appt 35(CANCELLED)
-- slot 19: PARTIALLY_BOOKED | bookings=1 | appt 36(PENDING)
-- slot 20: LOCKED           | bookings=3 | appts 37(CANCELLED),38(APPROVED),39(APPROVED),40(APPROVED)
-- slot 21: PARTIALLY_BOOKED | bookings=1 | appts 41(REJECTED),43(APPROVED)
-- slot 22: PARTIALLY_BOOKED | bookings=2 | appts 42(APPROVED),44(APPROVED)
-- slot 23: CANCELLED        | bookings=0 | appts 45(CANCELLED),46(CANCELLED)
-- slot 24: PARTIALLY_BOOKED | bookings=1 | appt 47(APPROVED) — reserved→accepted
-- slot 25: FREE             | bookings=0 | appt 48(CANCELLED) — reserved expired
-- slot 26: PARTIALLY_BOOKED | bookings=1 | appts 49(CANCELLED),50(APPROVED)
-- slot 27: FROZEN           | bookings=2 | appts 51,52(APPROVED), 53(PENDING)
-- slot 28: LOCKED           | bookings=0 | no appointments (manually blocked)
-- ============================================================

-- ============================================================
-- AUDIT HISTORY OVERVIEW
-- ============================================================
-- RESCHEDULING CHAIN (student 3):
--   appt 33 (APPROVED, slot 17, Apr 28)
--   → appt 34 (CANCELLED, slot 17)           [student reschedules]
--   → appt 35 (CANCELLED, slot 18, Apr 30, rescheduled_from=33) [reschedules again]
--   → appt 36 (PENDING,   slot 19, May 1,  rescheduled_from=35) [final booking]
--
-- WAITLIST PROMOTION (student 5):
--   appt 37 (student 1, CANCELLED, slot 20) → auto-promotion triggered
--   appt 40 (student 5, APPROVED,  slot 20) ← promoted from waitlist (waitlist_id 12)
--
-- REJECTION + RE-APPLICATION (student 6):
--   appt 41 (REJECTED, slot 21, reason saved) → barred from slot 21
--   appt 42 (APPROVED, slot 22)               ← new slot, same prof, allowed
--
-- SLOT CANCELLATION CASCADE (students 8 & 9):
--   appts 45,46 (CANCELLED) ← professor cancels slot 23
--   appt 47 (APPROVED)      ← student 8 accepts reserved offer on slot 24
--   appt 48 (CANCELLED)     ← student 9 reserved offer on slot 25 expires after 24h
--
-- CANCEL + RE-BOOK (student 10):
--   appt 49 (CANCELLED, slot 26)
--   appt 50 (APPROVED,  slot 26) ← same slot, same prof, fresh booking
--
-- FROZEN SLOT (slot 27, prof 11):
--   appts 51,52 (APPROVED) → prof freezes slot after 2 approvals
--   appt 53     (PENDING)  → student 7 awaiting decision, no new bookings allowed
-- ============================================================




-- ============================================================
-- EXTENDED DUMMY DATA — Professors 13–20 + 10 New Students
-- Builds on existing data (slots 1–28, appointments 1–53)
-- Generated: 2026-04-27
-- ============================================================
-- Scenarios per professor:
--   Prof 13 — Full waitlist (6 students) + auto-promotion on cancellation
--   Prof 14 — Realistic mix: APPROVED, REJECTED, PENDING across slots
--   Prof 15 — Rejection + re-apply different slot + reschedule chain
--   Prof 16 — Manual block slot + normal bookings
--   Prof 17 — FROZEN slot mid-review
--   Prof 18 — Professor cancels slot → cascade → RESERVED → both accepted
--   Prof 19 — Fresh simple bookings (newly onboarded professor)
--   Prof 20 — Reschedule chain after slot cancellation + waitlist
-- ============================================================

USE appointment_system;


-- ============================================================
-- SECTION 1: NEW STUDENTS (user IDs 21–30)
-- ============================================================

-- 1a. user_email
INSERT INTO user_email (user_id, email) VALUES
(21, 'hamza.malik.bscs24seecs@seecs.edu.pk'),
(22, 'amna.siddiqui.bba25nbs@nbs.edu.pk'),
(23, 'bilal.yousaf.bsme23smme@smme.edu.pk'),
(24, 'zara.ahmed.bsphy22sns@sns.edu.pk'),
(25, 'usman.tariq.bscs24seecs@seecs.edu.pk'),
(26, 'hira.khan.bscs23seecs@seecs.edu.pk'),
(27, 'saad.raza.bba25nbs@nbs.edu.pk'),
(28, 'noor.fatima.bsmath22sns@sns.edu.pk'),
(29, 'kamran.ali.bsme23smme@smme.edu.pk'),
(30, 'eman.sheikh.bscs24seecs@seecs.edu.pk');

-- 1b. user_details
INSERT INTO user_details (user_id, password_hash, role, phone_number, first_name, last_name) VALUES
(21, 'Hmz!21a', 'STUDENT', '03011223344', 'Hamza',  'Malik'),
(22, 'Amn@22b', 'STUDENT', '03342334455', 'Amna',   'Siddiqui'),
(23, 'Bly#23c', 'STUDENT', '03223445566', 'Bilal',  'Yousaf'),
(24, 'Zr@24dx', 'STUDENT', '03464556677', 'Zara',   'Ahmed'),
(25, 'Usm$25e', 'STUDENT', '03135667788', 'Usman',  'Tariq'),
(26, 'Hr@26fy', 'STUDENT', '03026778899', 'Hira',   'Khan'),
(27, 'Sd!27gz', 'STUDENT', '03357889900', 'Saad',   'Raza'),
(28, 'Nr^28ha', 'STUDENT', '03238990011', 'Noor',   'Fatima'),
(29, 'Km*29ib', 'STUDENT', '03479001122', 'Kamran', 'Ali'),
(30, 'Em@30jc', 'STUDENT', '03140112233', 'Eman',   'Sheikh');

-- 1c. student (year reflects seniority used for waitlist priority)
-- Year 4 = Final Year (high priority), Year 1–3 = Normal
INSERT INTO student (student_id, year) VALUES
(21, 2),   -- Hamza   — normal
(22, 1),   -- Amna    — normal (year 1)
(23, 3),   -- Bilal   — normal
(24, 4),   -- Zara    — FINAL YEAR → high waitlist priority
(25, 2),   -- Usman   — normal
(26, 3),   -- Hira    — normal
(27, 1),   -- Saad    — normal (year 1)
(28, 4),   -- Noor    — FINAL YEAR → high waitlist priority
(29, 3),   -- Kamran  — normal
(30, 2);   -- Eman    — normal


-- ============================================================
-- SECTION 2: PROFESSOR TIMETABLE ENTRIES (IDs 11–20)
-- Profs 13–18 each get a second timetable entry.
-- Profs 19–20 get their first two entries (had none before).
-- ============================================================

INSERT INTO professor_timetable (timetable_id, professor_id) VALUES
(11, 13),   -- second slot block for prof 13
(12, 14),   -- second slot block for prof 14
(13, 15),   -- second slot block for prof 15
(14, 16),   -- second slot block for prof 16
(15, 17),   -- second slot block for prof 17
(16, 18),   -- second slot block for prof 18
(17, 19),   -- first entry for prof 19
(18, 19),   -- second entry for prof 19
(19, 20),   -- first entry for prof 20
(20, 20);   -- second entry for prof 20


-- ============================================================
-- SECTION 3: TIMETABLE (busy blocks, IDs 11–20)
-- ============================================================

INSERT INTO timetable (timetable_id, day, start_time, end_time, is_busy) VALUES
(11, 'Wednesday', '10:00:00', '11:00:00', TRUE),  -- prof 13
(12, 'Monday',    '09:00:00', '10:00:00', TRUE),  -- prof 14
(13, 'Tuesday',   '11:00:00', '12:00:00', TRUE),  -- prof 15
(14, 'Wednesday', '13:00:00', '14:00:00', TRUE),  -- prof 16
(15, 'Thursday',  '09:00:00', '10:00:00', TRUE),  -- prof 17
(16, 'Friday',    '10:00:00', '11:00:00', TRUE),  -- prof 18
(17, 'Monday',    '11:00:00', '12:00:00', TRUE),  -- prof 19
(18, 'Wednesday', '14:00:00', '15:00:00', TRUE),  -- prof 19
(19, 'Tuesday',   '09:00:00', '10:00:00', TRUE),  -- prof 20
(20, 'Thursday',  '13:00:00', '14:00:00', TRUE);  -- prof 20


-- ============================================================
-- SECTION 4: TIMESLOTS (IDs 29–50)
-- Auto-generated free windows around professor busy blocks
-- ============================================================

INSERT INTO timeslot
(slot_id, slot_date, professor_id, start_time, end_time, status,
 reserved_count, current_bookings, max_capacity, is_manually_blocked_by_prof)
VALUES

-- PROF 13 — Usman Majeed (Electrical Engineering)
-- Scenario: Full waitlist + auto-promotion
(29, '2026-04-10', 13, '11:00:00', '11:30:00', 'LOCKED',           0, 3, 3, FALSE),
(30, '2026-04-14', 13, '11:30:00', '12:00:00', 'PARTIALLY_BOOKED', 0, 2, 3, FALSE),

-- PROF 14 — Ayesha Siddiqui (Business Administration)
-- Scenario: Realistic mix of statuses across three dates
(31, '2026-04-15', 14, '09:00:00', '09:30:00', 'LOCKED',           0, 3, 3, FALSE),
(32, '2026-04-22', 14, '09:30:00', '10:00:00', 'PARTIALLY_BOOKED', 0, 1, 3, FALSE),
(33, '2026-05-05', 14, '09:00:00', '09:30:00', 'FREE',             0, 0, 3, FALSE),

-- PROF 15 — Bilal Ahmed (Mechanical Engineering)
-- Scenario: Rejection + re-apply different slot + reschedule chain
(34, '2026-04-08', 15, '11:00:00', '11:30:00', 'PARTIALLY_BOOKED', 0, 1, 3, FALSE),
(35, '2026-04-09', 15, '11:00:00', '11:30:00', 'LOCKED',           0, 3, 3, FALSE),
(36, '2026-05-06', 15, '11:30:00', '12:00:00', 'PARTIALLY_BOOKED', 0, 1, 3, FALSE),

-- PROF 16 — Sana Fatima (Computer Science)
-- Scenario: Normal bookings + one manually blocked future slot
(37, '2026-04-16', 16, '13:00:00', '13:30:00', 'PARTIALLY_BOOKED', 0, 2, 3, FALSE),
(38, '2026-04-17', 16, '13:30:00', '14:00:00', 'LOCKED',           0, 3, 3, FALSE),
(39, '2026-05-07', 16, '13:00:00', '13:30:00', 'LOCKED',           0, 0, 3, TRUE),

-- PROF 17 — Salman Saeed (Electrical Engineering)
-- Scenario: FROZEN mid-review + fresh future slot
(40, '2026-04-21', 17, '09:00:00', '09:30:00', 'FROZEN',           0, 2, 3, FALSE),
(41, '2026-05-08', 17, '09:30:00', '10:00:00', 'FREE',             0, 0, 3, FALSE),

-- PROF 18 — Kamran Javed (Business Administration)
-- Scenario: Slot cancelled → cascade → RESERVED offers → both accepted
(42, '2026-04-23', 18, '10:00:00', '10:30:00', 'CANCELLED',        0, 0, 3, FALSE),
(43, '2026-04-28', 18, '10:00:00', '10:30:00', 'PARTIALLY_BOOKED', 0, 2, 3, FALSE),
(44, '2026-05-09', 18, '10:30:00', '11:00:00', 'PARTIALLY_BOOKED', 0, 1, 3, FALSE),

-- PROF 19 — Fatima Malik (Mathematics)
-- Scenario: Simple fresh bookings, newly active professor
(45, '2026-05-05', 19, '11:00:00', '11:30:00', 'PARTIALLY_BOOKED', 0, 1, 3, FALSE),
(46, '2026-05-06', 19, '11:30:00', '12:00:00', 'PARTIALLY_BOOKED', 0, 1, 3, FALSE),
(47, '2026-05-07', 19, '11:00:00', '11:30:00', 'FREE',             0, 0, 3, FALSE),

-- PROF 20 — Waqas Qureshi (Physics)
-- Scenario: Slot cancellation → reschedule chain + waitlist
(48, '2026-04-12', 20, '09:00:00', '09:30:00', 'CANCELLED',        0, 0, 3, FALSE),
(49, '2026-04-19', 20, '09:00:00', '09:30:00', 'LOCKED',           0, 3, 3, FALSE),
(50, '2026-05-10', 20, '09:30:00', '10:00:00', 'FREE',             0, 0, 3, FALSE);


-- ============================================================
-- SECTION 5: SCENARIOS
-- ============================================================


-- ------------------------------------------------------------
-- PROF 13 — FULL WAITLIST (6 students) + AUTO-PROMOTION
-- slot 29 (Apr 10): 3 approved → LOCKED
-- student 22 cancels → top-priority waitlisted student (24)
--   auto-promoted → APPROVED → slot back to LOCKED
-- slot 30 (Apr 14): 2 approved → PARTIALLY_BOOKED
-- ------------------------------------------------------------

-- Slot 29: original three approved students
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(54, 21, 29),
(55, 22, 29),
(56, 23, 29);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(54, 'APPROVED', 'CLEARANCE',
 'Requesting clearance sign-off.',
 NULL, '2026-04-07 09:00:00', NULL),

(55, 'CANCELLED', 'COURSE_REGISTRATION',
 'Student cancelled confirmed appointment.',
 NULL, '2026-04-07 09:05:00', NULL),    -- student 22 cancels → triggers promotion

(56, 'APPROVED', 'THESIS_FYP',
 'FYP progress update required.',
 NULL, '2026-04-07 09:10:00', NULL);

-- Waitlist for slot 29 — 6 students at maximum capacity
-- Priority: Final Year (year 4) > Normal; tiebreak = earlier joined_at
INSERT INTO waitlisted_student (waitlist_id, student_id) VALUES
(14, 24),   -- Zara, year 4 — top priority (earliest final-year entry)
(15, 28),   -- Noor, year 4 — tied final-year, joined later
(16, 26),   -- Hira, year 3 — normal
(17, 29),   -- Kamran, year 3 — normal, joined later
(18, 25),   -- Usman, year 2 — normal
(19, 27);   -- Saad, year 1 — lowest priority

INSERT INTO waitlist_details (waitlist_id, priority_score, joined_at, slot_id) VALUES
(14, 90, '2026-04-08 08:00:00', 29),
(15, 90, '2026-04-08 08:30:00', 29),
(16, 65, '2026-04-08 09:00:00', 29),
(17, 65, '2026-04-08 09:30:00', 29),
(18, 60, '2026-04-08 10:00:00', 29),
(19, 50, '2026-04-08 10:30:00', 29);

-- student 22 cancels (appt 55 = CANCELLED above)
-- System auto-promotes student 24 (waitlist_id 14, priority 90, earliest)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(57, 24, 29);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(57, 'APPROVED', 'CLEARANCE',
 'Auto-promoted from waitlist (priority score 90) after student 22 cancellation.',
 NULL, '2026-04-09 10:00:00', NULL);
-- slot 29: current_bookings = 3 (appts 54, 56, 57) → back to LOCKED ✓
-- waitlist_id 14 (student 24) would be removed by system; others remain

-- Slot 30 (Apr 14): normal PARTIALLY_BOOKED bookings
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(58, 30, 30),
(59, 21, 30);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(58, 'APPROVED', 'GENERAL_ADVICE',
 'Career path discussion.',
 NULL, '2026-04-12 10:00:00', NULL),

(59, 'APPROVED', 'THESIS_FYP',
 'Initial FYP topic discussion.',
 NULL, '2026-04-12 10:05:00', NULL);


-- ------------------------------------------------------------
-- PROF 14 — REALISTIC MIX: APPROVED / REJECTED / PENDING
-- slot 31 (Apr 15): 3 approved → LOCKED (past, fully reviewed)
-- slot 32 (Apr 22): 1 approved, 1 rejected, 1 pending
-- slot 33 (May 5):  1 pending (future, just submitted)
-- ------------------------------------------------------------

-- Slot 31 (Apr 15): fully booked and approved
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(60, 22, 31),
(61, 23, 31),
(62, 24, 31);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(60, 'APPROVED', 'CLEARANCE',
 'NBS clearance documentation query.',
 NULL, '2026-04-12 08:00:00', NULL),

(61, 'APPROVED', 'RECOMMENDATION_LETTER',
 'Requesting a recommendation letter for graduate school.',
 NULL, '2026-04-12 08:10:00', NULL),

(62, 'APPROVED', 'GRADE_APPEAL',
 'Mid-term grade appeal — score seems incorrect.',
 NULL, '2026-04-12 08:20:00', NULL);

-- Slot 32 (Apr 22): mixed outcome
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(63, 25, 32),
(64, 26, 32),
(65, 27, 32);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(63, 'APPROVED', 'COURSE_REGISTRATION',
 'Need guidance on elective selection for next semester.',
 NULL, '2026-04-19 09:00:00', NULL),

(64, 'REJECTED', 'ATTENDANCE_SHORTAGE',
 'I have missed several classes due to illness. Please consider.',
 'Medical certificates must be submitted to the department office first. Reapply after.',
 '2026-04-19 09:10:00', NULL),

(65, 'PENDING', 'GENERAL_ADVICE',
 'General academic guidance regarding switching tracks.',
 NULL, '2026-04-19 09:20:00', NULL);

-- Slot 33 (May 5): fresh pending submission
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(66, 28, 33);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(66, 'PENDING', 'THESIS_FYP',
 'Requesting discussion on FYP topic feasibility before submission deadline.',
 NULL, '2026-04-26 11:00:00', NULL);


-- ------------------------------------------------------------
-- PROF 15 — REJECTION + RE-APPLY + RESCHEDULE CHAIN
-- slot 34 (Apr 8):  student 29 REJECTED, student 30 APPROVED
-- slot 35 (Apr 9):  student 29 re-applies (different slot) → APPROVED
--                   + student 21 and student 25 also APPROVED → LOCKED
-- slot 36 (May 6):  student 30 reschedules from slot 34 → PENDING
-- ------------------------------------------------------------

-- Slot 34 (Apr 8)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(67, 29, 34),
(68, 30, 34);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(67, 'REJECTED', 'GRADE_APPEAL',
 'Requesting urgent review of my final exam marks.',
 'Grade appeals must be submitted formally via the department portal. Walk-in review not possible.',
 '2026-04-05 10:00:00', NULL),

(68, 'CANCELLED', 'PAPER_RECHECK',
 'Student rescheduled to a later date.',
 NULL, '2026-04-05 10:10:00', NULL);  -- appt 68 cancelled → student 30 reschedules to slot 36

-- Slot 35 (Apr 9): student 29 re-applies on a DIFFERENT slot (allowed after rejection on slot 34)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(69, 29, 35),
(70, 21, 35),
(71, 25, 35);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(69, 'APPROVED', 'GRADE_APPEAL',
 'Grade appeal — have now submitted the formal portal request as instructed.',
 NULL, '2026-04-06 09:00:00', NULL),

(70, 'APPROVED', 'COURSE_REGISTRATION',
 'Elective course registration assistance.',
 NULL, '2026-04-06 09:10:00', NULL),

(71, 'APPROVED', 'GENERAL_ADVICE',
 'Discussing internship options for year 2.',
 NULL, '2026-04-06 09:20:00', NULL);
-- slot 35: current_bookings = 3 → LOCKED ✓

-- Slot 36 (May 6): student 30 reschedule landing from slot 34 (appt 68 was cancelled)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(72, 30, 36);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(72, 'PENDING', 'PAPER_RECHECK',
 'Rescheduled from Apr 8 slot — requesting detailed paper recheck.',
 NULL, '2026-04-27 08:30:00', 68);
-- rescheduled_from = 68 (the cancelled appt on slot 34) ✓

-- slot 36 also has one other student already approved (current_bookings=1 from slot definition)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(73, 22, 36);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(73, 'APPROVED', 'ATTENDANCE_SHORTAGE',
 'Attendance percentage concern for end-of-semester.',
 NULL, '2026-04-20 10:00:00', NULL);


-- ------------------------------------------------------------
-- PROF 16 — MANUAL BLOCK + NORMAL BOOKINGS
-- slot 37 (Apr 16): 2 approved → PARTIALLY_BOOKED
-- slot 38 (Apr 17): 3 approved → LOCKED
-- slot 39 (May 7):  manually blocked — no appointments ever possible
-- ------------------------------------------------------------

-- Slot 37 (Apr 16)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(74, 22, 37),
(75, 23, 37);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(74, 'APPROVED', 'GENERAL_ADVICE',
 'Advice on specialisation tracks within CS.',
 NULL, '2026-04-13 09:00:00', NULL),

(75, 'APPROVED', 'RECOMMENDATION_LETTER',
 'Requesting a recommendation letter for an internship application.',
 NULL, '2026-04-13 09:10:00', NULL);

-- Slot 38 (Apr 17)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(76, 24, 38),
(77, 25, 38),
(78, 26, 38);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(76, 'APPROVED', 'CLEARANCE',
 'Final clearance for graduation — urgent.',
 NULL, '2026-04-14 10:00:00', NULL),

(77, 'APPROVED', 'THESIS_FYP',
 'FYP chapter one review.',
 NULL, '2026-04-14 10:10:00', NULL),

(78, 'APPROVED', 'PAPER_RECHECK',
 'Requesting recheck of quiz 3 marks.',
 NULL, '2026-04-14 10:20:00', NULL);

-- Slot 39 (May 7): is_manually_blocked_by_prof = TRUE, status = LOCKED
-- No student_appointment or appointment_details rows — slot was never bookable.


-- ------------------------------------------------------------
-- PROF 17 — FROZEN SLOT MID-REVIEW
-- slot 40 (Apr 21): 2 approved, professor freezes, student 29 PENDING
-- slot 41 (May 8):  fresh future slot, one PENDING submission
-- ------------------------------------------------------------

-- Slot 40 (Apr 21): FROZEN
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(79, 27, 40),
(80, 28, 40),
(81, 29, 40);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(79, 'APPROVED', 'COURSE_REGISTRATION',
 'Assistance with elective registration for semester 6.',
 NULL, '2026-04-18 08:00:00', NULL),

(80, 'APPROVED', 'ATTENDANCE_SHORTAGE',
 'Attendance dropped below threshold — need professor sign-off.',
 NULL, '2026-04-18 08:10:00', NULL),

(81, 'PENDING', 'GENERAL_ADVICE',
 'Requesting general academic advice — awaiting review.',
 NULL, '2026-04-18 08:20:00', NULL);
-- Professor froze slot 40 after approving 2. Student 29 (appt 81) stays PENDING.
-- No new bookings accepted. Slot status already FROZEN in timeslot table.

-- Slot 41 (May 8): future, just one submission
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(82, 30, 41);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(82, 'PENDING', 'THESIS_FYP',
 'Requesting guidance on FYP milestone timeline.',
 NULL, '2026-04-26 14:00:00', NULL);


-- ------------------------------------------------------------
-- PROF 18 — PROFESSOR CANCELS SLOT → CASCADE → RESERVED → BOTH ACCEPTED
-- slot 42 (Apr 23): 2 approved → professor cancels entire slot
-- Both appts cascade to CANCELLED
-- System finds slots 43 and 44 as alternatives
-- student 21 → offered slot 43 → accepts → APPROVED
-- student 22 → offered slot 44 → accepts → APPROVED
-- Both slots also have one additional organic booking each
-- ------------------------------------------------------------

-- Slot 42 (Apr 23): original approved appointments before cancellation
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(83, 21, 42),
(84, 22, 42);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(83, 'CANCELLED', 'CLEARANCE',
 'Professor cancelled the entire slot.',
 NULL, '2026-04-20 09:00:00', NULL),

(84, 'CANCELLED', 'PAPER_RECHECK',
 'Professor cancelled the entire slot.',
 NULL, '2026-04-20 09:05:00', NULL);

-- System offers student 21 → slot 43 (RESERVED → accepted within 24h → APPROVED)
-- reserved_count went 1→0, current_bookings went 1→2 after acceptance
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(85, 21, 43);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(85, 'APPROVED', 'CLEARANCE',
 'Reserved slot offered after professor cancelled slot 42. Student accepted within 24h.',
 NULL, '2026-04-23 11:00:00', 83);

-- System offers student 22 → slot 44 (RESERVED → accepted → APPROVED)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(86, 22, 44);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(86, 'APPROVED', 'PAPER_RECHECK',
 'Reserved slot offered after professor cancelled slot 42. Student accepted within 24h.',
 NULL, '2026-04-23 11:30:00', 84);

-- Additional organic bookings on slots 43 and 44 (from other students, pre-existing)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(87, 23, 43);   -- slot 43: current_bookings=2 (appts 85 + 87) ✓

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(87, 'APPROVED', 'GENERAL_ADVICE',
 'Discussion on research opportunities in business analytics.',
 NULL, '2026-04-25 10:00:00', NULL);

-- slot 44 already has current_bookings=1 (appt 86) ✓ — no more needed


-- ------------------------------------------------------------
-- PROF 19 — FRESH SIMPLE BOOKINGS (newly onboarded professor)
-- slot 45 (May 5): 1 approved
-- slot 46 (May 6): 1 approved, 1 pending
-- slot 47 (May 7): 1 pending (just submitted, future)
-- ------------------------------------------------------------

INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(88, 24, 45);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(88, 'APPROVED', 'COURSE_REGISTRATION',
 'Requesting advice on SNS mathematics electives.',
 NULL, '2026-04-25 09:00:00', NULL);

INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(89, 25, 46),
(90, 26, 46);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(89, 'APPROVED', 'THESIS_FYP',
 'Initial FYP scoping session — mathematical modelling topic.',
 NULL, '2026-04-25 09:10:00', NULL),

(90, 'PENDING', 'GENERAL_ADVICE',
 'Seeking advice on research methodology for final year project.',
 NULL, '2026-04-25 09:20:00', NULL);

INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(91, 27, 47);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(91, 'PENDING', 'RECOMMENDATION_LETTER',
 'Requesting a recommendation letter for a mathematics olympiad.',
 NULL, '2026-04-26 10:00:00', NULL);


-- ------------------------------------------------------------
-- PROF 20 — SLOT CANCELLATION → RESCHEDULE CHAIN + WAITLIST
-- slot 48 (Apr 12): 2 approved → professor cancels
-- Both appts cascade to CANCELLED
-- System moves them to slot 49 (Apr 19): RESERVED → APPROVED
-- slot 49: 3 approved → LOCKED
-- 2 students on waitlist for slot 49
-- student 30 (3rd approved) reschedules to slot 50 (May 10) → PENDING
-- slot 49 drops to PARTIALLY_BOOKED
-- top waitlist student auto-promoted (slot 49 back to LOCKED)
-- ------------------------------------------------------------

-- Slot 48 (Apr 12): original appointments before cancellation
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(92, 28, 48),
(93, 29, 48);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(92, 'CANCELLED', 'PAPER_RECHECK',
 'Professor cancelled the entire slot.',
 NULL, '2026-04-09 10:00:00', NULL),

(93, 'CANCELLED', 'GRADE_APPEAL',
 'Professor cancelled the entire slot.',
 NULL, '2026-04-09 10:05:00', NULL);

-- System offers slot 49 to both displaced students → both accept (RESERVED → APPROVED)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(94, 28, 49),
(95, 29, 49);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(94, 'APPROVED', 'PAPER_RECHECK',
 'Reserved slot offered after professor cancelled slot 48. Student accepted within 24h.',
 NULL, '2026-04-13 09:00:00', 92),

(95, 'APPROVED', 'GRADE_APPEAL',
 'Reserved slot offered after professor cancelled slot 48. Student accepted within 24h.',
 NULL, '2026-04-13 09:10:00', 93);

-- Third student books slot 49 organically → fills to LOCKED
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(96, 30, 49);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(96, 'CANCELLED', 'THESIS_FYP',
 'Student rescheduled to a later date.',
 NULL, '2026-04-15 10:00:00', NULL);  -- student 30 cancels (reschedules) → triggers waitlist check

-- Waitlist for slot 49 (2 students — slot was LOCKED, so waitlist formed)
INSERT INTO waitlisted_student (waitlist_id, student_id) VALUES
(20, 21),   -- Hamza, year 2, normal
(21, 22);   -- Amna, year 1, lowest priority

INSERT INTO waitlist_details (waitlist_id, priority_score, joined_at, slot_id) VALUES
(20, 60, '2026-04-17 09:00:00', 49),
(21, 50, '2026-04-17 09:30:00', 49);

-- student 30 reschedules (appt 96 CANCELLED) → new PENDING on slot 50
-- slot 49 drops from LOCKED → PARTIALLY_BOOKED (bookings=2)
-- top waitlisted student (student 21, priority 60, joined earlier) auto-promoted → APPROVED
-- slot 49 back to LOCKED (bookings=3: 94,95,97)

INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(97, 21, 49);  -- auto-promoted from waitlist

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(97, 'APPROVED', 'GENERAL_ADVICE',
 'Auto-promoted from waitlist (priority score 60) after student 30 rescheduled.',
 NULL, '2026-04-16 10:30:00', NULL);
-- slot 49: current_bookings = 3 (appts 94, 95, 97) → back to LOCKED ✓

-- student 30 reschedule target: slot 50 (May 10)
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(98, 30, 50);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(98, 'PENDING', 'THESIS_FYP',
 'Rescheduled from Apr 19 slot — FYP chapter two review.',
 NULL, '2026-04-27 09:00:00', 96);  -- rescheduled_from = 96 (cancelled slot 49 appt) ✓

-- Additional organic pending booking on slot 50
INSERT INTO student_appointment (appointment_id, student_id, slot_id) VALUES
(99, 22, 50);

INSERT INTO appointment_details
(appointment_id, status, reason, note, rejection_reason, created_at, rescheduled_from)
VALUES
(99, 'PENDING', 'GENERAL_ADVICE',
 'Guidance on physics research internships.',
 NULL, '2026-04-27 09:30:00', NULL);


-- ============================================================
-- SUMMARY TABLE
-- ============================================================
-- PROF 13 | Electrical Eng
--   slot 29 (Apr 10) LOCKED     | appts 54(APPROVED),55(CANCELLED),56(APPROVED),57(APPROVED-promoted)
--   slot 30 (Apr 14) PART_BOOKED | appts 58,59 (APPROVED)
--   waitlist 29: 6 entries (ws14–19) | student 24 promoted after student 22 cancels
--
-- PROF 14 | Business Admin
--   slot 31 (Apr 15) LOCKED     | appts 60,61,62 (all APPROVED)
--   slot 32 (Apr 22) PART_BOOKED | appts 63(APPROVED),64(REJECTED),65(PENDING)
--   slot 33 (May 5)  FREE       | appt  66 (PENDING)
--
-- PROF 15 | Mechanical Eng
--   slot 34 (Apr 8)  PART_BOOKED | appts 67(REJECTED),68(CANCELLED-reschedule)
--   slot 35 (Apr 9)  LOCKED      | appts 69(APPROVED),70(APPROVED),71(APPROVED)
--   slot 36 (May 6)  PART_BOOKED | appts 72(PENDING,rescheduled_from=68),73(APPROVED)
--
-- PROF 16 | Computer Science
--   slot 37 (Apr 16) PART_BOOKED | appts 74,75 (APPROVED)
--   slot 38 (Apr 17) LOCKED      | appts 76,77,78 (APPROVED)
--   slot 39 (May 7)  LOCKED      | manually blocked — no appointments
--
-- PROF 17 | Electrical Eng
--   slot 40 (Apr 21) FROZEN      | appts 79,80(APPROVED),81(PENDING — frozen mid-review)
--   slot 41 (May 8)  FREE        | appt  82 (PENDING)
--
-- PROF 18 | Business Admin
--   slot 42 (Apr 23) CANCELLED   | appts 83,84 (CANCELLED — prof cancelled slot)
--   slot 43 (Apr 28) PART_BOOKED | appts 85(APPROVED,from=83),87(APPROVED)
--   slot 44 (May 9)  PART_BOOKED | appt  86(APPROVED,from=84)
--
-- PROF 19 | Mathematics
--   slot 45 (May 5)  PART_BOOKED | appt  88 (APPROVED)
--   slot 46 (May 6)  PART_BOOKED | appts 89(APPROVED),90(PENDING)
--   slot 47 (May 7)  FREE        | appt  91 (PENDING)
--
-- PROF 20 | Physics
--   slot 48 (Apr 12) CANCELLED   | appts 92,93 (CANCELLED — prof cancelled)
--   slot 49 (Apr 19) LOCKED      | appts 94(APPROVED,from=92),95(APPROVED,from=93),
--                                |        96(CANCELLED-reschedule),97(APPROVED-promoted)
--   slot 50 (May 10) FREE        | appts 98(PENDING,from=96),99(PENDING)
--   waitlist 49: 2 entries (ws20,21) | student 21 promoted after student 30 reschedules
-- ============================================================
