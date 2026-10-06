import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volunteer_app/core/theme/app_theme.dart';
import 'package:volunteer_app/data/models/task_model.dart';
import 'package:volunteer_app/ui/view_models/admin_task_view_model.dart';
import 'package:volunteer_app/ui/views/common/custom_widgets.dart';

class TaskVolunteersView extends StatefulWidget {
  final TaskModel task;

  const TaskVolunteersView({super.key, required this.task});

  @override
  State<TaskVolunteersView> createState() => _TaskVolunteersViewState();
}

class _TaskVolunteersViewState extends State<TaskVolunteersView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminTaskViewModel>().loadVolunteersForTask(widget.task.taskId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminVm = context.watch<AdminTaskViewModel>();
    final volunteers = adminVm.selectedTaskVolunteers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Volunteers'),
      ),
      body: Column(
        children: [
          // Task summary banner
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.task.taskName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    StatusBadge(status: widget.task.status, isSmall: true),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: AppTheme.accentAmber),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.task.location,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.task.taskDate} • ${widget.task.startTime}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const Spacer(),
                    VolunteerSpotsBadge(
                      registered: volunteers.where((v) => v.status == 'Accepted').length,
                      required: widget.task.volunteersRequired,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Volunteer List
          Expanded(
            child: adminVm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : volunteers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No volunteers have registered yet',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: volunteers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final v = volunteers[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.primaryLight,
                                    foregroundColor: AppTheme.primaryTeal,
                                    child: Text(
                                      v.name.isNotEmpty ? v.name[0].toUpperCase() : 'V',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                v.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ),
                                            StatusBadge(status: v.status, isSmall: true),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                v.email,
                                                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (v.phone != null && v.phone!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                v.phone!,
                                                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                          'Registered: ${v.registrationDate}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
