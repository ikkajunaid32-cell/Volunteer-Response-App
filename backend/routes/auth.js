const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const { authenticateToken, JWT_SECRET } = require('../middleware/auth');

// Register a new user (Volunteer or Admin)
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, phone, role } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: 'Name, email, and password are required' });
    }

    const assignedRole = role === 'admin' ? 'admin' : 'volunteer';

    // Check if user already exists
    const existing = await db.getAsync('SELECT UserID FROM Users WHERE Email = ?', [email.toLowerCase().trim()]);
    if (existing) {
      return res.status(409).json({ success: false, message: 'An account with this email already exists' });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // Insert user into SQL database
    const result = await db.runAsync(
      `INSERT INTO Users (Name, Email, PasswordHash, Phone, Role) VALUES (?, ?, ?, ?, ?)`,
      [name.trim(), email.toLowerCase().trim(), passwordHash, phone ? phone.trim() : null, assignedRole]
    );

    const userId = result.lastID;
    const token = jwt.sign({ id: userId, email: email.toLowerCase().trim(), role: assignedRole, name }, JWT_SECRET, { expiresIn: '7d' });

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      token,
      user: {
        userId,
        name: name.trim(),
        email: email.toLowerCase().trim(),
        phone: phone ? phone.trim() : null,
        role: assignedRole
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ success: false, message: 'Internal server error during registration' });
  }
});

// Login user
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required' });
    }

    const user = await db.getAsync('SELECT * FROM Users WHERE Email = ?', [email.toLowerCase().trim()]);
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    const isMatch = await bcrypt.compare(password, user.PasswordHash);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    const token = jwt.sign(
      { id: user.UserID, email: user.Email, role: user.Role, name: user.Name },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        userId: user.UserID,
        name: user.Name,
        email: user.Email,
        phone: user.Phone,
        role: user.Role,
        createdDate: user.CreatedDate
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, message: 'Internal server error during login' });
  }
});

// Get current user profile
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const user = await db.getAsync(
      'SELECT UserID, Name, Email, Phone, Role, CreatedDate FROM Users WHERE UserID = ?',
      [req.user.id]
    );

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({
      success: true,
      user: {
        userId: user.UserID,
        name: user.Name,
        email: user.Email,
        phone: user.Phone,
        role: user.Role,
        createdDate: user.CreatedDate
      }
    });
  } catch (error) {
    console.error('Profile error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

module.exports = router;
