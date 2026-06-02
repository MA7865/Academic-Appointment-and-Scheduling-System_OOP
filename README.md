# SlotSync

## Academic Appointment and Scheduling System

A project by Maryam Amir, Romaisa Kashif, Arham Nabi & Eiman Fatima.

SlotSync is a JavaFX-based academic appointment scheduler built for students and professors. It replaces informal booking workflows, blocks double bookings, and manages appointment capacity and waitlists through a local MySQL backend.

## Why this repo?

- Modern JavaFX desktop application with a clean professor/student dashboard.
- Includes database bootstrap scripts so anyone can run the system locally.
- Designed for academic appointment booking, waitlist management, and professor approvals.

## Key Features

- Student dashboard for booking, viewing upcoming appointments, and cancelling pending/approved requests.
- Professor dashboard for reviewing pending appointment requests, approving/rejecting bookings, and managing waitlists.
- Upcoming-appointment filtering across student and professor views.
- Double-booking prevention for the same student/slot combination.
- Slot capacity tracking with live available-spots updates.
- Local MySQL database bootstrap with schema and sample data scripts.

## Repo structure

- `src/dao/` - Database access and SQL queries.
- `src/service/` - Business logic and service layer.
- `src/view/` - JavaFX screens for students and professors.
- `src/model/` - Domain models for appointments, users, and time slots.
- `db/` - SQL bootstrap scripts for local MySQL setup.
- `.env.example` - Example environment file for local database credentials.

## Local setup

1. Install MySQL locally.
2. Copy `.env.example` to `.env` and update credentials:

```env
DB_URL=jdbc:mysql://127.0.0.1:3306/appointment_system
DB_USER=root
DB_PASSWORD=your_password_here
```

3. Create and populate the local database:

```powershell
mysql -u root -p < db/schema.sql
mysql -u root -p appointment_system < db/sample-data.sql
```

4. Build and run the application:

```powershell
mvn clean compile
mvn javafx:run
```

## Database scripts

- `db/schema.sql` — Creates the database schema and required tables.
- `db/sample-data.sql` — Inserts starter users, professor, student, and a sample timeslot.



Note: 
If you add your own MySQL credentials, keep them in a local `.env` file only. `.env` is already ignored by `.gitignore`.
