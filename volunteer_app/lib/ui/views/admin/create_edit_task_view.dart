import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:volunteer_app/core/theme/app_theme.dart';
import 'package:volunteer_app/data/models/task_model.dart';
import 'package:volunteer_app/ui/view_models/admin_task_view_model.dart';
import 'package:volunteer_app/ui/views/common/custom_widgets.dart';

class CreateEditTaskView extends StatefulWidget {
  final TaskModel? taskToEdit;

  const CreateEditTaskView({super.key, this.taskToEdit});

  @override
  State<CreateEditTaskView> createState() => _CreateEditTaskViewState();
}

class _CreateEditTaskViewState extends State<CreateEditTaskView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _locationController;
  late final TextEditingController _volunteersController;
  late final TextEditingController _imageUrlController;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay? _endTime = const TimeOfDay(hour: 15, minute: 0);

  String _status = 'Available';
  final List<String> _additionalImages = [];
  bool _isUploadingImage = false;

  bool get isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    final t = widget.taskToEdit;
    _nameController = TextEditingController(text: t?.taskName ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _locationController = TextEditingController(text: t?.location ?? '');
    _volunteersController = TextEditingController(text: (t?.volunteersRequired ?? 10).toString());
    _imageUrlController = TextEditingController(text: t?.imageUrl ?? '');

    if (t != null) {
      _status = t.status;
      try {
        _selectedDate = DateTime.parse(t.taskDate);
      } catch (_) {}
      _additionalImages.addAll(t.images.where((img) => img != t.imageUrl));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _volunteersController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final adminVm = context.read<AdminTaskViewModel>();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    final uploadedUrl = await adminVm.uploadImageFile(picked);
    if (!mounted) return;
    setState(() => _isUploadingImage = false);

    if (uploadedUrl != null) {
      setState(() {
        if (_imageUrlController.text.isEmpty) {
          _imageUrlController.text = uploadedUrl;
        } else {
          _additionalImages.add(uploadedUrl);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!'), backgroundColor: AppTheme.statusGreen),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 17, minute: 0),
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final adminVm = context.read<AdminTaskViewModel>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final startStr = _formatTimeOfDay(_startTime);
    final endStr = _endTime != null ? _formatTimeOfDay(_endTime!) : null;

    final allImages = <String>[];
    if (_imageUrlController.text.trim().isNotEmpty) {
      allImages.add(_imageUrlController.text.trim());
    }
    allImages.addAll(_additionalImages);

    bool success;
    if (isEditing) {
      success = await adminVm.updateTask(
        taskId: widget.taskToEdit!.taskId,
        taskName: _nameController.text.trim(),
        description: _descController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        location: _locationController.text.trim(),
        taskDate: dateStr,
        startTime: startStr,
        endTime: endStr,
        volunteersRequired: int.tryParse(_volunteersController.text.trim()) ?? 1,
        status: _status,
        additionalImages: allImages,
      );
    } else {
      success = await adminVm.createTask(
        taskName: _nameController.text.trim(),
        description: _descController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        location: _locationController.text.trim(),
        taskDate: dateStr,
        startTime: startStr,
        endTime: endStr,
        volunteersRequired: int.tryParse(_volunteersController.text.trim()) ?? 1,
        status: _status,
        additionalImages: allImages,
      );
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Task updated successfully' : 'Task published to volunteers!'),
          backgroundColor: AppTheme.statusGreen,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adminVm.errorMessage ?? 'Failed to save task'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminVm = context.watch<AdminTaskViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Volunteer Task' : 'Create Daily Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Task Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name / Title *',
                  hintText: 'e.g. Fill Sandbags',
                  prefixIcon: Icon(Icons.assignment),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter task name' : null,
              ),
              const SizedBox(height: 16),

              // Task Description
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Detailed Task Description *',
                  hintText: 'Describe requirements, gear, instructions...',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter task description' : null,
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location / Address *',
                  hintText: 'e.g. Newcastle Emergency Response Centre',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter task location' : null,
              ),
              const SizedBox(height: 16),

              // Volunteers Required
              TextFormField(
                controller: _volunteersController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Volunteers Required *',
                  hintText: 'e.g. 10',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter volunteers quota';
                  final num = int.tryParse(v.trim());
                  if (num == null || num < 1) return 'Must be 1 or more';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date & Time Selectors
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(DateFormat('d MMM yyyy').format(_selectedDate)),
                      onPressed: _selectDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text('Start: ${_formatTimeOfDay(_startTime)}'),
                      onPressed: _selectStartTime,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.timelapse, size: 16),
                      label: Text(_endTime != null ? 'End: ${_formatTimeOfDay(_endTime!)}' : 'End Time'),
                      onPressed: _selectEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Task Status Dropdown
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Task Status',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: ['Available', 'In Progress', 'Completed', 'Cancelled'].map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
              const SizedBox(height: 24),

              // Image Section
              const Text('Task Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL or Upload Below',
                  hintText: 'https://... or uploaded image path',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 10),

              // Upload Image Button
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade50,
                      foregroundColor: AppTheme.primaryTeal,
                      elevation: 0,
                    ),
                    icon: _isUploadingImage
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.photo_camera_back),
                    label: Text(_isUploadingImage ? 'Uploading...' : 'Upload Image from Device'),
                    onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                  ),
                ],
              ),

              // Image preview
              if (_imageUrlController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                TaskImageThumbnail(
                  imageUrl: _imageUrlController.text,
                  height: 160,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: adminVm.isSaving ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: adminVm.isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isEditing ? 'Save Changes' : 'Publish Task',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
