#!/usr/bin/env node

/**
 * Database Initialization Script
 *
 * This script initializes the PostgreSQL database by:
 * 1. Running migrations (creating all tables)
 * 2. Optionally seeding sample data for development
 *
 * Usage:
 *   node scripts/init-db.js [--seed]
 */

require('dotenv').config();
const { runMigrations, seedData, dropAllTables } = require('../src/database/migrations');
const { connectPostgreSQL } = require('../src/config/postgres');
const logger = require('../src/utils/logger');

const args = process.argv.slice(2);
const shouldSeed = args.includes('--seed');
const shouldDrop = args.includes('--drop');

async function initializeDatabase() {
  try {
    logger.info('Starting database initialization...');

    // Connect to PostgreSQL
    await connectPostgreSQL();

    // Drop tables if requested
    if (shouldDrop) {
      logger.warn('Dropping all existing tables...');
      await dropAllTables();
    }

    // Run migrations
    logger.info('Running database migrations...');
    await runMigrations();
    logger.info('✓ Database migrations completed successfully');

    // Seed data if requested
    if (shouldSeed) {
      logger.info('Seeding sample data...');
      await seedData();
      logger.info('✓ Database seeding completed successfully');
    }

    logger.info('🎉 Database initialization completed!');
    process.exit(0);
  } catch (error) {
    logger.error('Database initialization failed:', error);
    process.exit(1);
  }
}

// Show usage information
if (args.includes('--help') || args.includes('-h')) {
  console.log(`
Database Initialization Script

Usage:
  node scripts/init-db.js [options]

Options:
  --seed    Seed sample data for development
  --drop    Drop all existing tables before migration (WARNING: destructive)
  --help    Show this help message

Examples:
  node scripts/init-db.js                 # Run migrations only
  node scripts/init-db.js --seed          # Run migrations and seed data
  node scripts/init-db.js --drop --seed   # Drop, migrate, and seed
  `);
  process.exit(0);
}

initializeDatabase();
