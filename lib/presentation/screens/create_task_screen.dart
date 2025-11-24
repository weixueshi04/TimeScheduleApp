import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../business/providers/task_provider.dart';
import '../../data/models/task.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'study';
  String _priority = 'medium';
  DateTime? _dueDate;
  int _estimatedPomodoros = 1;

  final Map<String, String> _categoryOptions = {
    'work': '工作',
    'study': '学习',
    'reading': '阅读',
    'coding': '编程',
    'exam_prep': '备考',
    'life': '生活',
    'health': '健康',
    'other': '其他',
  };

  final Map<String, String> _priorityOptions = {
    'low': '低',
    'medium': '中',
    'high': '高',
    'urgent': '紧急',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();

    // Date picker
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null) return;

    if (!mounted) return;

    // Time picker
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? now),
    );

    if (time == null) return;

    setState(() {
      _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TaskProvider>();

    final request = CreateTaskRequest(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _category,
      priority: _priority,
      dueDate: _dueDate?.toIso8601String(),
      estimatedPomodoros: _estimatedPomodoros,
    );

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final task = await provider.createTask(request);

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (task != null) {
      Navigator.pop(context); // Return to task list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('任务创建成功！')),
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
        title: const Text('新建任务'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '任务标题',
                hintText: '例如：完成项目文档',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入任务标题';
                }
                if (value.trim().length < 2) {
                  return '标题至少2个字符';
                }
                if (value.trim().length > 100) {
                  return '标题不能超过100个字符';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '任务描述（可选）',
                hintText: '详细描述任务内容...',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 500,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 16),

            // Category
            _buildSectionTitle('任务分类'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categoryOptions.entries.map((entry) {
                final isSelected = _category == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _category = entry.key);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Priority
            _buildSectionTitle('优先级'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _priorityOptions.entries.map((entry) {
                final isSelected = _priority == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  selectedColor: _getPriorityColor(entry.key),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _priority = entry.key);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Due date
            _buildSectionTitle('截止时间（可选）'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDueDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dueDate == null
                            ? '选择截止时间'
                            : DateFormat('yyyy年MM月dd日 HH:mm').format(_dueDate!),
                        style: TextStyle(
                          fontSize: 16,
                          color: _dueDate == null ? Colors.grey : null,
                        ),
                      ),
                    ),
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() => _dueDate = null),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Estimated Pomodoros
            _buildSectionTitle('预计番茄钟数'),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _estimatedPomodoros > 1
                      ? () => setState(() => _estimatedPomodoros--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Expanded(
                  child: Slider(
                    value: _estimatedPomodoros.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: '$_estimatedPomodoros 个',
                    onChanged: (value) {
                      setState(() => _estimatedPomodoros = value.toInt());
                    },
                  ),
                ),
                IconButton(
                  onPressed: _estimatedPomodoros < 20
                      ? () => setState(() => _estimatedPomodoros++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_estimatedPomodoros 个',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '预计耗时: ${_estimatedPomodoros * 25} 分钟',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
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
                    '任务概要',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20),
                  _buildSummaryRow('分类', _categoryOptions[_category]!),
                  const SizedBox(height: 8),
                  _buildSummaryRow('优先级', _priorityOptions[_priority]!),
                  if (_dueDate != null) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      '截止',
                      DateFormat('MM月dd日 HH:mm').format(_dueDate!),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    '预计',
                    '$_estimatedPomodoros 个番茄钟 (${_estimatedPomodoros * 25}分钟)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Create button
            ElevatedButton(
              onPressed: _createTask,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '创建任务',
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red.withOpacity(0.2);
      case 'high':
        return Colors.orange.withOpacity(0.2);
      case 'medium':
        return Colors.blue.withOpacity(0.2);
      case 'low':
        return Colors.grey.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }
}
