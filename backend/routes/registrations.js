const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticateToken, requireRole } = require('../middleware/auth');

// 1. Volunteer accepts a task
router.post('/task/:taskId/apply', authenticateToken, async (req, res) => {
  try {
    const taskId = req.params.taskId;
    const userId = req.user.id;

    // Verify task exists
    const task = await db.getAsync(`
      SELECT 
        t.*,
        COUNT(CASE WHEN tr.Status = 'Accepted' THEN 1 END) as AcceptedCount
      FROM Tasks t
      LEFT JOIN TaskRegistrations tr ON t.TaskID = tr.TaskID
      WHERE t.TaskID = ?
      GROUP BY t.TaskID
    `, [taskId]);

    if (!task) {
      return res.status(404).json({ success: false, message: 'Task not found' });
    }

    if (task.Status === 'Completed' || task.Status === 'Cancelled') {
      return res.status(400).json({
        success: false,
        message: `Cannot register for a ${task.Status.toLowerCase()} task`
      });
    }

    // Check if task is already full
    if (task.AcceptedCount >= task.VolunteersRequired) {
      return res.status(400).json({
        success: false,
        message: 'This task has already reached its required volunteer limit'
      });
    }

    // Check if user already registered
    const existing = await db.getAsync(
      'SELECT * FROM TaskRegistrations WHERE TaskID = ? AND UserID = ?',
      [taskId, userId]
    );

    if (existing) {
      if (existing.Status === 'Accepted') {
        return res.status(400).json({
          success: false,
          message: 'You have already accepted this task'
        });
      } else {
        // Re-activate registration
        await db.runAsync(
          'UPDATE TaskRegistrations SET Status = ?, RegistrationDate = CURRENT_TIMESTAMP WHERE RegistrationID = ?',
          ['Accepted', existing.RegistrationID]
        );
        return res.json({
          success: true,
          message: 'Task accepted successfully',
          registrationId: existing.RegistrationID
        });
      }
    }

    // Insert new registration
    const result = await db.runAsync(
      'INSERT INTO TaskRegistrations (TaskID, UserID, Status) VALUES (?, ?, ?)',
      [taskId, userId, 'Accepted']
    );

    res.status(201).json({
      success: true,
      message: 'Task accepted successfully',
      registrationId: result.lastID
    });
  } catch (error) {
    console.error('Task apply error:', error);
    res.status(500).json({ success: false, message: 'Failed to accept task' });
  }
});

// 2. Volunteer cancels their registration
router.post('/task/:taskId/cancel', authenticateToken, async (req, res) => {
  try {
    const taskId = req.params.taskId;
    const userId = req.user.id;

    const existing = await db.getAsync(
      'SELECT * FROM TaskRegistrations WHERE TaskID = ? AND UserID = ?',
      [taskId, userId]
    );

    if (!existing) {
      return res.status(404).json({ success: false, message: 'You have not registered for this task' });
    }

    await db.runAsync(
      'UPDATE TaskRegistrations SET Status = ? WHERE RegistrationID = ?',
      ['Cancelled', existing.RegistrationID]
    );

    res.json({ success: true, message: 'Task registration cancelled' });
  } catch (error) {
    console.error('Task cancel registration error:', error);
    res.status(500).json({ success: false, message: 'Failed to cancel task registration' });
  }
});

// 3. Get volunteer's registered tasks ("My Tasks")
router.get('/my-tasks', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { status } = req.query; // 'Upcoming', 'Accepted', 'Completed', 'Cancelled', or 'All'

    let sql = `
      SELECT 
        tr.RegistrationID,
        tr.RegistrationDate,
        tr.Status as RegistrationStatus,
        t.*,
        (SELECT COUNT(*) FROM TaskRegistrations tr2 WHERE tr2.TaskID = t.TaskID AND tr2.Status = 'Accepted') as RegisteredCount
      FROM TaskRegistrations tr
      JOIN Tasks t ON tr.TaskID = t.TaskID
      WHERE tr.UserID = ?
    `;

    const params = [userId];

    if (status && status !== 'All') {
      if (status === 'Upcoming') {
        // Upcoming = RegistrationStatus 'Accepted' and task status not completed/cancelled
        sql += ` AND tr.Status = 'Accepted' AND t.Status IN ('Available', 'In Progress')`;
      } else {
        sql += ` AND tr.Status = ?`;
        params.push(status);
      }
    }

    sql += ' ORDER BY t.TaskDate ASC, t.StartTime ASC';

    const myTasks = await db.allAsync(sql, params);

    res.json({ success: true, count: myTasks.length, tasks: myTasks });
  } catch (error) {
    console.error('Fetch my-tasks error:', error);
    res.status(500).json({ success: false, message: 'Failed to retrieve your tasks' });
  }
});

// 4. Admin views volunteers who accepted a specific task
router.get('/task/:taskId/volunteers', authenticateToken, requireRole('admin'), async (req, res) => {
  try {
    const taskId = req.params.taskId;

    const task = await db.getAsync('SELECT TaskID, TaskName, VolunteersRequired, Status FROM Tasks WHERE TaskID = ?', [taskId]);
    if (!task) {
      return res.status(404).json({ success: false, message: 'Task not found' });
    }

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

    res.json({
      success: true,
      task,
      totalRegistered: volunteers.filter(v => v.RegistrationStatus === 'Accepted').length,
      volunteers
    });
  } catch (error) {
    console.error('Fetch task volunteers error:', error);
    res.status(500).json({ success: false, message: 'Failed to retrieve volunteers list' });
  }
});

// 5. Update Registration Status (e.g. mark volunteer as completed)
router.put('/:registrationId/status', authenticateToken, async (req, res) => {
  try {
    const { registrationId } = req.params;
    const { status } = req.body; // 'Accepted', 'Completed', 'Cancelled'

    if (!['Accepted', 'Completed', 'Cancelled'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid registration status' });
    }

    await db.runAsync('UPDATE TaskRegistrations SET Status = ? WHERE RegistrationID = ?', [status, registrationId]);

    res.json({ success: true, message: 'Registration status updated' });
  } catch (error) {
    console.error('Update registration status error:', error);
    res.status(500).json({ success: false, message: 'Failed to update registration status' });
  }
});

module.exports = router;
