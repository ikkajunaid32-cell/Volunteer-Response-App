const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticateToken, requireRole } = require('../middleware/auth');
const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../middleware/auth');

// Helper to extract user if token is provided optionally
function optionalAuth(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (token) {
    try {
      req.user = jwt.verify(token, JWT_SECRET);
    } catch (e) {
      // Ignore token verification errors in optional auth
    }
  }
  next();
}

// 1. GET /api/tasks - List all tasks with volunteer counts and user registration status
router.get('/', optionalAuth, async (req, res) => {
  try {
    const { status, search } = req.query;
    let sql = `
      SELECT 
        t.*,
        u.Name as CreatorName,
        COUNT(CASE WHEN tr.Status = 'Accepted' THEN 1 END) as RegisteredCount
      FROM Tasks t
      LEFT JOIN Users u ON t.CreatedBy = u.UserID
      LEFT JOIN TaskRegistrations tr ON t.TaskID = tr.TaskID
    `;

    const whereClauses = [];
    const params = [];

    if (status && status !== 'All') {
      whereClauses.push('t.Status = ?');
      params.push(status);
    }

    if (search && search.trim() !== '') {
      whereClauses.push('(t.TaskName LIKE ? OR t.Description LIKE ? OR t.Location LIKE ?)');
      const term = `%${search.trim()}%`;
      params.push(term, term, term);
    }

    if (whereClauses.length > 0) {
      sql += ' WHERE ' + whereClauses.join(' AND ');
    }

    sql += ' GROUP BY t.TaskID ORDER BY t.TaskDate ASC, t.StartTime ASC';

    const tasks = await db.allAsync(sql, params);

    // If a volunteer user is authenticated, determine whether they have accepted each task
    if (req.user && req.user.id) {
      const userRegs = await db.allAsync(
        'SELECT TaskID, Status FROM TaskRegistrations WHERE UserID = ?',
        [req.user.id]
      );
      const regMap = {};
      userRegs.forEach(r => { regMap[r.TaskID] = r.Status; });

      tasks.forEach(task => {
        task.userRegistrationStatus = regMap[task.TaskID] || null;
        task.isUserRegistered = regMap[task.TaskID] === 'Accepted';
      });
    }

    res.json({ success: true, count: tasks.length, tasks });
  } catch (error) {
    console.error('Fetch tasks error:', error);
    res.status(500).json({ success: false, message: 'Failed to retrieve tasks' });
  }
});

// 2. GET /api/tasks/:id - Detailed task information
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const taskId = req.params.id;

    const task = await db.getAsync(`
      SELECT 
        t.*,
        u.Name as CreatorName,
        COUNT(CASE WHEN tr.Status = 'Accepted' THEN 1 END) as RegisteredCount
      FROM Tasks t
      LEFT JOIN Users u ON t.CreatedBy = u.UserID
      LEFT JOIN TaskRegistrations tr ON t.TaskID = tr.TaskID
      WHERE t.TaskID = ?
      GROUP BY t.TaskID
    `, [taskId]);

    if (!task) {
      return res.status(404).json({ success: false, message: 'Task not found' });
    }

    // Fetch associated task images
    const images = await db.allAsync(
      'SELECT ImageID, ImageURL, UploadedDate FROM TaskImages WHERE TaskID = ? ORDER BY ImageID ASC',
      [taskId]
    );
    task.images = images.map(img => img.ImageURL);

    // If main ImageURL isn't in images list, prepend it
    if (task.ImageURL && !task.images.includes(task.ImageURL)) {
      task.images.unshift(task.ImageURL);
    }

    // Check user registration status
    if (req.user && req.user.id) {
      const userReg = await db.getAsync(
        'SELECT Status FROM TaskRegistrations WHERE TaskID = ? AND UserID = ?',
        [taskId, req.user.id]
      );
      task.userRegistrationStatus = userReg ? userReg.Status : null;
      task.isUserRegistered = userReg ? userReg.Status === 'Accepted' : false;
    }

    // If admin requested, also fetch the list of registered volunteers
    if (req.user && req.user.role === 'admin') {
      const volunteers = await db.allAsync(`
        SELECT 
          tr.RegistrationID,
          tr.RegistrationDate,
          tr.Status as RegistrationStatus,
          u.UserID,
          u.Name,
          u.Email,
          u.Phone
        FROM TaskRegistrations tr
        JOIN Users u ON tr.UserID = u.UserID
        WHERE tr.TaskID = ?
        ORDER BY tr.RegistrationDate DESC
      `, [taskId]);
      task.registeredVolunteers = volunteers;
    }

    res.json({ success: true, task });
  } catch (error) {
    console.error('Fetch task details error:', error);
    res.status(500).json({ success: false, message: 'Failed to retrieve task details' });
  }
});

// 3. POST /api/tasks - Create task (Admin only)
router.post('/', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const {
      taskName,
      description,
      imageUrl,
      location,
      latitude,
      longitude,
      taskDate,
      startTime,
      endTime,
      volunteersRequired,
      status,
      additionalImages
    } = req.body;

    if (!taskName || !description || !location || !taskDate || !startTime) {
      return res.status(400).json({
        success: false,
        message: 'Task name, description, location, task date, and start time are required'
      });
    }

    const taskStatus = status || 'Available';
    const reqVolunteers = parseInt(volunteersRequired, 10) || 1;

    const result = await db.runAsync(`
      INSERT INTO Tasks (
        TaskName, Description, ImageURL, Location, Latitude, Longitude,
        TaskDate, StartTime, EndTime, VolunteersRequired, Status, CreatedBy
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      taskName.trim(),
      description.trim(),
      imageUrl || null,
      location.trim(),
      latitude || null,
      longitude || null,
      taskDate.trim(),
      startTime.trim(),
      endTime ? endTime.trim() : null,
      reqVolunteers,
      taskStatus,
      req.user.id
    ]);

    const newTaskId = result.lastID;

    // Insert main image if provided
    if (imageUrl) {
      await db.runAsync(
        'INSERT INTO TaskImages (TaskID, ImageURL) VALUES (?, ?)',
        [newTaskId, imageUrl]
      );
    }

    // Insert additional images if provided
    if (Array.isArray(additionalImages) && additionalImages.length > 0) {
      for (const img of additionalImages) {
        if (img && img !== imageUrl) {
          await db.runAsync(
            'INSERT INTO TaskImages (TaskID, ImageURL) VALUES (?, ?)',
            [newTaskId, img]
          );
        }
      }
    }

    res.status(201).json({
      success: true,
      message: 'Task created successfully',
      taskId: newTaskId
    });
  } catch (error) {
    console.error('Create task error:', error);
    res.status(500).json({ success: false, message: 'Failed to create task' });
  }
});

// 4. PUT /api/tasks/:id - Update task (Admin only)
router.put('/:id', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const taskId = req.params.id;
    const {
      taskName,
      description,
      imageUrl,
      location,
      latitude,
      longitude,
      taskDate,
      startTime,
      endTime,
      volunteersRequired,
      status,
      additionalImages
    } = req.body;

    const existing = await db.getAsync('SELECT * FROM Tasks WHERE TaskID = ?', [taskId]);
    if (!existing) {
      return res.status(404).json({ success: false, message: 'Task not found' });
    }

    await db.runAsync(`
      UPDATE Tasks SET
        TaskName = COALESCE(?, TaskName),
        Description = COALESCE(?, Description),
        ImageURL = COALESCE(?, ImageURL),
        Location = COALESCE(?, Location),
        Latitude = COALESCE(?, Latitude),
        Longitude = COALESCE(?, Longitude),
        TaskDate = COALESCE(?, TaskDate),
        StartTime = COALESCE(?, StartTime),
        EndTime = COALESCE(?, EndTime),
        VolunteersRequired = COALESCE(?, VolunteersRequired),
        Status = COALESCE(?, Status)
      WHERE TaskID = ?
    `, [
      taskName ? taskName.trim() : null,
      description ? description.trim() : null,
      imageUrl,
      location ? location.trim() : null,
      latitude,
      longitude,
      taskDate,
      startTime,
      endTime,
      volunteersRequired ? parseInt(volunteersRequired, 10) : null,
      status,
      taskId
    ]);

    // Update images if provided
    if (Array.isArray(additionalImages)) {
      await db.runAsync('DELETE FROM TaskImages WHERE TaskID = ?', [taskId]);
      if (imageUrl) {
        await db.runAsync('INSERT INTO TaskImages (TaskID, ImageURL) VALUES (?, ?)', [taskId, imageUrl]);
      }
      for (const img of additionalImages) {
        if (img && img !== imageUrl) {
          await db.runAsync('INSERT INTO TaskImages (TaskID, ImageURL) VALUES (?, ?)', [taskId, img]);
        }
      }
    }

    res.json({ success: true, message: 'Task updated successfully' });
  } catch (error) {
    console.error('Update task error:', error);
    res.status(500).json({ success: false, message: 'Failed to update task' });
  }
});

// 5. DELETE /api/tasks/:id - Delete task (Admin only)
router.delete('/:id', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const taskId = req.params.id;

    const existing = await db.getAsync('SELECT * FROM Tasks WHERE TaskID = ?', [taskId]);
    if (!existing) {
      return res.status(404).json({ success: false, message: 'Task not found' });
    }

    await db.runAsync('DELETE FROM Tasks WHERE TaskID = ?', [taskId]);

    res.json({ success: true, message: 'Task deleted successfully' });
  } catch (error) {
    console.error('Delete task error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete task' });
  }
});

module.exports = router;
