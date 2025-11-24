const express = require('express');
const router = express.Router();
const focusController = require('../controllers/focusController');
const { authenticate } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/v1/focus
 * @desc    Get all focus sessions (with filters)
 * @access  Private
 */
router.get('/', focusController.getFocusSessions);

/**
 * @route   GET /api/v1/focus/today
 * @desc    Get today's focus sessions with statistics
 * @access  Private
 */
router.get('/today', focusController.getTodayFocusSessions);

/**
 * @route   GET /api/v1/focus/statistics
 * @desc    Get focus statistics
 * @access  Private
 */
router.get('/statistics', focusController.getFocusStatistics);

/**
 * @route   GET /api/v1/focus/:id
 * @desc    Get single focus session
 * @access  Private
 */
router.get('/:id', focusController.getFocusSession);

/**
 * @route   POST /api/v1/focus
 * @desc    Start new focus session
 * @access  Private
 */
router.post('/', focusController.startFocusSession);

/**
 * @route   PUT /api/v1/focus/:id/complete
 * @desc    Complete focus session
 * @access  Private
 */
router.put('/:id/complete', focusController.completeFocusSession);

/**
 * @route   PUT /api/v1/focus/:id/cancel
 * @desc    Cancel/interrupt focus session
 * @access  Private
 */
router.put('/:id/cancel', focusController.cancelFocusSession);

module.exports = router;
