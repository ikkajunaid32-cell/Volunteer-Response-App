# Volunteer Task Management Application 🤝

A full-stack mobile volunteer management solution built with **Flutter**, **Android APK**, **Node.js REST API**, and a **Relational SQL Database (SQLite)**.

---

## 📱 Features

### 1. Admin Panel
* **Secure Admin Authentication**: Login with dedicated administrative credentials.
* **Task Creation & Publishing**:
  * Task Name / Title & detailed description.
  * Location / Address (with coordinates support).
  * Date picker and Start/End time pickers.
  * Volunteer quota (`Volunteers Required`).
  * Image upload from camera/gallery or direct URL.
  * Status management: `Available`, `In Progress`, `Completed`, `Cancelled`.
* **Task Editing & Deletion**: Update task details or delete tasks with automatic cascade cleanup.
* **Volunteer Roster**: View real-time list of volunteers who accepted each task, including:
  * Volunteer Name
  * Email & Phone number
  * Registration Date & Time
  * Registration Status (`Accepted`, `Completed`, `Cancelled`)
* **Live Statistics**: Real-time counter of total tasks, available tasks, and completed tasks.

### 2. Volunteer / User App
* **Volunteer Registration & Login**: Instant account creation or quick demo sign-in.
* **Daily Tasks Feed / Dashboard**:
  * Shows banner image, title, location, date & time.
  * Shows volunteer quota indicator (e.g. `6/10 Registered`, `4 spots left`).
  * Real-time status badges.
  * **View Details** and **Accept Task** buttons.
* **Task Details View**:
  * Multiple image gallery.
  * Capacity progress bar.
  * Clear action to **Accept Task** or **Cancel Registration**.
* **My Tasks Screen**:
  * Filterable tabs: **Upcoming**, **Accepted**, **Completed**, and **Cancelled**.

---

## 🗄️ SQL Database Architecture

The SQLite database (`backend/volunteer_database.sqlite`) uses relational foreign keys:

```sql
-- 1. Users Table
CREATE TABLE Users (
  UserID INTEGER PRIMARY KEY AUTOINCREMENT,
  Name TEXT NOT NULL,
  Email TEXT UNIQUE NOT NULL,
  PasswordHash TEXT NOT NULL,
  Phone TEXT,
  Role TEXT CHECK(Role IN ('admin', 'volunteer')) NOT NULL DEFAULT 'volunteer',
  CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tasks Table
CREATE TABLE Tasks (
  TaskID INTEGER PRIMARY KEY AUTOINCREMENT,
  TaskName TEXT NOT NULL,
  Description TEXT NOT NULL,
  ImageURL TEXT,
  Location TEXT NOT NULL,
  Latitude REAL,
  Longitude REAL,
  TaskDate TEXT NOT NULL,
  StartTime TEXT NOT NULL,
  EndTime TEXT,
  VolunteersRequired INTEGER NOT NULL DEFAULT 1,
  Status TEXT CHECK(Status IN ('Available', 'In Progress', 'Completed', 'Cancelled')) NOT NULL DEFAULT 'Available',
  CreatedBy INTEGER,
  CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (CreatedBy) REFERENCES Users(UserID) ON DELETE SET NULL
);

-- 3. TaskRegistrations Table
CREATE TABLE TaskRegistrations (
  RegistrationID INTEGER PRIMARY KEY AUTOINCREMENT,
  TaskID INTEGER NOT NULL,
  UserID INTEGER NOT NULL,
  RegistrationDate DATETIME DEFAULT CURRENT_TIMESTAMP,
  Status TEXT CHECK(Status IN ('Accepted', 'Completed', 'Cancelled')) NOT NULL DEFAULT 'Accepted',
  UNIQUE(TaskID, UserID),
  FOREIGN KEY (TaskID) REFERENCES Tasks(TaskID) ON DELETE CASCADE,
  FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);

-- 4. TaskImages Table
CREATE TABLE TaskImages (
  ImageID INTEGER PRIMARY KEY AUTOINCREMENT,
  TaskID INTEGER NOT NULL,
  ImageURL TEXT NOT NULL,
  UploadedDate DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (TaskID) REFERENCES Tasks(TaskID) ON DELETE CASCADE
);
```

---

## 🚀 Quick Start Guide

### 1. Start the Backend API Server
```bash
cd backend
npm install
npm run seed     # Seeds sample tasks and demo users
npm start        # Starts server on http://localhost:3000
```
> The server listens on `0.0.0.0:3000`, making it accessible to Android emulators (`10.0.2.2:3000`) and physical devices on the local network.

### 2. Pre-Seeded Demo Accounts
For instant testing, use the quick demo login buttons in the app or sign in manually:

| Role | Email | Password |
|---|---|---|
| **Admin** | `admin@volunteer.org` | `admin123` |
| **Volunteer** | `volunteer@volunteer.org` | `volunteer123` |

---

### 3. Run the Flutter Mobile App
```bash
cd volunteer_app
flutter run
```

#### Server IP Configuration
* **Android Emulator**: Uses `http://10.0.2.2:3000` automatically.
* **Physical Device**: Connect phone to the same Wi-Fi, tap the **Settings icon (⚙️)** on the top right of the Login screen, and enter your machine's local IP (e.g., `http://192.168.1.X:3000`).
* **Web/Desktop**: Uses `http://localhost:3000`.

---

## 📦 Mobile App Packages (.apk and .ipa)

Both installation packages are generated and placed directly in this project's root folder:

| Package | Platform | File Location |
|---|---|---|
| **Android APK** | Android Devices / Emulators | `Volunteer Response App.apk` |
| **iOS Package** | iPhone / iOS Package Bundle | `Volunteer Response App.ipa` |

### Install Android APK via ADB:
```bash
adb install "Volunteer Response App.apk"
```
Or rebuild anytime using:
```bash
cd volunteer_app
flutter build apk --debug
```

---

## 🍏 iOS (.ipa) Build for iPhone

Apple requires **macOS with Xcode** and the iOS toolchain to compile iOS binaries. Because your development environment is Windows, you have two options to obtain the `.ipa`:

### Option A: Automated Cloud Build with GitHub Actions (Included!)
A GitHub Actions workflow is provided at [`.github/workflows/build_ios.yml`](.github/workflows/build_ios.yml).
1. Push your repository to GitHub.
2. In your repository on GitHub, navigate to the **Actions** tab.
3. Select **Build iOS IPA** and click **Run workflow** (or simply push to `main`).
4. The workflow runs on a GitHub-hosted macOS runner, builds the `.ipa`, and attaches `VolunteerResponse-iOS-IPA` as a downloadable zip file under the workflow run!

### Option B: Building on a Mac
If you have access to a Mac computer:
```bash
cd volunteer_app
flutter pub get
flutter build ipa --no-codesign
```
The resulting `.ipa` file will be generated in `volunteer_app/build/ios/archive/` or `volunteer_app/build/ios/ipa/`.

All iOS permissions (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSAppTransportSecurity`) and workspace configurations have already been set up in `volunteer_app/ios/Runner/Info.plist`.

---

## 📂 Project Structure

```
Volunteer Reponse App/
├── backend/
│   ├── db.js                      # SQLite database initialization & schemas
│   ├── server.js                  # Express REST API & static file serving
│   ├── seed.js                    # Database seed data & demo accounts
│   ├── routes/
│   │   ├── auth.js                # Login, register, JWT validation
│   │   ├── tasks.js               # Task CRUD & query filters
│   │   ├── registrations.js       # Volunteer accept/cancel & rosters
│   │   └── upload.js              # Multer image uploads
│   └── uploads/                   # Stored task images
│
└── volunteer_app/
    ├── android/                   # Android native config (Permissions & NDK)
    ├── lib/
    │   ├── core/
    │   │   ├── constants/         # ApiConstants & dynamic IP resolver
    │   │   └── theme/             # Material 3 emergency theme
    │   ├── data/
    │   │   ├── models/            # UserModel, TaskModel, RegistrationModel
    │   │   ├── services/          # ApiService (HTTP, Auth headers, Upload)
    │   │   └── repositories/      # AuthRepository, TaskRepository
    │   ├── ui/
    │   │   ├── view_models/       # AuthViewModel, TaskViewModel, AdminTaskViewModel
    │   │   ├── views/
    │   │   │   ├── auth/          # LoginView, RegisterView (Quick demo buttons)
    │   │   │   ├── volunteer/     # VolunteerDashboardView, TaskDetailsView, MyTasksView
    │   │   │   ├── admin/         # AdminDashboardView, CreateEditTaskView, TaskVolunteersView
    │   │   │   └── common/        # StatusBadge, TaskImageThumbnail, ApiConfigDialog
    │   │   └── splash_gate.dart   # Role-based authentication router
    │   └── main.dart              # MultiProvider app setup
    └── test/                      # Data model unit tests
```
