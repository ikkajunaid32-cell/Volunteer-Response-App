import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volunteer_app/core/theme/app_theme.dart';
import 'package:volunteer_app/ui/view_models/task_view_model.dart';
import 'package:volunteer_app/ui/views/common/custom_widgets.dart';

class TaskDetailsView extends StatefulWidget {
  final int taskId;

  const TaskDetailsView({super.key, required this.taskId});

  @override
  State<TaskDetailsView> createState() => _TaskDetailsViewState();
}

class _TaskDetailsViewState extends State<TaskDetailsView> {
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskViewModel>().loadTaskDetails(widget.taskId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskVm = context.watch<TaskViewModel>();
    final task = taskVm.selectedTask;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: taskVm.isLoading && task == null
          ? const Center(child: CircularProgressIndicator())
          : task == null
              ? Center(
                  child: Text(taskVm.errorMessage ?? 'Task could not be found'),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Display & Gallery
                      if (task.images.isNotEmpty) ...[
                        TaskImageThumbnail(
                          imageUrl: task.images[_selectedImageIndex.clamp(0, task.images.length - 1)],
                          height: 240,
                          borderRadius: BorderRadius.zero,
                        ),
                        if (task.images.length > 1)
                          Container(
                            height: 64,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: task.images.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (context, idx) {
                                final isSelected = idx == _selectedImageIndex;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedImageIndex = idx),
                                  child: Container(
                                    width: 50,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
                                        width: 2.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TaskImageThumbnail(
                                      imageUrl: task.images[idx],
                                      height: 48,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ] else ...[
                        TaskImageThumbnail(
                          imageUrl: task.imageUrl,
                          height: 220,
                          borderRadius: BorderRadius.zero,
                        ),
                      ],

                      // Content Body
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status & Spots header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StatusBadge(status: task.status),
                                VolunteerSpotsBadge(
                                  registered: task.registeredCount,
                                  required: task.volunteersRequired,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              task.taskName,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),

                            // Info Cards (Location, Date/Time)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  _InfoRow(
                                    icon: Icons.location_on,
                                    iconColor: AppTheme.accentAmber,
                                    title: 'Location',
                                    subtitle: task.location,
                                    trailing: task.latitude != null
                                        ? Text(
                                            '${task.latitude!.toStringAsFixed(3)}, ${task.longitude!.toStringAsFixed(3)}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                          )
                                        : null,
                                  ),
                                  const Divider(height: 20),
                                  _InfoRow(
                                    icon: Icons.calendar_month,
                                    iconColor: Colors.blue.shade700,
                                    title: 'Date',
                                    subtitle: task.taskDate,
                                  ),
                                  const Divider(height: 20),
                                  _InfoRow(
                                    icon: Icons.access_time,
                                    iconColor: Colors.purple.shade600,
                                    title: 'Time',
                                    subtitle: task.endTime != null
                                        ? '${task.startTime} – ${task.endTime}'
                                        : task.startTime,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Progress bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Volunteer Capacity',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      '${task.registeredCount} / ${task.volunteersRequired} filled',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: task.progressRatio,
                                    minHeight: 10,
                                    backgroundColor: Colors.grey.shade200,
                                    color: task.isFull ? AppTheme.alertRed : AppTheme.primaryTeal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Description Section
                            const Text(
                              'Task Description',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              task.description,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: task == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: task.isUserRegistered
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.cancel_outlined, color: AppTheme.alertRed),
                              label: const Text('Cancel Registration', style: TextStyle(color: AppTheme.alertRed)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.alertRed),
                              ),
                              onPressed: taskVm.isActionLoading
                                  ? null
                                  : () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final success = await taskVm.cancelRegistration(task.taskId);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(success ? 'Registration cancelled' : 'Failed to cancel'),
                                        ),
                                      );
                                    },
                            ),
                          ),
                        ],
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.how_to_reg),
                        label: Text(task.isFull ? 'Task Full' : 'Apply / Accept Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: task.isFull ? Colors.grey.shade500 : AppTheme.primaryTeal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: task.isFull || task.status != 'Available' || taskVm.isActionLoading
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final success = await taskVm.applyForTask(task.taskId);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? 'You have accepted this task!'
                                        : (taskVm.errorMessage ?? 'Application failed')),
                                    backgroundColor: success ? AppTheme.statusGreen : AppTheme.alertRed,
                                  ),
                                );
                              },
                      ),
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
