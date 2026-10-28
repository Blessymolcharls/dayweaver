import 'package:uuid/uuid.dart';
import '../domain/activity.dart';
import '../domain/activity_category.dart';
import '../domain/activity_priority.dart';
import '../domain/time_utils.dart';

/// Provides realistic sample schedule data for testing and initial visual development.
/// Isolated from production repository logic.
class SampleActivities {
  SampleActivities._();

  static List<Activity> generateForDate(DateTime date) {
    final normalized = TimeUtils.normalizeDate(date);
    const uuid = Uuid();

    return [
      Activity(
        id: uuid.v4(),
        title: 'Deep Sleep & Recovery',
        category: ActivityCategory.sleep,
        date: normalized,
        startMinute: 0, // 00:00
        endMinute: 420, // 07:00
        notes: 'Sleep hygiene: phone kept outside bed area.',
        isCompleted: true,
        priority: ActivityPriority.high,
      ),
      Activity(
        id: uuid.v4(),
        title: 'Morning Fuel & Coffee',
        category: ActivityCategory.meals,
        date: normalized,
        startMinute: 420, // 07:00
        endMinute: 480, // 08:00
        notes: 'Oatmeal, banana, and pour-over coffee.',
        isCompleted: true,
        priority: ActivityPriority.low,
      ),
      Activity(
        id: uuid.v4(),
        title: 'Distributed Systems Lecture',
        category: ActivityCategory.college,
        date: normalized,
        startMinute: 510, // 08:30
        endMinute: 630, // 10:30
        notes: 'Hall B2. Covering Paxos consensus & Raft leader election.',
        isCompleted: true,
        priority: ActivityPriority.high,
      ),
      Activity(
        id: uuid.v4(),
        title: 'Algorithms & Data Structures Lab',
        category: ActivityCategory.college,
        date: normalized,
        startMinute: 645, // 10:45
        endMinute: 765, // 12:45
        notes: 'Dynamic programming problem set submission.',
        isCompleted: true,
        priority: ActivityPriority.high,
      ),
      Activity(
        id: uuid.v4(),
        title: 'Campus Canteen Lunch',
        category: ActivityCategory.meals,
        date: normalized,
        startMinute: 765, // 12:45
        endMinute: 825, // 13:45
        notes: 'Catch up with project teammates.',
        isCompleted: true,
        priority: ActivityPriority.low,
      ),
      Activity(
        id: uuid.v4(),
        title: 'Cloud Architecture Paper Review',
        category: ActivityCategory.personal,
        date: normalized,
        startMinute: 855, // 14:15
        endMinute: 945, // 15:45
        notes: 'Read DynamoDB paper; annotate trade-offs.',
        isCompleted: false,
        priority: ActivityPriority.medium,
      ),
      Activity(
        id: uuid.v4(),
        title: 'Evening Run & Stretch',
        category: ActivityCategory.rest,
        date: normalized,
        startMinute: 975, // 16:15
        endMinute: 1020, // 17:00
        notes: '4km around park loop.',
        isCompleted: false,
        priority: ActivityPriority.medium,
      ),
      Activity(
        id: uuid.v4(),
        title: 'Dayweaver Flutter Development',
        category: ActivityCategory.coding,
        date: normalized,
        startMinute: 1035, // 17:15
        endMinute: 1185, // 19:45
        notes: 'Milestone 1: 24h timeline and Drift persistence.',
        isCompleted: false,
        priority: ActivityPriority.high,
      ),
      Activity(
        id: uuid.v4(),
        title: 'Dinner & Relaxation',
        category: ActivityCategory.meals,
        date: normalized,
        startMinute: 1200, // 20:00
        endMinute: 1260, // 21:00
        notes: 'Warm soup and quiet downtime.',
        isCompleted: false,
        priority: ActivityPriority.low,
      ),
      Activity(
        id: uuid.v4(),
        title: 'Nightly Wind-down & Journal',
        category: ActivityCategory.rest,
        date: normalized,
        startMinute: 1320, // 22:00
        endMinute: 1380, // 23:00
        notes: 'Reflect on accomplishments and tomorrow outline.',
        isCompleted: false,
        priority: ActivityPriority.medium,
      ),
      Activity(
        id: uuid.v4(),
        title: 'Night Sleep',
        category: ActivityCategory.sleep,
        date: normalized,
        startMinute: 1380, // 23:00
        endMinute: 1440, // 24:00
        notes: 'Restful recovery.',
        isCompleted: false,
        priority: ActivityPriority.high,
      ),
    ];
  }
}
