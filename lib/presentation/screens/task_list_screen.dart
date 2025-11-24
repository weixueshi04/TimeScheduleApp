import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../business/providers/task_provider.dart';
import '../../data/models/task.dart';
import 'create_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, String> _categoryNames = {
    'work': '工作',
    'study': '学习',
    'reading': '阅读',
    'coding': '编程',
    'exam_prep': '备考',
    'life': '生活',
    'health': '健康',
    'other': '其他',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final provider = context.read<TaskProvider>();
    await Future.wait([
      provider.fetchTasks(),
      provider.fetchTodayTasks(),
      provider.fetchStats(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '今天'),
            Tab(text: '进行中'),
            Tab(text: '已完成'),
          ],
          onTap: (index) {
            final provider = context.read<TaskProvider>();
            switch (index) {
              case 0:
                provider.setFilter(status: 'all');
                break;
              case 1:
                // Today tasks - handled separately
                break;
              case 2:
                provider.setFilter(status: 'in_progress');
                break;
              case 3:
                provider.setFilter(status: 'completed');
                break;
            }
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (category) {
              context.read<TaskProvider>().setFilter(category: category);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('全部分类')),
              ..._categoryNames.entries.map((entry) {
                return PopupMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTasksView(),
          _buildTodayTasksView(),
          _buildAllTasksView(),
          _buildAllTasksView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateTask(),
        icon: const Icon(Icons.add),
        label: const Text('新建任务'),
      ),
    );
  }

  Widget _buildAllTasksView() {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        if (provider.status == TaskLoadingStatus.loading && provider.tasks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.status == TaskLoadingStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.errorMessage ?? '加载失败'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadTasks,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final tasks = provider.tasks;

        if (tasks.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _loadTasks,
          child: Column(
            children: [
              // Stats card
              if (provider.stats != null) _buildStatsCard(provider.stats!),

              // Task list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return _buildTaskCard(tasks[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayTasksView() {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final tasks = provider.todayTasks;

        if (provider.isLoading && tasks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.today, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('今天没有任务', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadTasks,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return _buildTaskCard(tasks[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(TaskStats stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('总任务', stats.totalTasks.toString(), Icons.task_alt),
          _buildStatDivider(),
          _buildStatItem('已完成', stats.completedTasks.toString(), Icons.check_circle),
          _buildStatDivider(),
          _buildStatItem('进行中', stats.pendingTasks.toString(), Icons.pending),
          _buildStatDivider(),
          _buildStatItem('完成率', '${(stats.completionRate * 100).toInt()}%', Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_alt, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('还没有任务', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('点击下方按钮创建第一个任务吧！', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTaskDetail(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Completion checkbox
              Checkbox(
                value: task.isCompleted,
                onChanged: (value) => _toggleCompletion(task),
              ),
              const SizedBox(width: 12),

              // Task content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted ? Colors.grey : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Tags and info
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildChip(
                          _categoryNames[task.category] ?? task.category,
                          Colors.blue,
                        ),
                        _buildChip(
                          _getPriorityText(task.priority),
                          _getPriorityColor(task.priority),
                        ),
                        if (task.dueDate != null)
                          _buildChip(
                            _formatDueDate(task),
                            task.isOverdue ? Colors.red : Colors.grey,
                          ),
                        if (task.estimatedPomodoros > 0)
                          _buildChip(
                            '${task.actualPomodoros}/${task.estimatedPomodoros} 番茄',
                            Colors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // More options
              PopupMenuButton<String>(
                onSelected: (action) => _handleTaskAction(action, task),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('编辑')),
                  const PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'urgent':
        return '紧急';
      case 'high':
        return '高';
      case 'medium':
        return '中';
      case 'low':
        return '低';
      default:
        return priority;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDueDate(Task task) {
    if (task.dueDate == null) return '';

    if (task.isDueToday) {
      return '今天';
    } else if (task.isOverdue) {
      return '已逾期';
    } else {
      final days = task.remainingDays;
      if (days == 1) {
        return '明天';
      } else if (days! < 7) {
        return '$days天后';
      } else {
        return DateFormat('MM-dd').format(task.dueDate!);
      }
    }
  }

  void _navigateToCreateTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTaskScreen()),
    );
  }

  void _showTaskDetail(Task task) {
    // TODO: Implement task detail dialog or screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null) ...[
              const Text('描述:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(task.description!),
              const SizedBox(height: 12),
            ],
            Text('分类: ${_categoryNames[task.category]}'),
            Text('优先级: ${_getPriorityText(task.priority)}'),
            if (task.dueDate != null)
              Text('截止: ${DateFormat('yyyy-MM-dd HH:mm').format(task.dueDate!)}'),
            Text('番茄钟: ${task.actualPomodoros}/${task.estimatedPomodoros}'),
            Text('状态: ${task.isCompleted ? "已完成" : "未完成"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCompletion(Task task) async {
    final provider = context.read<TaskProvider>();
    await provider.toggleTaskCompletion(task.id, !task.isCompleted);
  }

  Future<void> _handleTaskAction(String action, Task task) async {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit screen
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除任务'),
            content: const Text('确定要删除这个任务吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          final provider = context.read<TaskProvider>();
          final success = await provider.deleteTask(task.id);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? '任务已删除' : '删除失败'),
                backgroundColor: success ? null : Colors.red,
              ),
            );
          }
        }
        break;
    }
  }
}
