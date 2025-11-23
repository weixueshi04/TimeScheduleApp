const express = require('express');
const router = express.Router();
const taskController = require('../controllers/taskController');
const { authenticate } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/v1/tasks
 * @desc    Get all tasks for current user (with filters)
 * @access  Private
 */
router.get('/', taskController.getTasks);

/**
 * @route   GET /api/v1/tasks/today
 * @desc    Get today's tasks
 * @access  Private
 */
router.get('/today', taskController.getTodayTasks);

/**
 * @route   GET /api/v1/tasks/statistics
 * @desc    Get task statistics
 * @access  Private
 */
router.get('/statistics', taskController.getTaskStatistics);

/**
 * @route   GET /api/v1/tasks/:id
 * @desc    Get single task
 * @access  Private
 */
router.get('/:id', taskController.getTask);

/**
 * @route   POST /api/v1/tasks
 * @desc    Create new task
 * @access  Private
 */
router.post('/', taskController.createTask);

/**
 * @route   PUT /api/v1/tasks/:id
 * @desc    Update task
 * @access  Private
 */
router.put('/:id', taskController.updateTask);

/**
 * @route   PUT /api/v1/tasks/:id/complete
 * @desc    Complete task
 * @access  Private
 */
router.put('/:id/complete', taskController.completeTask);

/**
 * @route   DELETE /api/v1/tasks/:id
 * @desc    Delete task (soft delete)
 * @access  Private
 */
router.delete('/:id', taskController.deleteTask);

module.exports = router;
