const express = require('express');
const router = express.Router();
const studyRoomController = require('../controllers/studyRoomController');
const { authenticate, requireStudyRoomAccess } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/v1/study-rooms
 * @desc    Get all study rooms (with filters)
 * @access  Private
 */
router.get('/', studyRoomController.getStudyRooms);

/**
 * @route   GET /api/v1/study-rooms/my
 * @desc    Get user's study rooms
 * @access  Private
 */
router.get('/my', studyRoomController.getMyStudyRooms);

/**
 * @route   GET /api/v1/study-rooms/:id
 * @desc    Get single study room with participants
 * @access  Private
 */
router.get('/:id', studyRoomController.getStudyRoom);

/**
 * @route   POST /api/v1/study-rooms
 * @desc    Create new study room (requires eligibility)
 * @access  Private (with study room access)
 */
router.post('/', requireStudyRoomAccess, studyRoomController.createStudyRoom);

/**
 * @route   POST /api/v1/study-rooms/:id/join
 * @desc    Join study room
 * @access  Private
 */
router.post('/:id/join', studyRoomController.joinStudyRoom);

/**
 * @route   POST /api/v1/study-rooms/:id/leave
 * @desc    Leave study room
 * @access  Private
 */
router.post('/:id/leave', studyRoomController.leaveStudyRoom);

/**
 * @route   PUT /api/v1/study-rooms/:id/energy
 * @desc    Update participant energy level and focus state
 * @access  Private
 */
router.put('/:id/energy', studyRoomController.updateEnergyLevel);

/**
 * @route   POST /api/v1/study-rooms/:id/start
 * @desc    Start study room session (creator only)
 * @access  Private
 */
router.post('/:id/start', studyRoomController.startStudyRoom);

module.exports = router;
