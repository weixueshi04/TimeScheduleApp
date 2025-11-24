import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../business/providers/study_room_provider.dart';
import '../../business/providers/auth_provider.dart';
import '../../data/models/study_room.dart';

class StudyRoomDetailScreen extends StatefulWidget {
  final StudyRoom room;

  const StudyRoomDetailScreen({
    super.key,
    required this.room,
  });

  @override
  State<StudyRoomDetailScreen> createState() => _StudyRoomDetailScreenState();
}

class _StudyRoomDetailScreenState extends State<StudyRoomDetailScreen> {
  final TextEditingController _chatController = TextEditingController();
  Timer? _energyUpdateTimer;
  int _currentEnergy = 100;
  String _currentFocusState = 'focused';

  @override
  void initState() {
    super.initState();
    _startEnergyUpdates();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _energyUpdateTimer?.cancel();
    super.dispose();
  }

  // Simulate energy updates (in real app, this would be based on user activity)
  void _startEnergyUpdates() {
    _energyUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentFocusState == 'focused') {
        // Send energy update to server
        context.read<StudyRoomProvider>().updateEnergy(
              _currentEnergy,
              _currentFocusState,
            );
      }
    });
  }

  Future<void> _leaveRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('离开自习室'),
        content: const Text('确定要离开自习室吗？\n提前离开可能会有惩罚时间。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('离开'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final provider = context.read<StudyRoomProvider>();

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.leaveStudyRoom();

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (success) {
      Navigator.pop(context); // Return to list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已离开自习室')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('离开失败: ${provider.errorMessage ?? "未知错误"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendChatMessage() {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;

    context.read<StudyRoomProvider>().sendChatMessage(message);
    _chatController.clear();

    // Show local feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('消息已发送'), duration: Duration(seconds: 1)),
    );
  }

  void _showEnergySlider() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '调整专注状态',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text('能量值:'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Slider(
                        value: _currentEnergy.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: '$_currentEnergy%',
                        onChanged: (value) {
                          setState(() => _currentEnergy = value.toInt());
                        },
                      ),
                    ),
                    Text('$_currentEnergy%'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('专注状态:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('专注中'),
                      selected: _currentFocusState == 'focused',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _currentFocusState = 'focused');
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('休息中'),
                      selected: _currentFocusState == 'break',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _currentFocusState = 'break');
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('分心了'),
                      selected: _currentFocusState == 'distracted',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _currentFocusState = 'distracted');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.read<StudyRoomProvider>().updateEnergy(
                          _currentEnergy,
                          _currentFocusState,
                        );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('更新状态'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final studyRoomProvider = context.watch<StudyRoomProvider>();
    final currentUser = authProvider.currentUser;
    final room = studyRoomProvider.currentRoom ?? widget.room;
    final participants = room.participants ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(room.name ?? '自习室 ${room.roomCode}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              // Show participants list
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Room info header
          _buildRoomInfoCard(room),

          // Participants list
          Expanded(
            child: participants.isEmpty
                ? const Center(
                    child: Text('暂无参与者', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final participant = participants[index];
                      final energy = studyRoomProvider.getParticipantEnergy(
                        room.id,
                        participant.userId,
                      );
                      return _buildParticipantCard(participant, energy);
                    },
                  ),
          ),

          // Chat input
          _buildChatInput(),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(room, currentUser?.id),
    );
  }

  Widget _buildRoomInfoCard(StudyRoom room) {
    final isActive = room.status == 'active';
    final remainingMinutes = room.remainingMinutes;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status and time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(room.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isActive && remainingMinutes != null)
                Text(
                  '剩余 $remainingMinutes 分钟',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Time range
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('HH:mm').format(room.scheduledStartTime)} - ${DateFormat('HH:mm').format(room.scheduledEndTime)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Duration and participants
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoItem(
                Icons.timer,
                '${room.durationMinutes}分钟',
              ),
              Container(
                width: 1,
                height: 20,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildInfoItem(
                Icons.people,
                '${room.currentParticipants}/${room.maxParticipants}人',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantCard(Participant participant, int energy) {
    final isCreator = participant.role == 'creator';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isCreator ? Colors.amber : Colors.blue,
                  child: Text(
                    participant.nickname?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isCreator)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Info and energy bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          participant.nickname ?? participant.username ?? '未知用户',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (participant.totalFocusMinutes != null)
                        Text(
                          '${participant.totalFocusMinutes}min',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Energy bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: energy / 100,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getEnergyColor(energy),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$energy%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getEnergyColor(energy),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getFocusStateText(participant.focusState),
                    style: TextStyle(
                      fontSize: 11,
                      color: _getFocusStateColor(participant.focusState),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                decoration: InputDecoration(
                  hintText: '发送消息...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendChatMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendChatMessage,
              icon: const Icon(Icons.send),
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(StudyRoom room, int? currentUserId) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showEnergySlider,
                icon: const Icon(Icons.battery_charging_full),
                label: const Text('更新状态'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _leaveRoom,
                icon: const Icon(Icons.exit_to_app),
                label: const Text('离开'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'waiting':
        return '等待中';
      case 'active':
        return '进行中';
      case 'completed':
        return '已结束';
      case 'cancelled':
        return '已取消';
      default:
        return status;
    }
  }

  String _getFocusStateText(String state) {
    switch (state) {
      case 'focused':
        return '专注中';
      case 'break':
        return '休息中';
      case 'distracted':
        return '分心了';
      default:
        return state;
    }
  }

  Color _getFocusStateColor(String state) {
    switch (state) {
      case 'focused':
        return Colors.green;
      case 'break':
        return Colors.orange;
      case 'distracted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getEnergyColor(int energy) {
    if (energy >= 70) return Colors.green;
    if (energy >= 40) return Colors.orange;
    return Colors.red;
  }
}
