import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../business/providers/study_room_provider.dart';
import 'study_room_detail_screen.dart';

class CreateStudyRoomScreen extends StatefulWidget {
  const CreateStudyRoomScreen({super.key});

  @override
  State<CreateStudyRoomScreen> createState() => _CreateStudyRoomScreenState();
}

class _CreateStudyRoomScreenState extends State<CreateStudyRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Form fields
  int _durationMinutes = 90; // Default: 90 minutes
  DateTime _scheduledStartTime = DateTime.now().add(const Duration(minutes: 5));
  int _maxParticipants = 4;
  String? _taskCategory;

  // Duration options
  final List<int> _durationOptions = [25, 45, 60, 90, 120, 180];

  // Category options
  final Map<String, String> _categoryOptions = {
    'work': '工作',
    'study': '学习',
    'reading': '阅读',
    'coding': '编程',
    'exam_prep': '备考',
    'other': '其他',
  };

  // Max participants options
  final List<int> _participantOptions = [2, 3, 4, 6, 8];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final now = DateTime.now();

    // Date picker
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledStartTime,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (date == null) return;

    if (!mounted) return;

    // Time picker
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledStartTime),
    );

    if (time == null) return;

    setState(() {
      _scheduledStartTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<StudyRoomProvider>();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final room = await provider.createStudyRoom(
      name: _nameController.text.trim(),
      durationMinutes: _durationMinutes,
      scheduledStartTime: _scheduledStartTime.toIso8601String(),
      maxParticipants: _maxParticipants,
      taskCategory: _taskCategory,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (room != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('创建成功！')),
      );

      // Navigate to room detail and remove create screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudyRoomDetailScreen(room: room),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('创建失败: ${provider.errorMessage ?? "未知错误"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建自习室'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '创建自习室后，其他用户可以看到并加入您的房间',
                      style: TextStyle(fontSize: 13, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Room name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '自习室名称',
                hintText: '给你的自习室起个名字',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入自习室名称';
                }
                if (value.trim().length < 2) {
                  return '名称至少2个字符';
                }
                if (value.trim().length > 50) {
                  return '名称不能超过50个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description (optional)
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '介绍一下这个自习室吧',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 16),

            // Duration selection
            _buildSectionTitle('学习时长'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durationOptions.map((duration) {
                final isSelected = _durationMinutes == duration;
                return ChoiceChip(
                  label: Text('$duration分钟'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _durationMinutes = duration);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Start time
            _buildSectionTitle('开始时间'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectStartTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('yyyy年MM月dd日 HH:mm').format(_scheduledStartTime),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getRelativeTimeText(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Max participants
            _buildSectionTitle('最多参与人数'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _participantOptions.map((count) {
                final isSelected = _maxParticipants == count;
                return ChoiceChip(
                  label: Text('$count人'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _maxParticipants = count);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Task category
            _buildSectionTitle('任务类别（可选）'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categoryOptions.entries.map((entry) {
                final isSelected = _taskCategory == entry.key;
                return FilterChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _taskCategory = selected ? entry.key : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '自习室概要',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20),
                  _buildSummaryRow('时长', '$_durationMinutes分钟'),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    '开始',
                    DateFormat('MM月dd日 HH:mm').format(_scheduledStartTime),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    '结束',
                    DateFormat('HH:mm').format(
                      _scheduledStartTime.add(Duration(minutes: _durationMinutes)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow('人数', '最多$_maxParticipants人'),
                  if (_taskCategory != null) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow('类别', _categoryOptions[_taskCategory!]!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Create button
            ElevatedButton(
              onPressed: _createRoom,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '创建自习室',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _getRelativeTimeText() {
    final now = DateTime.now();
    final diff = _scheduledStartTime.difference(now);

    if (diff.inMinutes < 0) {
      return '已过期，请选择未来时间';
    } else if (diff.inMinutes < 5) {
      return '建议至少提前5分钟';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟后';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时后';
    } else {
      return '${diff.inDays}天后';
    }
  }
}
