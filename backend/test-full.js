const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./src/routes/auth');
const userRoutes = require('./src/routes/users');
const customerRoutes = require('./src/routes/customers');
const documentRoutes = require('./src/routes/documents');

const app = express();

app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/documents', documentRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'OK - all routes', timestamp: new Date().toISOString() });
});

const PORT = 3003;

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Full server on http://localhost:${PORT}`);
});

setInterval(() => {}, 1000);
