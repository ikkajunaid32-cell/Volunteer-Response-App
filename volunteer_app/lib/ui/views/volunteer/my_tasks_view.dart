import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:volunteer_app/core/theme/app_theme.dart';
import 'package:volunteer_app/data/models/task_model.dart';
import 'package:volunteer_app/ui/view_models/task_view_model.dart';
import 'package:volunteer_app/ui/views/common/custom_widgets.dart';
import 'package:volunteer_app/ui/views/volunteer/task_details_view.dart';

class MyTasksView extends StatefulWidget {
  const MyTasksView({super.key});

  @override
  State<MyTasksView> createState() => _MyTasksViewState();
}

class _MyTasksViewState extends State<MyTasksView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Upcoming', 'Accepted', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<TaskViewModel>().setMyTasksFilter(_tabs[_tabController.index]);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskViewModel>().loadMyTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskVm = context.watch<TaskViewModel>();

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppTheme.primaryTeal,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: AppTheme.primaryTeal,
            indicatorWeight: 3,
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => taskVm.loadMyTasks(),
            child: taskVm.isLoading && taskVm.myTasks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : taskVm.myTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No ${_tabs[_tabController.index].toLowerCase()} tasks found',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: taskVm.myTasks.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = taskVm.myTasks[index];
                          return _MyTaskListItem(task: task);
                        },
                      ),
          ),
        ),
      ],
    );
  }
}

class _MyTaskListItem extends StatelessWidget {
  final TaskModel task;

  const _MyTaskListItem({required this.task});

  @override
  Widget build(BuildContext context) {
    final registrationStatus = task.userRegistrationStatus ?? 'Accepted';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailsView(taskId: task.taskId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Small image thumbnail
              TaskImageThumbnail(
                imageUrl: task.imageUrl,
                height: 80,
                width: 80,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            task.taskName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(status: registrationStatus, isSmall: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.accentAmber),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task.location,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text(
                          '${task.taskDate} • ${task.startTime}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
