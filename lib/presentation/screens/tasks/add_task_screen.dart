import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:focus_life/core/themes/app_theme.dart';
import 'package:focus_life/core/constants/app_constants.dart';
import 'package:focus_life/business/providers/task_provider.dart';
import 'package:focus_life/data/models/task_model.dart';

/// 添加任务页面
class AddTaskScreen extends StatefulWidget {
  final Task? task; // 如果提供，则为编辑模式

  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskCategory _selectedCategory = TaskCategory.work;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDueDate;
  int _estimatedMinutes = 30;

  bool get _isEditMode => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadTaskData();
    }
  }

  /// 加载任务数据（编辑模式）
  void _loadTaskData() {
    final task = widget.task!;
    _titleController.text = task.title;
    _descriptionController.text = task.description ?? '';
    _selectedCategory = task.category;
    _selectedPriority = task.priority;
    _selectedDueDate = task.dueDate;
    _estimatedMinutes = task.estimatedMinutes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isEditMode ? '编辑任务' : '添加任务'),
        backgroundColor: AppTheme.cardColor,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saveTask,
          child: const Text('保存'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          children: [
            // 任务标题
            _buildSection(
              title: '任务标题',
              child: CupertinoTextField(
                controller: _titleController,
                placeholder: '输入任务标题',
                maxLength: AppConstants.maxTaskTitleLength,
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // 任务描述
            _buildSection(
              title: '任务描述（可选）',
              child: CupertinoTextField(
                controller: _descriptionController,
                placeholder: '输入任务描述',
                maxLines: 4,
                maxLength: AppConstants.maxTaskDescriptionLength,
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // 任务分类
            _buildSection(
              title: '任务分类',
              child: _buildCategoryPicker(),
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // 优先级
            _buildSection(
              title: '优先级',
              child: _buildPriorityPicker(),
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // 截止日期
            _buildSection(
              title: '截止日期',
              child: _buildDueDatePicker(),
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // 预估时间
            _buildSection(
              title: '预估时间',
              child: _buildEstimatedTimePicker(),
            ),

            const SizedBox(height: AppTheme.spacingXXL),
          ],
        ),
      ),
    );
  }

  /// 构建章节
  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeCaption,
            fontWeight: AppTheme.fontWeightMedium,
            color: AppTheme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        child,
      ],
    );
  }

  /// 构建分类选择器
  Widget _buildCategoryPicker() {
    return Row(
      children: TaskCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              decoration: BoxDecoration(
                color: isSelected
                    ? category.color.withOpacity(0.2)
                    : AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: isSelected ? category.color : CupertinoColors.separator,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    category.icon,
                    color: isSelected ? category.color : AppTheme.secondaryTextColor,
                    size: 24,
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    category.displayName,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: isSelected ? category.color : AppTheme.primaryTextColor,
                      fontWeight: isSelected
                          ? AppTheme.fontWeightMedium
                          : AppTheme.fontWeightRegular,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建优先级选择器
  Widget _buildPriorityPicker() {
    return Row(
      children: TaskPriority.values.map((priority) {
        final isSelected = _selectedPriority == priority;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPriority = priority),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              decoration: BoxDecoration(
                color: isSelected
                    ? priority.color.withOpacity(0.2)
                    : AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: isSelected ? priority.color : CupertinoColors.separator,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                priority.displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeBody,
                  color: isSelected ? priority.color : AppTheme.primaryTextColor,
                  fontWeight: isSelected
                      ? AppTheme.fontWeightMedium
                      : AppTheme.fontWeightRegular,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建截止日期选择器
  Widget _buildDueDatePicker() {
    return CupertinoButton(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      onPressed: _showDatePicker,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _selectedDueDate == null
                ? '选择截止日期'
                : _formatDate(_selectedDueDate!),
            style: TextStyle(
              color: _selectedDueDate == null
                  ? AppTheme.secondaryTextColor
                  : AppTheme.primaryTextColor,
            ),
          ),
          Icon(
            CupertinoIcons.calendar,
            color: _selectedDueDate == null
                ? AppTheme.secondaryTextColor
                : AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  /// 构建预估时间选择器
  Widget _buildEstimatedTimePicker() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('预估时间'),
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (_estimatedMinutes > 15) {
                    setState(() => _estimatedMinutes -= 15);
                  }
                },
                child: const Icon(CupertinoIcons.minus_circle),
              ),
              Container(
                width: 80,
                alignment: Alignment.center,
                child: Text(
                  '$_estimatedMinutes分钟',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeSubtitle,
                    fontWeight: AppTheme.fontWeightMedium,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() => _estimatedMinutes += 15);
                },
                child: const Icon(CupertinoIcons.plus_circle),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 显示日期选择器
  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() => _selectedDueDate = null);
                      Navigator.pop(context);
                    },
                    child: const Text('清除'),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDueDate ?? DateTime.now(),
                minimumDate: DateTime.now(),
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() => _selectedDueDate = newDateTime);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  /// 保存任务
  void _saveTask() {
    // 验证输入
    if (_titleController.text.trim().isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('提示'),
          content: const Text('请输入任务标题'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    // 创建或更新任务
    final task = Task(
      id: _isEditMode ? widget.task!.id : null,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      dueDate: _selectedDueDate,
      estimatedMinutes: _estimatedMinutes,
    );

    // 保存到数据库
    final provider = context.read<TaskProvider>();
    if (_isEditMode) {
      provider.updateTask(task);
    } else {
      provider.addTask(task);
    }

    // 返回
    Navigator.pop(context);
  }
}
