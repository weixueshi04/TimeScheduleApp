import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../business/providers/study_room_provider.dart';
import '../../business/providers/auth_provider.dart';
import '../../data/models/study_room.dart';
import 'create_study_room_screen.dart';
import 'study_room_detail_screen.dart';
import 'package:intl/intl.dart';

class StudyRoomListScreen extends StatefulWidget {
  const StudyRoomListScreen({super.key});

  @override
  State<StudyRoomListScreen> createState() => _StudyRoomListScreenState();
}

class _StudyRoomListScreenState extends State<StudyRoomListScreen> {
  String _filterStatus = 'all'; // all, waiting, active
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudyRooms();
    });
  }

  Future<void> _loadStudyRooms() async {
    await context.read<StudyRoomProvider>().fetchStudyRooms();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final studyRoomProvider = context.watch<StudyRoomProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('网络自习室'),
        actions: [
          // Filter button
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('全部')),
              const PopupMenuItem(value: 'waiting', child: Text('等待中')),
              const PopupMenuItem(value: 'active', child: Text('进行中')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStudyRooms,
        child: _buildBody(studyRoomProvider),
      ),
      floatingActionButton: _buildFloatingActionButton(user, studyRoomProvider),
    );
  }

  Widget _buildBody(StudyRoomProvider provider) {
    if (provider.status == StudyRoomStatus.loading && provider.studyRooms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == StudyRoomStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(provider.errorMessage ?? '加载失败'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStudyRooms,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final filteredRooms = _filterRooms(provider.studyRooms);

    if (filteredRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('暂无自习室', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('创建一个自习室开始学习吧！', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRooms.length,
      itemBuilder: (context, index) {
        return _buildRoomCard(filteredRooms[index]);
      },
    );
  }

  List<StudyRoom> _filterRooms(List<StudyRoom> rooms) {
    return rooms.where((room) {
      // Filter by status
      if (_filterStatus != 'all') {
        if (_filterStatus == 'waiting' && room.status != 'waiting') return false;
        if (_filterStatus == 'active' && room.status != 'active') return false;
      }

      // Filter by category
      if (_filterCategory != null && _filterCategory!.isNotEmpty) {
        if (room.matchingCriteria?['taskCategory'] != _filterCategory) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildRoomCard(StudyRoom room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToRoomDetail(room),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Room name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.name ?? '自习室 ${room.roomCode}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(room.status),
                ],
              ),
              const SizedBox(height: 12),

              // Creator info
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    child: Text(
                      room.creatorNickname?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.creatorNickname ?? room.creatorUsername ?? '未知',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _getRoomTypeText(room.roomType),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Time and duration
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatStartTime(room.scheduledStartTime),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.timer, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${room.durationMinutes}分钟',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Participants
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: room.currentParticipants >= room.maxParticipants
                        ? Colors.red
                        : Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${room.currentParticipants}/${room.maxParticipants} 人',
                    style: TextStyle(
                      fontSize: 13,
                      color: room.currentParticipants >= room.maxParticipants
                          ? Colors.red
                          : Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (room.canJoin)
                    TextButton.icon(
                      onPressed: () => _joinRoom(room),
                      icon: const Icon(Icons.login, size: 16),
                      label: const Text('加入'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                    )
                  else if (room.isActive)
                    const Text(
                      '进行中',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                    )
                  else
                    const Text(
                      '已满',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'waiting':
        color = Colors.blue;
        text = '等待中';
        icon = Icons.hourglass_empty;
        break;
      case 'active':
        color = Colors.green;
        text = '进行中';
        icon = Icons.play_circle_outline;
        break;
      case 'completed':
        color = Colors.grey;
        text = '已结束';
        icon = Icons.check_circle_outline;
        break;
      default:
        color = Colors.grey;
        text = status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoomTypeText(String roomType) {
    switch (roomType) {
      case 'matched':
        return '智能匹配';
      case 'created':
        return '自建房间';
      case 'temporary_rest':
        return '临时休息';
      default:
        return roomType;
    }
  }

  String _formatStartTime(DateTime time) {
    final now = DateTime.now();
    final diff = time.difference(now);

    if (diff.inMinutes < 0) {
      return '已开始';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟后开始';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时后开始';
    } else {
      return DateFormat('MM-dd HH:mm').format(time);
    }
  }

  Widget? _buildFloatingActionButton(user, StudyRoomProvider provider) {
    // Check if user can create study room
    final canCreate = user?.studyRoomEligibility?.canCreateStudyRoom ?? false;

    if (!canCreate) {
      return null;
    }

    // If matching, show cancel button
    if (provider.isMatching) {
      return FloatingActionButton.extended(
        onPressed: () {
          provider.cancelMatching();
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.close),
        label: const Text('取消匹配'),
      );
    }

    // If in room, don't show button
    if (provider.isInRoom) {
      return null;
    }

    return FloatingActionButton.extended(
      onPressed: () => _showCreateOptions(),
      icon: const Icon(Icons.add),
      label: const Text('创建自习室'),
    );
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create, color: Colors.blue),
              title: const Text('创建自习室'),
              subtitle: const Text('自定义设置，邀请好友'),
              onTap: () {
                Navigator.pop(context);
                _navigateToCreateRoom();
              },
            ),
            ListTile(
              leading: const Icon(Icons.shuffle, color: Colors.green),
              title: const Text('智能匹配'),
              subtitle: const Text('系统自动匹配合适的学习伙伴'),
              onTap: () {
                Navigator.pop(context);
                _startMatching();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateRoom() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateStudyRoomScreen()),
    );
  }

  void _navigateToRoomDetail(StudyRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudyRoomDetailScreen(room: room),
      ),
    );
  }

  Future<void> _joinRoom(StudyRoom room) async {
    final provider = context.read<StudyRoomProvider>();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.joinStudyRoom(room.id);

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加入成功！')),
      );

      // Navigate to room detail
      _navigateToRoomDetail(provider.currentRoom!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加入失败: ${provider.errorMessage ?? "未知错误"}')),
      );
    }
  }

  void _startMatching() {
    // Show matching dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const MatchingDialog(),
    );

    // Start matching with default settings (can be customized)
    final provider = context.read<StudyRoomProvider>();
    final scheduledTime = DateTime.now().add(const Duration(minutes: 5));

    provider.startMatching(
      durationMinutes: 90,
      scheduledStartTime: scheduledTime.toIso8601String(),
      taskCategory: null,
    );
  }
}

/// Matching dialog widget
class MatchingDialog extends StatelessWidget {
  const MatchingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyRoomProvider>();

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              provider.matchingMessage ?? '正在匹配...',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                provider.cancelMatching();
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }
}
