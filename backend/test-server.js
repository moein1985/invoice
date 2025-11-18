const express = require('express');
const cors = require('cors');
require('dotenv').config();

console.log('1. Loading routes...');

try {
  const authRoutes = require('./src/routes/auth');
  console.log('2. Auth routes loaded');
  
  const userRoutes = require('./src/routes/users');
  console.log('3. User routes loaded');
  
  const customerRoutes = require('./src/routes/customers');
  console.log('4. Customer routes loaded');
  
  const documentRoutes = require('./src/routes/documents');
  console.log('5. Document routes loaded');

  const app = express();

  console.log('6. Configuring middleware...');
  app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  console.log('7. Registering routes...');
  app.use('/api/auth', authRoutes);
  app.use('/api/users', userRoutes);
  app.use('/api/customers', customerRoutes);
  app.use('/api/documents', documentRoutes);

  app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
  });

  console.log('8. Starting server...');
  const PORT = process.env.PORT || 3000;

  const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`\n🚀 Server running on http://localhost:${PORT}`);
    console.log(`📝 API Documentation: http://localhost:${PORT}/api`);
    console.log(`💚 Health Check: http://localhost:${PORT}/health\n`);
  });

  server.on('error', (err) => {
    console.error('Server error:', err);
  });

  console.log('9. Listening...');

} catch (error) {
  console.error('Failed to start server:', error);
  process.exit(1);
}
