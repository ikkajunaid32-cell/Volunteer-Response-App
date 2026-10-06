import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volunteer_app/core/theme/app_theme.dart';
import 'package:volunteer_app/data/models/task_model.dart';
import 'package:volunteer_app/ui/view_models/admin_task_view_model.dart';
import 'package:volunteer_app/ui/view_models/auth_view_model.dart';
import 'package:volunteer_app/ui/views/admin/create_edit_task_view.dart';
import 'package:volunteer_app/ui/views/admin/task_volunteers_view.dart';
import 'package:volunteer_app/ui/views/common/api_config_dialog.dart';
import 'package:volunteer_app/ui/views/common/custom_widgets.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminTaskViewModel>().loadAdminTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final adminVm = context.watch<AdminTaskViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Task Panel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'Coordinator: ${authVm.currentUser?.name ?? 'Admin'}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Server Settings',
            onPressed: () => ApiConfigDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => authVm.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => adminVm.loadAdminTasks(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Overview Grid
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Tasks',
                        count: adminVm.totalCount,
                        color: AppTheme.primaryTeal,
                        icon: Icons.task,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: 'Available',
                        count: adminVm.availableCount,
                        color: AppTheme.statusGreen,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: 'Completed',
                        count: adminVm.completedCount,
                        color: Colors.blue.shade700,
                        icon: Icons.done_all,
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: ['All', 'Available', 'In Progress', 'Completed', 'Cancelled'].map((status) {
                    final isSelected = adminVm.adminStatusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (_) => adminVm.setFilter(status),
                        selectedColor: AppTheme.primaryLight,
                        checkmarkColor: AppTheme.primaryTeal,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(height: 1),

              // Tasks List
              if (adminVm.isLoading && adminVm.tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (adminVm.tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.post_add, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No tasks in this category',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Task'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CreateEditTaskView()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: adminVm.tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final task = adminVm.tasks[index];
                    return _AdminTaskCard(task: task);
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Task'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEditTaskView()),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AdminTaskCard extends StatelessWidget {
  final TaskModel task;

  const _AdminTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final adminVm = context.read<AdminTaskViewModel>();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header thumbnail and badges
          Stack(
            children: [
              TaskImageThumbnail(
                imageUrl: task.imageUrl,
                height: 150,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: StatusBadge(status: task.status, isSmall: true),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.taskName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                    VolunteerSpotsBadge(
                      registered: task.registeredCount,
                      required: task.volunteersRequired,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: AppTheme.accentAmber),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task.location,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(
                      '${task.taskDate} • ${task.startTime}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 16),

                // Admin Action Buttons
                Row(
                  children: [
                    // View Volunteers Button
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.people_outline, size: 16),
                        label: Text('Volunteers (${task.registeredCount})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade50,
                          foregroundColor: AppTheme.primaryTeal,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskVolunteersView(task: task),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Edit Button
                    IconButton.filledTonal(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Task',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateEditTaskView(taskToEdit: task),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),

                    // Delete Button
                    IconButton.filledTonal(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.alertRed),
                      tooltip: 'Delete Task',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Task?'),
                            content: Text('Are you sure you want to delete "${task.taskName}"? This will also remove any volunteer registrations.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.alertRed),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  final success = await adminVm.deleteTask(task.taskId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success ? 'Task deleted' : 'Failed to delete task'),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
