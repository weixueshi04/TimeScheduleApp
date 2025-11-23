const express = require('express');
const router = express.Router();
const healthController = require('../controllers/healthController');
const { authenticate } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/v1/health
 * @desc    Get health records (with filters)
 * @access  Private
 */
router.get('/', healthController.getHealthRecords);

/**
 * @route   GET /api/v1/health/today
 * @desc    Get today's health record
 * @access  Private
 */
router.get('/today', healthController.getTodayHealthRecord);

/**
 * @route   GET /api/v1/health/statistics
 * @desc    Get health statistics
 * @access  Private
 */
router.get('/statistics', healthController.getHealthStatistics);

/**
 * @route   GET /api/v1/health/trends
 * @desc    Get health trends (daily data for charts)
 * @access  Private
 */
router.get('/trends', healthController.getHealthTrends);

/**
 * @route   GET /api/v1/health/:date
 * @desc    Get health record for specific date
 * @access  Private
 */
router.get('/:date', healthController.getHealthRecord);

/**
 * @route   POST /api/v1/health
 * @desc    Create or update health record
 * @access  Private
 */
router.post('/', healthController.upsertHealthRecord);

/**
 * @route   DELETE /api/v1/health/:date
 * @desc    Delete health record
 * @access  Private
 */
router.delete('/:date', healthController.deleteHealthRecord);

module.exports = router;
