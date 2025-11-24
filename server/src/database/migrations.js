const fs = require('fs');
const path = require('path');
const { query } = require('../config/postgres');
const logger = require('../utils/logger');

/**
 * Run database migrations
 */
async function runMigrations() {
  try {
    logger.info('Starting database migrations...');

    // Read schema file
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');

    // Split schema into individual statements
    const statements = schema
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));

    // Execute each statement
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      try {
        await query(statement);
        logger.debug(`Migration statement ${i + 1}/${statements.length} executed successfully`);
      } catch (error) {
        logger.error(`Error executing migration statement ${i + 1}:`, error);
        throw error;
      }
    }

    logger.info('Database migrations completed successfully');
    return true;
  } catch (error) {
    logger.error('Database migration failed:', error);
    throw error;
  }
}

/**
 * Seed initial data for development
 */
async function seedData() {
  try {
    logger.info('Starting database seeding...');

    // Check if data already exists
    const userCount = await query('SELECT COUNT(*) FROM users');
    if (parseInt(userCount.rows[0].count) > 0) {
      logger.info('Database already contains data, skipping seed');
      return false;
    }

    // Seed sample data (optional, for development only)
    // You can add sample users, tasks, etc. here

    logger.info('Database seeding completed successfully');
    return true;
  } catch (error) {
    logger.error('Database seeding failed:', error);
    throw error;
  }
}

/**
 * Drop all tables (WARNING: destructive operation)
 */
async function dropAllTables() {
  try {
    logger.warn('Dropping all tables...');

    const tables = [
      'notifications',
      'user_follows',
      'user_rapport',
      'study_room_events',
      'study_room_participants',
      'study_rooms',
      'health_records',
      'focus_sessions',
      'tasks',
      'refresh_tokens',
      'users',
    ];

    for (const table of tables) {
      try {
        await query(`DROP TABLE IF EXISTS ${table} CASCADE`);
        logger.debug(`Dropped table: ${table}`);
      } catch (error) {
        logger.warn(`Error dropping table ${table}:`, error.message);
      }
    }

    logger.warn('All tables dropped');
    return true;
  } catch (error) {
    logger.error('Error dropping tables:', error);
    throw error;
  }
}

module.exports = {
  runMigrations,
  seedData,
  dropAllTables,
};
