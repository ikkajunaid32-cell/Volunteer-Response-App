import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volunteer_app/core/theme/app_theme.dart';
import 'package:volunteer_app/data/models/task_model.dart';
import 'package:volunteer_app/ui/view_models/auth_view_model.dart';
import 'package:volunteer_app/ui/view_models/task_view_model.dart';
import 'package:volunteer_app/ui/views/common/api_config_dialog.dart';
import 'package:volunteer_app/ui/views/common/custom_widgets.dart';
import 'package:volunteer_app/ui/views/volunteer/my_tasks_view.dart';
import 'package:volunteer_app/ui/views/volunteer/task_details_view.dart';

class VolunteerDashboardView extends StatefulWidget {
  const VolunteerDashboardView({super.key});

  @override
  State<VolunteerDashboardView> createState() => _VolunteerDashboardViewState();
}

class _VolunteerDashboardViewState extends State<VolunteerDashboardView> {
  int _currentBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskViewModel>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Volunteer Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'Hello, ${authVm.currentUser?.name ?? 'Volunteer'}',
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
      body: _currentBottomNavIndex == 0
          ? const _AvailableTasksList()
          : const MyTasksView(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentBottomNavIndex,
        onDestinationSelected: (index) {
          setState(() => _currentBottomNavIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Explore Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_turned_in_outlined),
            selectedIcon: Icon(Icons.assignment_turned_in),
            label: 'My Tasks',
          ),
        ],
      ),
    );
  }
}

class _AvailableTasksList extends StatelessWidget {
  const _AvailableTasksList();

  @override
  Widget build(BuildContext context) {
    final taskVm = context.watch<TaskViewModel>();

    return RefreshIndicator(
      onRefresh: () => taskVm.loadTasks(),
      child: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks by name, location...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => taskVm.setSearchQuery(val),
            ),
          ),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: ['All', 'Available', 'In Progress'].map((status) {
                final isSelected = taskVm.statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) => taskVm.setStatusFilter(status),
                    selectedColor: AppTheme.primaryLight,
                    checkmarkColor: AppTheme.primaryTeal,
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // Main Task List
          Expanded(
            child: taskVm.isLoading && taskVm.tasks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : taskVm.tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No volunteer tasks found',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => taskVm.loadTasks(),
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: taskVm.tasks.length,
                        separatorBuilder: (context, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final task = taskVm.tasks[index];
                          return _TaskCard(task: task);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final taskVm = context.read<TaskViewModel>();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Image with status overlay
          Stack(
            children: [
              TaskImageThumbnail(
                imageUrl: task.imageUrl,
                height: 170,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: StatusBadge(status: task.status, isSmall: true),
              ),
              if (task.isUserRegistered)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Accepted',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  task.taskName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.accentAmber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task.location,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Date & Time
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 15, color: Colors.blueGrey),
                    const SizedBox(width: 6),
                    Text(
                      '${task.taskDate} • ${task.startTime}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description excerpt
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 14),

                // Volunteers Required & Registered Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VolunteerSpotsBadge(
                      registered: task.registeredCount,
                      required: task.volunteersRequired,
                    ),
                    Text(
                      task.isFull
                          ? 'Capacity Reached'
                          : '${task.spotsRemaining} spots left',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: task.isFull ? AppTheme.alertRed : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailsView(taskId: task.taskId),
                            ),
                          );
                        },
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: task.isUserRegistered
                              ? Colors.grey.shade700
                              : AppTheme.primaryTeal,
                        ),
                        onPressed: task.isUserRegistered || task.isFull || task.status != 'Available'
                            ? null
                            : () async {
                                final success = await taskVm.applyForTask(task.taskId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success
                                          ? 'Successfully accepted "${task.taskName}"!'
                                          : (taskVm.errorMessage ?? 'Failed to apply')),
                                      backgroundColor: success ? AppTheme.statusGreen : AppTheme.alertRed,
                                    ),
                                  );
                                }
                              },
                        child: Text(
                          task.isUserRegistered
                              ? 'Registered'
                              : (task.isFull ? 'Full' : 'Accept Task'),
                        ),
                      ),
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
