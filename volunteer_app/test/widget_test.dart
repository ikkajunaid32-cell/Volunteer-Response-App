import 'package:flutter_test/flutter_test.dart';
import 'package:volunteer_app/data/models/task_model.dart';
import 'package:volunteer_app/data/models/user_model.dart';

void main() {
  group('Model Serialization Tests', () {
    test('UserModel parsing test', () {
      final userJson = {
        'userId': 1,
        'name': 'Test Volunteer',
        'email': 'volunteer@test.org',
        'phone': '0412345678',
        'role': 'volunteer'
      };

      final user = UserModel.fromJson(userJson);
      expect(user.userId, 1);
      expect(user.name, 'Test Volunteer');
      expect(user.email, 'volunteer@test.org');
      expect(user.isVolunteer, true);
      expect(user.isAdmin, false);
    });

    test('TaskModel parsing and capacity test', () {
      final taskJson = {
        'taskId': 101,
        'taskName': 'Fill Sandbags',
        'description': 'Fill and prepare emergency sandbags.',
        'location': 'Newcastle Emergency Response Centre',
        'taskDate': '2026-10-06',
        'startTime': '09:00 AM',
        'volunteersRequired': 10,
        'registeredCount': 6,
        'status': 'Available',
      };

      final task = TaskModel.fromJson(taskJson);
      expect(task.taskId, 101);
      expect(task.taskName, 'Fill Sandbags');
      expect(task.volunteersRequired, 10);
      expect(task.registeredCount, 6);
      expect(task.spotsRemaining, 4);
      expect(task.isFull, false);
      expect(task.progressRatio, 0.6);
    });
  });
}
