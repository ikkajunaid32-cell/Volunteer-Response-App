import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:volunteer_app/data/models/registration_model.dart';
import 'package:volunteer_app/data/models/task_model.dart';
import 'package:volunteer_app/data/models/user_model.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('volunteer_management.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Users Table
    await db.execute('''
      CREATE TABLE Users (
        UserID INTEGER PRIMARY KEY AUTOINCREMENT,
        Name TEXT NOT NULL,
        Email TEXT UNIQUE NOT NULL,
        Password TEXT NOT NULL,
        Phone TEXT,
        Role TEXT CHECK(Role IN ('admin', 'volunteer')) NOT NULL DEFAULT 'volunteer',
        CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 2. Tasks Table
    await db.execute('''
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
      )
    ''');

    // 3. TaskRegistrations Table
    await db.execute('''
      CREATE TABLE TaskRegistrations (
        RegistrationID INTEGER PRIMARY KEY AUTOINCREMENT,
        TaskID INTEGER NOT NULL,
        UserID INTEGER NOT NULL,
        RegistrationDate DATETIME DEFAULT CURRENT_TIMESTAMP,
        Status TEXT CHECK(Status IN ('Accepted', 'Completed', 'Cancelled')) NOT NULL DEFAULT 'Accepted',
        UNIQUE(TaskID, UserID),
        FOREIGN KEY (TaskID) REFERENCES Tasks(TaskID) ON DELETE CASCADE,
        FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
      )
    ''');

    // 4. TaskImages Table
    await db.execute('''
      CREATE TABLE TaskImages (
        ImageID INTEGER PRIMARY KEY AUTOINCREMENT,
        TaskID INTEGER NOT NULL,
        ImageURL TEXT NOT NULL,
        UploadedDate DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (TaskID) REFERENCES Tasks(TaskID) ON DELETE CASCADE
      )
    ''');

    // Seed Initial Data
    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
    // 1. Admin account
    final adminId = await db.insert('Users', {
      'Name': 'Emergency Coordinator',
      'Email': 'admin@volunteer.org',
      'Password': 'admin123',
      'Phone': '+61 400 123 456',
      'Role': 'admin',
    });

    // 2. Main demo volunteer
    final volId1 = await db.insert('Users', {
      'Name': 'Jane Volunteer',
      'Email': 'volunteer@volunteer.org',
      'Password': 'volunteer123',
      'Phone': '+61 411 987 654',
      'Role': 'volunteer',
    });

    // Additional volunteers for quota demonstrations
    final v2 = await db.insert('Users', {
      'Name': 'Sarah Jenkins',
      'Email': 'sarah.j@example.com',
      'Password': 'password123',
      'Phone': '+61 422 111 222',
      'Role': 'volunteer',
    });
    final v3 = await db.insert('Users', {
      'Name': 'Alex Morgan',
      'Email': 'alex.m@example.com',
      'Password': 'password123',
      'Phone': '+61 433 222 333',
      'Role': 'volunteer',
    });
    final v4 = await db.insert('Users', {
      'Name': 'Michael Chang',
      'Email': 'michael.c@example.com',
      'Password': 'password123',
      'Phone': '+61 444 333 444',
      'Role': 'volunteer',
    });
    final v5 = await db.insert('Users', {
      'Name': 'David Miller',
      'Email': 'david.m@example.com',
      'Password': 'password123',
      'Phone': '+61 455 444 555',
      'Role': 'volunteer',
    });
    final v6 = await db.insert('Users', {
      'Name': 'Emma Watson',
      'Email': 'emma.w@example.com',
      'Password': 'password123',
      'Phone': '+61 466 555 666',
      'Role': 'volunteer',
    });

    // 3. Seed Initial Task: "Fill Sandbags" (10 Required, 6 Registered)
    final taskId1 = await db.insert('Tasks', {
      'TaskName': 'Fill Sandbags',
      'Description':
          'URGENT FLOOD PREPARATION: Volunteers needed to fill, tie, and stack sandbags along the river barrier. Heavy lifting involved, gloves and shovels provided on site. Please wear protective boots.',
      'ImageURL':
          'https://images.unsplash.com/photo-1547683905-f686c993aae5?auto=format&fit=crop&w=800&q=80',
      'Location': 'Newcastle Emergency Response Centre, NSW',
      'Latitude': -32.9283,
      'Longitude': 151.7817,
      'TaskDate': '2026-10-15',
      'StartTime': '08:00 AM',
      'EndTime': '02:00 PM',
      'VolunteersRequired': 10,
      'Status': 'Available',
      'CreatedBy': adminId,
    });

    // Add extra gallery images for Task 1
    await db.insert('TaskImages', {
      'TaskID': taskId1,
      'ImageURL':
          'https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?auto=format&fit=crop&w=800&q=80',
    });
    await db.insert('TaskImages', {
      'TaskID': taskId1,
      'ImageURL':
          'https://images.unsplash.com/photo-1593113598332-cd288d649433?auto=format&fit=crop&w=800&q=80',
    });

    // Register 6 volunteers for Task 1 (6 / 10 registered)
    for (final uid in [volId1, v2, v3, v4, v5, v6]) {
      await db.insert('TaskRegistrations', {
        'TaskID': taskId1,
        'UserID': uid,
        'Status': 'Accepted',
      });
    }

    // 4. Seed Second Task: "Food Parcel Distribution"
    final taskId2 = await db.insert('Tasks', {
      'TaskName': 'Community Food Distribution',
      'Description':
          'Organize, pack, and distribute emergency non-perishable food boxes and clean water supplies for families affected by recent storms.',
      'ImageURL':
          'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?auto=format&fit=crop&w=800&q=80',
      'Location': 'Hunter Community Hub, Broadmeadow, NSW',
      'Latitude': -32.9190,
      'Longitude': 151.7390,
      'TaskDate': '2026-10-16',
      'StartTime': '09:00 AM',
      'EndTime': '01:00 PM',
      'VolunteersRequired': 5,
      'Status': 'Available',
      'CreatedBy': adminId,
    });

    await db.insert('TaskRegistrations', {
      'TaskID': taskId2,
      'UserID': v2,
      'Status': 'Accepted',
    });
    await db.insert('TaskRegistrations', {
      'TaskID': taskId2,
      'UserID': v3,
      'Status': 'Accepted',
    });
  }

  // ==========================================
  // AUTH METHODS
  // ==========================================

  Future<UserModel?> login(String email, String password) async {
    final db = await instance.database;
    final results = await db.query(
      'Users',
      where: 'LOWER(Email) = ? AND Password = ?',
      whereArgs: [email.trim().toLowerCase(), password],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return UserModel.fromJson(results.first);
    }
    return null;
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'volunteer',
  }) async {
    final db = await instance.database;
    final existing = await db.query(
      'Users',
      where: 'LOWER(Email) = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw Exception('An account with this email address already exists.');
    }

    final id = await db.insert('Users', {
      'Name': name.trim(),
      'Email': email.trim().toLowerCase(),
      'Password': password,
      'Phone': phone?.trim(),
      'Role': role,
    });

    final created = await db.query('Users', where: 'UserID = ?', whereArgs: [id], limit: 1);
    return UserModel.fromJson(created.first);
  }

  Future<UserModel?> getUserById(int userId) async {
    final db = await instance.database;
    final results = await db.query('Users', where: 'UserID = ?', whereArgs: [userId], limit: 1);
    if (results.isNotEmpty) {
      return UserModel.fromJson(results.first);
    }
    return null;
  }

  // ==========================================
  // TASK METHODS
  // ==========================================

  Future<List<TaskModel>> getTasks({String? status, String? search}) async {
    final db = await instance.database;

    String query = '''
      SELECT 
        t.*,
        COUNT(CASE WHEN r.Status = 'Accepted' THEN 1 END) AS RegisteredCount
      FROM Tasks t
      LEFT JOIN TaskRegistrations r ON t.TaskID = r.TaskID
    ''';

    final conditions = <String>[];
    final args = <dynamic>[];

    if (status != null && status.isNotEmpty && status != 'All') {
      conditions.add('t.Status = ?');
      args.add(status);
    }

    if (search != null && search.trim().isNotEmpty) {
      conditions.add('(LOWER(t.TaskName) LIKE ? OR LOWER(t.Location) LIKE ? OR LOWER(t.Description) LIKE ?)');
      final term = '%${search.trim().toLowerCase()}%';
      args.add(term);
      args.add(term);
      args.add(term);
    }

    if (conditions.isNotEmpty) {
      query += ' WHERE ${conditions.join(" AND ")}';
    }

    query += ' GROUP BY t.TaskID ORDER BY t.TaskID DESC';

    final rows = await db.rawQuery(query, args);

    final tasks = <TaskModel>[];
    for (final row in rows) {
      final taskId = row['TaskID'] as int;
      final images = await _getTaskImages(db, taskId);

      final map = Map<String, dynamic>.from(row);
      map['Images'] = images;
      tasks.add(TaskModel.fromJson(map));
    }
    return tasks;
  }

  Future<TaskModel> getTaskDetails(int taskId) async {
    final db = await instance.database;

    final query = '''
      SELECT 
        t.*,
        COUNT(CASE WHEN r.Status = 'Accepted' THEN 1 END) AS RegisteredCount
      FROM Tasks t
      LEFT JOIN TaskRegistrations r ON t.TaskID = r.TaskID
      WHERE t.TaskID = ?
      GROUP BY t.TaskID
    ''';

    final rows = await db.rawQuery(query, [taskId]);
    if (rows.isEmpty) {
      throw Exception('Task not found');
    }

    final images = await _getTaskImages(db, taskId);
    final map = Map<String, dynamic>.from(rows.first);
    map['Images'] = images;
    return TaskModel.fromJson(map);
  }

  Future<List<String>> _getTaskImages(Database db, int taskId) async {
    final rows = await db.query('TaskImages', where: 'TaskID = ?', whereArgs: [taskId]);
    return rows.map((r) => r['ImageURL'] as String).toList();
  }

  Future<void> createTask({
    required String taskName,
    required String description,
    String? imageUrl,
    required String location,
    double? latitude,
    double? longitude,
    required String taskDate,
    required String startTime,
    String? endTime,
    required int volunteersRequired,
    String status = 'Available',
    List<String> additionalImages = const [],
    int? createdBy,
  }) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final taskId = await txn.insert('Tasks', {
        'TaskName': taskName,
        'Description': description,
        'ImageURL': imageUrl,
        'Location': location,
        'Latitude': latitude,
        'Longitude': longitude,
        'TaskDate': taskDate,
        'StartTime': startTime,
        'EndTime': endTime,
        'VolunteersRequired': volunteersRequired,
        'Status': status,
        'CreatedBy': createdBy,
      });

      for (final img in additionalImages) {
        if (img.trim().isNotEmpty) {
          await txn.insert('TaskImages', {
            'TaskID': taskId,
            'ImageURL': img.trim(),
          });
        }
      }
    });
  }

  Future<void> updateTask({
    required int taskId,
    String? taskName,
    String? description,
    String? imageUrl,
    String? location,
    double? latitude,
    double? longitude,
    String? taskDate,
    String? startTime,
    String? endTime,
    int? volunteersRequired,
    String? status,
    List<String>? additionalImages,
  }) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final updates = <String, dynamic>{};
      if (taskName != null) updates['TaskName'] = taskName;
      if (description != null) updates['Description'] = description;
      if (imageUrl != null) updates['ImageURL'] = imageUrl;
      if (location != null) updates['Location'] = location;
      if (latitude != null) updates['Latitude'] = latitude;
      if (longitude != null) updates['Longitude'] = longitude;
      if (taskDate != null) updates['TaskDate'] = taskDate;
      if (startTime != null) updates['StartTime'] = startTime;
      if (endTime != null) updates['EndTime'] = endTime;
      if (volunteersRequired != null) updates['VolunteersRequired'] = volunteersRequired;
      if (status != null) updates['Status'] = status;

      if (updates.isNotEmpty) {
        await txn.update('Tasks', updates, where: 'TaskID = ?', whereArgs: [taskId]);
      }

      if (additionalImages != null) {
        await txn.delete('TaskImages', where: 'TaskID = ?', whereArgs: [taskId]);
        for (final img in additionalImages) {
          if (img.trim().isNotEmpty) {
            await txn.insert('TaskImages', {
              'TaskID': taskId,
              'ImageURL': img.trim(),
            });
          }
        }
      }
    });
  }

  Future<void> deleteTask(int taskId) async {
    final db = await instance.database;
    await db.delete('Tasks', where: 'TaskID = ?', whereArgs: [taskId]);
  }

  // ==========================================
  // REGISTRATION METHODS
  // ==========================================

  Future<void> applyTask(int taskId, int userId) async {
    final db = await instance.database;

    // Check task capacity and status
    final taskRows = await db.query('Tasks', where: 'TaskID = ?', whereArgs: [taskId], limit: 1);
    if (taskRows.isEmpty) throw Exception('Task not found');
    final task = taskRows.first;

    if (task['Status'] != 'Available' && task['Status'] != 'In Progress') {
      throw Exception('Task is not accepting volunteers at this time.');
    }

    final capacity = task['VolunteersRequired'] as int;

    // Check count of active accepted registrations
    final countRows = await db.rawQuery('''
      SELECT COUNT(*) as count FROM TaskRegistrations 
      WHERE TaskID = ? AND Status = 'Accepted'
    ''', [taskId]);
    final currentCount = Sqflite.firstIntValue(countRows) ?? 0;

    // Check user's current registration
    final existingReg = await db.query(
      'TaskRegistrations',
      where: 'TaskID = ? AND UserID = ?',
      whereArgs: [taskId, userId],
      limit: 1,
    );

    if (existingReg.isNotEmpty) {
      final currentStatus = existingReg.first['Status'];
      if (currentStatus == 'Accepted') {
        throw Exception('You are already registered for this task.');
      } else {
        if (currentCount >= capacity) {
          throw Exception('Task has reached its volunteer quota limit ($capacity/$capacity).');
        }
        await db.update(
          'TaskRegistrations',
          {'Status': 'Accepted', 'RegistrationDate': DateTime.now().toIso8601String()},
          where: 'TaskID = ? AND UserID = ?',
          whereArgs: [taskId, userId],
        );
        return;
      }
    }

    if (currentCount >= capacity) {
      throw Exception('Volunteer quota reached ($capacity/$capacity). Registration is full.');
    }

    await db.insert('TaskRegistrations', {
      'TaskID': taskId,
      'UserID': userId,
      'Status': 'Accepted',
    });
  }

  Future<void> cancelTaskRegistration(int taskId, int userId) async {
    final db = await instance.database;
    final rows = await db.query(
      'TaskRegistrations',
      where: 'TaskID = ? AND UserID = ?',
      whereArgs: [taskId, userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw Exception('You are not registered for this task.');
    }

    await db.update(
      'TaskRegistrations',
      {'Status': 'Cancelled'},
      where: 'TaskID = ? AND UserID = ?',
      whereArgs: [taskId, userId],
    );
  }

  Future<List<TaskModel>> getUserTasks(int userId, {String? status}) async {
    final db = await instance.database;

    String query = '''
      SELECT 
        t.*,
        COUNT(CASE WHEN all_reg.Status = 'Accepted' THEN 1 END) AS RegisteredCount,
        r.Status as MyRegistrationStatus
      FROM TaskRegistrations r
      INNER JOIN Tasks t ON r.TaskID = t.TaskID
      LEFT JOIN TaskRegistrations all_reg ON t.TaskID = all_reg.TaskID
      WHERE r.UserID = ?
    ''';

    final args = <dynamic>[userId];

    if (status != null && status.isNotEmpty && status != 'All') {
      if (status == 'Upcoming') {
        query += " AND (r.Status = 'Accepted' AND t.Status IN ('Available', 'In Progress'))";
      } else {
        query += " AND r.Status = ?";
        args.add(status);
      }
    }

    query += ' GROUP BY t.TaskID, r.RegistrationID ORDER BY t.TaskID DESC';

    final rows = await db.rawQuery(query, args);

    final tasks = <TaskModel>[];
    for (final row in rows) {
      final taskId = row['TaskID'] as int;
      final images = await _getTaskImages(db, taskId);

      final map = Map<String, dynamic>.from(row);
      map['Images'] = images;
      tasks.add(TaskModel.fromJson(map));
    }
    return tasks;
  }

  Future<List<TaskRegistrationModel>> getTaskVolunteers(int taskId) async {
    final db = await instance.database;

    final query = '''
      SELECT 
        r.RegistrationID,
        r.TaskID,
        r.UserID,
        r.RegistrationDate,
        r.Status,
        u.Name as VolunteerName,
        u.Email as VolunteerEmail,
        u.Phone as VolunteerPhone
      FROM TaskRegistrations r
      INNER JOIN Users u ON r.UserID = u.UserID
      WHERE r.TaskID = ?
      ORDER BY r.RegistrationID DESC
    ''';

    final rows = await db.rawQuery(query, [taskId]);
    return rows.map((r) => TaskRegistrationModel.fromJson(r)).toList();
  }

  // ==========================================
  // LOCAL IMAGE STORAGE
  // ==========================================

  Future<String> saveImageLocally(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'task_${DateTime.now().millisecondsSinceEpoch}_${basename(file.path)}';
    final savedImage = await file.copy('${appDir.path}/$fileName');
    return savedImage.path;
  }
}
