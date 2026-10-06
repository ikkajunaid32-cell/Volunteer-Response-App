const bcrypt = require('bcryptjs');
const db = require('./db');

async function seed() {
  console.log('Seeding SQLite database with initial data...');

  try {
    // Clear existing data (in reverse order of foreign keys)
    await db.runAsync('DELETE FROM TaskImages');
    await db.runAsync('DELETE FROM TaskRegistrations');
    await db.runAsync('DELETE FROM Tasks');
    await db.runAsync('DELETE FROM Users');

    const salt = await bcrypt.genSalt(10);
    const adminPass = await bcrypt.hash('admin123', salt);
    const volunteerPass = await bcrypt.hash('volunteer123', salt);

    // 1. Seed Users
    const adminRes = await db.runAsync(`
      INSERT INTO Users (Name, Email, PasswordHash, Phone, Role)
      VALUES (?, ?, ?, ?, ?)
    `, ['Emergency Coordinator (Admin)', 'admin@volunteer.org', adminPass, '0412 345 678', 'admin']);
    const adminId = adminRes.lastID;

    const vol1Res = await db.runAsync(`
      INSERT INTO Users (Name, Email, PasswordHash, Phone, Role)
      VALUES (?, ?, ?, ?, ?)
    `, ['John Doe', 'volunteer@volunteer.org', volunteerPass, '0498 765 432', 'volunteer']);
    const vol1Id = vol1Res.lastID;

    const vol2Res = await db.runAsync(`
      INSERT INTO Users (Name, Email, PasswordHash, Phone, Role)
      VALUES (?, ?, ?, ?, ?)
    `, ['Sarah Jenkins', 'sarah.j@volunteer.org', volunteerPass, '0455 112 233', 'volunteer']);
    const vol2Id = vol2Res.lastID;

    const vol3Res = await db.runAsync(`
      INSERT INTO Users (Name, Email, PasswordHash, Phone, Role)
      VALUES (?, ?, ?, ?, ?)
    `, ['David Miller', 'david.m@volunteer.org', volunteerPass, '0466 223 344', 'volunteer']);
    const vol3Id = vol3Res.lastID;

    const vol4Res = await db.runAsync(`
      INSERT INTO Users (Name, Email, PasswordHash, Phone, Role)
      VALUES (?, ?, ?, ?, ?)
    `, ['Emily Watson', 'emily.w@volunteer.org', volunteerPass, '0477 334 455', 'volunteer']);
    const vol4Id = vol4Res.lastID;

    const vol5Res = await db.runAsync(`
      INSERT INTO Users (Name, Email, PasswordHash, Phone, Role)
      VALUES (?, ?, ?, ?, ?)
    `, ['Michael Chang', 'michael.c@volunteer.org', volunteerPass, '0488 445 566', 'volunteer']);
    const vol5Id = vol5Res.lastID;

    const vol6Res = await db.runAsync(`
      INSERT INTO Users (Name, Email, PasswordHash, Phone, Role)
      VALUES (?, ?, ?, ?, ?)
    `, ['Jessica Taylor', 'jessica.t@volunteer.org', volunteerPass, '0499 556 677', 'volunteer']);
    const vol6Id = vol6Res.lastID;

    console.log('✓ Users created');

    // 2. Seed Tasks
    // Task 1: Fill Sandbags (Example from requirement)
    const task1Res = await db.runAsync(`
      INSERT INTO Tasks (
        TaskName, Description, ImageURL, Location, Latitude, Longitude,
        TaskDate, StartTime, EndTime, VolunteersRequired, Status, CreatedBy
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      'Fill Sandbags',
      'Volunteers are required to fill and prepare sandbags for emergency flood protection. Please wear appropriate safety equipment and sturdy footwear.',
      'https://images.unsplash.com/photo-1547683905-f686c993aae5?auto=format&fit=crop&w=800&q=80',
      'Newcastle Emergency Response Centre',
      -32.9283,
      151.7817,
      '2026-10-06',
      '08:30 AM',
      '03:00 PM',
      10,
      'Available',
      adminId
    ]);
    const task1Id = task1Res.lastID;

    // Additional images for Task 1
    await db.runAsync('INSERT INTO TaskImages (TaskID, ImageURL) VALUES (?, ?)', [
      task1Id,
      'https://images.unsplash.com/photo-1547683905-f686c993aae5?auto=format&fit=crop&w=800&q=80'
    ]);
    await db.runAsync('INSERT INTO TaskImages (TaskID, ImageURL) VALUES (?, ?)', [
      task1Id,
      'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=800&q=80'
    ]);

    // Task 2: Community Food Distribution
    const task2Res = await db.runAsync(`
      INSERT INTO Tasks (
        TaskName, Description, ImageURL, Location, Latitude, Longitude,
        TaskDate, StartTime, EndTime, VolunteersRequired, Status, CreatedBy
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      'Emergency Food & Supply Distribution',
      'Pack, organize, and hand out emergency grocery hampers and fresh produce care packages to displaced local families.',
      'https://images.unsplash.com/photo-1593113598332-cd288d649433?auto=format&fit=crop&w=800&q=80',
      'Hunter Valley Civic Hall, Maitland',
      -32.7333,
      151.5500,
      '2026-10-07',
      '10:00 AM',
      '02:00 PM',
      6,
      'Available',
      adminId
    ]);
    const task2Id = task2Res.lastID;

    await db.runAsync('INSERT INTO TaskImages (TaskID, ImageURL) VALUES (?, ?)', [
      task2Id,
      'https://images.unsplash.com/photo-1593113598332-cd288d649433?auto=format&fit=crop&w=800&q=80'
    ]);

    // Task 3: Debris & Fallen Branch Clearing
    const task3Res = await db.runAsync(`
      INSERT INTO Tasks (
        TaskName, Description, ImageURL, Location, Latitude, Longitude,
        TaskDate, StartTime, EndTime, VolunteersRequired, Status, CreatedBy
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      'Pathways & Debris Clearing',
      'Clear storm debris and fallen branches from community pathways and elderly care village access gates. Gloves provided.',
      'https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?auto=format&fit=crop&w=800&q=80',
      'Lake Macquarie Foreshore Park',
      -32.9714,
      151.6533,
      '2026-10-08',
      '07:30 AM',
      '12:00 PM',
      8,
      'Available',
      adminId
    ]);
    const task3Id = task3Res.lastID;

    console.log('✓ Tasks created');

    // 3. Seed Task Registrations (6 volunteers registered for Task 1 -> matching example "6/10")
    const registeredVolunteers = [vol1Id, vol2Id, vol3Id, vol4Id, vol5Id, vol6Id];
    for (const vId of registeredVolunteers) {
      await db.runAsync(`
        INSERT INTO TaskRegistrations (TaskID, UserID, Status)
        VALUES (?, ?, 'Accepted')
      `, [task1Id, vId]);
    }

    // vol1 also registered for Task 2
    await db.runAsync(`
      INSERT INTO TaskRegistrations (TaskID, UserID, Status)
      VALUES (?, ?, 'Accepted')
    `, [task2Id, vol1Id]);

    console.log('✓ Task registrations created (Task 1 has 6/10 registered)');
    console.log('Database seeding successfully completed!');
    process.exit(0);
  } catch (error) {
    console.error('Seeding failed:', error);
    process.exit(1);
  }
}

seed();
