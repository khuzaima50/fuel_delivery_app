const express = require('express');
const Redis = require('ioredis');
const bodyParser = require('body-parser');

const app = express();
const port = process.env.PORT || 4111;

// Initialize Redis client
const redis = new Redis();

app.use(bodyParser.json());

// Logger middleware for visibility
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// v1: Activity Status Endpoints

/**
 * POST /v1/user/set-activity-status
 * Sets the activity status for a user and updates their last active timestamp.
 */
app.post('/v1/user/set-activity-status', async (req, res) => {
  const { clientId, userId, status } = req.body;

  if (!clientId || !userId || !status) {
    return res.status(400).json({ error: 'Missing parameters: clientId, userId, and status are required' });
  }

  try {
    const statusKey = `activity_status:${clientId}:${userId}`;
    const lastActiveKey = `last_active:${clientId}:${userId}`;
    const timestamp = Date.now();

    // Store status and last active timestamp in Redis
    await redis.set(statusKey, status);
    await redis.set(lastActiveKey, timestamp);

    res.status(200).json({ status: 'Status updated successfully', timestamp });
  } catch (error) {
    console.error('Redis error setting status:', error);
    res.status(500).json({ error: 'Unable to set user status' });
  }
});

/**
 * GET /v1/user/get-activity-status
 * Retrieves the current activity status of a user.
 */
app.get('/v1/user/get-activity-status', async (req, res) => {
  const { clientId, userId } = req.query;

  if (!clientId || !userId) {
    return res.status(400).json({ error: 'Missing parameters: clientId and userId are required' });
  }

  try {
    const statusKey = `activity_status:${clientId}:${userId}`;
    const status = await redis.get(statusKey);

    if (status === null) {
      return res.status(404).json({ error: 'User status not found' });
    }

    res.status(200).json({ status });
  } catch (error) {
    console.error('Redis error getting status:', error);
    res.status(500).json({ error: 'Unable to retrieve user status' });
  }
});

// Basic health check
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Start the server
app.listen(port, () => {
  console.log(`Presence Service API listening on port ${port}`);
});
