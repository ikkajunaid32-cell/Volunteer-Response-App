const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, 'volunteer_database.sqlite');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Failed to connect to SQLite database:', err.message);
  } else {
    console.log('Connected to SQLite database at:', dbPath);
  }
});

// Enable Foreign Key support in SQLite
db.run('PRAGMA foreign_keys = ON;');

// Initialize SQL Schemas
db.serialize(() => {
  // 1. Users Table
  db.run(`
    CREATE TABLE IF NOT EXISTS Users (
      UserID INTEGER PRIMARY KEY AUTOINCREMENT,
      Name TEXT NOT NULL,
      Email TEXT UNIQUE NOT NULL,
      PasswordHash TEXT NOT NULL,
      Phone TEXT,
      Role TEXT CHECK(Role IN ('admin', 'volunteer')) NOT NULL DEFAULT 'volunteer',
      CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // 2. Tasks Table
  db.run(`
    CREATE TABLE IF NOT EXISTS Tasks (
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
    )
  `);

  // 3. TaskRegistrations Table
  db.run(`
    CREATE TABLE IF NOT EXISTS TaskRegistrations (
      RegistrationID INTEGER PRIMARY KEY AUTOINCREMENT,
      TaskID INTEGER NOT NULL,
      UserID INTEGER NOT NULL,
      RegistrationDate DATETIME DEFAULT CURRENT_TIMESTAMP,
      Status TEXT CHECK(Status IN ('Accepted', 'Completed', 'Cancelled')) NOT NULL DEFAULT 'Accepted',
      UNIQUE(TaskID, UserID),
      FOREIGN KEY (TaskID) REFERENCES Tasks(TaskID) ON DELETE CASCADE,
      FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
    )
  `);

  // 4. TaskImages Table
  db.run(`
    CREATE TABLE IF NOT EXISTS TaskImages (
      ImageID INTEGER PRIMARY KEY AUTOINCREMENT,
      TaskID INTEGER NOT NULL,
      ImageURL TEXT NOT NULL,
      UploadedDate DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (TaskID) REFERENCES Tasks(TaskID) ON DELETE CASCADE
    )
  `);
});

// Async helper wrappers for cleaner async/await syntax
db.getAsync = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
};

db.allAsync = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
};

db.runAsync = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve({ lastID: this.lastID, changes: this.changes });
    });
  });
};

module.exports = db;
