const express = require('express');
const cors = require('cors');
require('dotenv').config();

console.log('Loading auth routes...');
const authRoutes = require('./src/routes/auth');

const app = express();

app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json());

app.use('/api/auth', authRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'OK with auth routes', timestamp: new Date().toISOString() });
});

const PORT = 3002;

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server with auth on http://localhost:${PORT}`);
});

setInterval(() => {}, 1000);
