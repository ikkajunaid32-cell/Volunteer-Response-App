const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const db = require('./db');
const authRoutes = require('./routes/auth');
const taskRoutes = require('./routes/tasks');
const registrationRoutes = require('./routes/registrations');
const uploadRoutes = require('./routes/upload');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploaded images statically
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/registrations', registrationRoutes);
app.use('/api/upload', uploadRoutes);

// Health Check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'Volunteer Task Management API',
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled Server Error:', err);
  res.status(500).json({
    success: false,
    message: err.message || 'An unexpected server error occurred'
  });
});

// Start listening on all network interfaces (0.0.0.0) so emulators & devices can connect
app.listen(PORT, '0.0.0.0', () => {
  console.log(`=======================================================`);
  console.log(` Volunteer Response Backend API Server is running`);
  console.log(` Local:            http://localhost:${PORT}`);
  console.log(` Android Emulator: http://10.0.2.2:${PORT}`);
  console.log(` Health check:     http://localhost:${PORT}/api/health`);
  console.log(`=======================================================`);
});

module.exports = app;
