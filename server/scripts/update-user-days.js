#!/usr/bin/env node

/**
 * Update User Registration Days Script
 *
 * This script updates the days_since_registration field for all users.
 * Should be run daily via cron job or scheduled task.
 *
 * Usage:
 *   node scripts/update-user-days.js
 */

require('dotenv').config();
const { query } = require('../src/config/postgres');
const { connectPostgreSQL } = require('../src/config/postgres');
const logger = require('../src/utils/logger');

async function updateUserDays() {
  try {
    logger.info('Starting user registration days update...');

    // Connect to PostgreSQL
    await connectPostgreSQL();

    // Update all users' days_since_registration
    const result = await query(`
      UPDATE users
      SET days_since_registration = EXTRACT(DAY FROM (CURRENT_TIMESTAMP - created_at))
      WHERE status = 'active'
      RETURNING id, username, days_since_registration
    `);

    logger.info(`✓ Updated ${result.rowCount} users`);

    // Check and update study room eligibility
    const eligibilityResult = await query(`
      UPDATE users
      SET can_create_study_room = true
      WHERE status = 'active'
        AND can_create_study_room = false
        AND days_since_registration >= 3
        AND (total_focus_sessions >= 5 OR total_focus_hours >= 3)
      RETURNING id, username
    `);

    if (eligibilityResult.rowCount > 0) {
      logger.info(`✓ ${eligibilityResult.rowCount} users now eligible for study rooms`);
    }

    logger.info('🎉 User registration days update completed!');
    process.exit(0);
  } catch (error) {
    logger.error('Update failed:', error);
    process.exit(1);
  }
}

updateUserDays();
