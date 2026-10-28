import 'package:uuid/uuid.dart';
import '../domain/activity_category.dart';
import '../domain/activity_priority.dart';
import '../domain/routine_template.dart';
import '../domain/routine_template_block.dart';

class SampleTemplates {
  SampleTemplates._();

  static List<RoutineTemplate> getDefaultTemplates() {
    const uuid = Uuid();

    // 1. College Day
    final collegeTemplateId = uuid.v4();
    final collegeDay = RoutineTemplate(
      id: collegeTemplateId,
      name: 'College Day',
      description:
          'Balanced schedule with university lectures, lab work, study, and rest.',
      blocks: [
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: collegeTemplateId,
          title: 'Deep Sleep & Recovery',
          category: ActivityCategory.sleep,
          startMinute: 0,
          endMinute: 420, // 07:00
          priority: ActivityPriority.high,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: collegeTemplateId,
          title: 'Morning Fuel & Coffee',
          category: ActivityCategory.meals,
          startMinute: 420,
          endMinute: 480, // 08:00
          priority: ActivityPriority.low,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: collegeTemplateId,
          title: 'Core Systems Lecture',
          category: ActivityCategory.college,
          startMinute: 510, // 08:30
          endMinute: 630, // 10:30
          notes: 'Lecture Hall 2',
          priority: ActivityPriority.high,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: collegeTemplateId,
          title: 'Algorithms & Computing Lab',
          category: ActivityCategory.college,
          startMinute: 645, // 10:45
          endMinute: 765, // 12:45
          notes: 'Problem set submissions',
          priority: ActivityPriority.high,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: collegeTemplateId,
          title: 'Campus Lunch Break',
          category: ActivityCategory.meals,
          startMinute: 765, // 12:45
          endMinute: 825, // 13:45
          priority: ActivityPriority.low,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: collegeTemplateId,
          title: 'Personal Study & Review',
          category: ActivityCategory.personal,
          startMinute: 870, // 14:30
          endMinute: 990, // 16:30
          priority: ActivityPriority.medium,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: collegeTemplateId,
          title: 'Evening Run / Gym',
          category: ActivityCategory.rest,
          startMinute: 1005, // 16:45
          endMinute: 1065, // 17:45
          priority: ActivityPriority.medium,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: collegeTemplateId,
          title: 'Coding Projects',
          category: ActivityCategory.coding,
          startMinute: 1080, // 18:00
          endMinute: 1200, // 20:00
          priority: ActivityPriority.high,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: collegeTemplateId,
          title: 'Dinner & Leisure',
          category: ActivityCategory.meals,
          startMinute: 1200, // 20:00
          endMinute: 1275, // 21:15
          priority: ActivityPriority.low,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: collegeTemplateId,
          title: 'Night Sleep',
          category: ActivityCategory.sleep,
          startMinute: 1380, // 23:00
          endMinute: 1440, // 24:00
          priority: ActivityPriority.high,
        ),
      ],
    );

    // 2. Weekend
    final weekendTemplateId = uuid.v4();
    final weekendDay = RoutineTemplate(
      id: weekendTemplateId,
      name: 'Weekend',
      description:
          'Downtime, open source exploration, outdoor activities, and recharging.',
      blocks: [
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: weekendTemplateId,
          title: 'Extended Sleep',
          category: ActivityCategory.sleep,
          startMinute: 0,
          endMinute: 510, // 08:30
          priority: ActivityPriority.medium,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: weekendTemplateId,
          title: 'Slow Weekend Brunch',
          category: ActivityCategory.meals,
          startMinute: 540, // 09:00
          endMinute: 615, // 10:15
          priority: ActivityPriority.low,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: weekendTemplateId,
          title: 'Side Projects & Creative Coding',
          category: ActivityCategory.coding,
          startMinute: 630, // 10:30
          endMinute: 810, // 13:30
          notes: 'Build features without deadlines',
          priority: ActivityPriority.medium,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: weekendTemplateId,
          title: 'Outdoor Nature Walk',
          category: ActivityCategory.rest,
          startMinute: 900, // 15:00
          endMinute: 990, // 16:30
          priority: ActivityPriority.low,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: weekendTemplateId,
          title: 'Reading & Hobbies',
          category: ActivityCategory.personal,
          startMinute: 1020, // 17:00
          endMinute: 1140, // 19:00
          priority: ActivityPriority.low,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: weekendTemplateId,
          title: 'Dinner & Social Time',
          category: ActivityCategory.meals,
          startMinute: 1170, // 19:30
          endMinute: 1290, // 21:30
          priority: ActivityPriority.low,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: weekendTemplateId,
          title: 'Restful Sleep',
          category: ActivityCategory.sleep,
          startMinute: 1380, // 23:00
          endMinute: 1440, // 24:00
          priority: ActivityPriority.high,
        ),
      ],
    );

    // 3. Exam Preparation
    final examTemplateId = uuid.v4();
    final examDay = RoutineTemplate(
      id: examTemplateId,
      name: 'Exam Preparation',
      description:
          'Structured high-intensity revision with strategic breaks to maximize retention.',
      blocks: [
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: examTemplateId,
          title: 'Restful Sleep',
          category: ActivityCategory.sleep,
          startMinute: 0,
          endMinute: 420, // 07:00
          priority: ActivityPriority.high,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: examTemplateId,
          title: 'Breakfast & Plan',
          category: ActivityCategory.meals,
          startMinute: 420,
          endMinute: 480, // 08:00
          priority: ActivityPriority.low,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: examTemplateId,
          title: 'Deep Revision: Core Concepts',
          category: ActivityCategory.college,
          startMinute: 480, // 08:00
          endMinute: 690, // 11:30
          notes: 'Active recall & flashcard drilling',
          priority: ActivityPriority.high,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: examTemplateId,
          title: 'Nutritious Lunch & Rest',
          category: ActivityCategory.meals,
          startMinute: 705, // 11:45
          endMinute: 765, // 12:45
          priority: ActivityPriority.medium,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: examTemplateId,
          title: 'Past Exam Paper Solving',
          category: ActivityCategory.college,
          startMinute: 795, // 13:15
          endMinute: 975, // 16:15
          notes: 'Timed simulation',
          priority: ActivityPriority.high,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: examTemplateId,
          title: 'Mental Reset Walk',
          category: ActivityCategory.rest,
          startMinute: 990, // 16:30
          endMinute: 1035, // 17:15
          priority: ActivityPriority.medium,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: examTemplateId,
          title: 'Formula & Summary Review',
          category: ActivityCategory.personal,
          startMinute: 1050, // 17:30
          endMinute: 1170, // 19:30
          priority: ActivityPriority.high,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: examTemplateId,
          title: 'Dinner & Relaxation',
          category: ActivityCategory.meals,
          startMinute: 1200, // 20:00
          endMinute: 1260, // 21:00
          priority: ActivityPriority.low,
        ),
        RoutineTemplateBlock(
          id: uuid.v4(),
          templateId: examTemplateId,
          title: 'Night Sleep',
          category: ActivityCategory.sleep,
          startMinute: 1350, // 22:30
          endMinute: 1440, // 24:00
          priority: ActivityPriority.high,
        ),
      ],
    );

    return [collegeDay, weekendDay, examDay];
  }
}
