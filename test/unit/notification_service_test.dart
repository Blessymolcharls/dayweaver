import 'package:dayweaver/core/notifications/notification_service.dart';
import 'package:dayweaver/features/schedule/domain/activity.dart';
import 'package:dayweaver/features/schedule/domain/activity_category.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test implementation of [NotificationService] for unit testing scheduling logic
class TestNotificationService implements NotificationService {
  final Map<int, Activity> scheduledReminders = {};
  bool isInitialized = false;
  bool permissionsGranted = true;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    return permissionsGranted;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    return permissionsGranted;
  }

  @override
  int getNotificationId(String activityId) {
    return activityId.hashCode & 0x7FFFFFFF;
  }

  @override
  Future<bool> scheduleActivityReminder(Activity activity) async {
    if (!isInitialized) await initialize();

    if (activity.reminderOffsetMinutes == null || activity.isCompleted) {
      await cancelActivityReminder(activity.id);
      return false;
    }

    final int scheduledMinuteOfDay =
        activity.startMinute - activity.reminderOffsetMinutes!;
    final DateTime targetDateTime = DateTime(
      activity.date.year,
      activity.date.month,
      activity.date.day,
      scheduledMinuteOfDay ~/ 60,
      scheduledMinuteOfDay % 60,
    );

    if (targetDateTime.isBefore(DateTime.now())) {
      await cancelActivityReminder(activity.id);
      return false;
    }

    final int id = getNotificationId(activity.id);
    scheduledReminders[id] = activity;
    return true;
  }

  @override
  Future<void> cancelActivityReminder(String activityId) async {
    final int id = getNotificationId(activityId);
    scheduledReminders.remove(id);
  }

  @override
  Future<int> rescheduleAllReminders(List<Activity> upcomingActivities) async {
    if (!isInitialized) await initialize();
    int count = 0;
    for (final Activity a in upcomingActivities) {
      final bool scheduled = await scheduleActivityReminder(a);
      if (scheduled) count++;
    }
    return count;
  }
}

void main() {
  group('Notification Service & Reminders Logic', () {
    late TestNotificationService service;
    late DateTime futureDate;

    setUp(() {
      service = TestNotificationService();
      final DateTime now = DateTime.now();
      futureDate = DateTime(now.year, now.month, now.day + 2);
    });

    test(
      'getNotificationId produces stable, collision-resistant 31-bit integer',
      () {
        const String id1 = 'uuid-abc-123';
        const String id2 = 'uuid-xyz-789';

        final int notifId1 = service.getNotificationId(id1);
        final int notifId2 = service.getNotificationId(id2);

        // Verify deterministic
        expect(service.getNotificationId(id1), equals(notifId1));
        expect(service.getNotificationId(id2), equals(notifId2));

        // Verify within positive 31-bit range [0, 0x7FFFFFFF]
        expect(notifId1, greaterThanOrEqualTo(0));
        expect(notifId1, lessThanOrEqualTo(0x7FFFFFFF));
        expect(notifId2, greaterThanOrEqualTo(0));
        expect(notifId2, lessThanOrEqualTo(0x7FFFFFFF));

        // Verify distinct IDs produce distinct hashes
        expect(notifId1, isNot(equals(notifId2)));
      },
    );

    test(
      'scheduleActivityReminder schedules reminder for future uncompleted activity',
      () async {
        final Activity act = Activity(
          id: 'act-future-1',
          title: 'Compiler Design Lecture',
          category: ActivityCategory.college,
          date: futureDate,
          startMinute: 600, // 10:00
          endMinute: 720,
          reminderOffsetMinutes: 15,
          isCompleted: false,
        );

        final bool scheduled = await service.scheduleActivityReminder(act);
        expect(scheduled, isTrue);

        final int id = service.getNotificationId(act.id);
        expect(service.scheduledReminders.containsKey(id), isTrue);
        expect(
          service.scheduledReminders[id]?.title,
          equals('Compiler Design Lecture'),
        );
      },
    );

    test(
      'scheduleActivityReminder ignores completed activities and cancels reminder',
      () async {
        final Activity act = Activity(
          id: 'act-completed-1',
          title: 'Morning Yoga',
          category: ActivityCategory.rest,
          date: futureDate,
          startMinute: 420,
          endMinute: 480,
          reminderOffsetMinutes: 10,
          isCompleted: true, // Completed
        );

        final bool scheduled = await service.scheduleActivityReminder(act);
        expect(scheduled, isFalse);

        final int id = service.getNotificationId(act.id);
        expect(service.scheduledReminders.containsKey(id), isFalse);
      },
    );

    test(
      'scheduleActivityReminder does not schedule past-due activities',
      () async {
        final DateTime pastDate = DateTime(2020, 1, 1);
        final Activity pastAct = Activity(
          id: 'act-past-1',
          title: 'Old Assignment',
          category: ActivityCategory.college,
          date: pastDate,
          startMinute: 600,
          endMinute: 720,
          reminderOffsetMinutes: 15,
          isCompleted: false,
        );

        final bool scheduled = await service.scheduleActivityReminder(pastAct);
        expect(scheduled, isFalse);
        expect(service.scheduledReminders.isEmpty, isTrue);
      },
    );

    test('cancelActivityReminder removes scheduled notification', () async {
      final Activity act = Activity(
        id: 'act-cancel-1',
        title: 'Evening Run',
        category: ActivityCategory.rest,
        date: futureDate,
        startMinute: 1100,
        endMinute: 1160,
        reminderOffsetMinutes: 30,
      );

      await service.scheduleActivityReminder(act);
      expect(service.scheduledReminders.length, equals(1));

      await service.cancelActivityReminder(act.id);
      expect(service.scheduledReminders.length, equals(0));
    });

    test(
      'rescheduleAllReminders rebuilds upcoming reminders in batch',
      () async {
        final List<Activity> list = [
          Activity(
            id: 'batch-1',
            title: 'Algorithmic Puzzles',
            category: ActivityCategory.coding,
            date: futureDate,
            startMinute: 600,
            endMinute: 700,
            reminderOffsetMinutes: 10,
          ),
          Activity(
            id: 'batch-2',
            title: 'Database Systems',
            category: ActivityCategory.college,
            date: futureDate,
            startMinute: 720,
            endMinute: 800,
            reminderOffsetMinutes: 15,
          ),
          Activity(
            id: 'batch-3',
            title: 'Dinner with Roommates',
            category: ActivityCategory.meals,
            date: futureDate,
            startMinute: 1200,
            endMinute: 1260,
            reminderOffsetMinutes: null, // No reminder
          ),
        ];

        final int scheduledCount = await service.rescheduleAllReminders(list);
        expect(scheduledCount, equals(2));
        expect(service.scheduledReminders.length, equals(2));
      },
    );

    test('permission status reflects user grant or denial', () async {
      expect(await service.areNotificationsEnabled(), isTrue);

      service.permissionsGranted = false;
      expect(await service.areNotificationsEnabled(), isFalse);
      expect(await service.requestPermissions(), isFalse);
    });
  });
}
