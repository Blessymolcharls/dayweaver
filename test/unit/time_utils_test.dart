import 'package:flutter_test/flutter_test.dart';
import 'package:dayweaver/features/schedule/domain/time_utils.dart';

class MockTimeSpan implements HasTimeSpan {
  @override
  final String id;
  @override
  final String title;
  @override
  final int startMinute;
  @override
  final int endMinute;

  MockTimeSpan({
    required this.id,
    required this.title,
    required this.startMinute,
    required this.endMinute,
  });
}

void main() {
  group('TimeUtils - Formatting & Conversion', () {
    test('formatMinutes formats standard minutes correctly', () {
      expect(TimeUtils.formatMinutes(0), '00:00');
      expect(TimeUtils.formatMinutes(30), '00:30');
      expect(TimeUtils.formatMinutes(540), '09:00');
      expect(TimeUtils.formatMinutes(755), '12:35');
      expect(TimeUtils.formatMinutes(1380), '23:00');
      expect(TimeUtils.formatMinutes(1440), '24:00');
    });

    test('formatDuration formats minute durations into hours and minutes', () {
      expect(TimeUtils.formatDuration(0), '0m');
      expect(TimeUtils.formatDuration(45), '45m');
      expect(TimeUtils.formatDuration(60), '1h');
      expect(TimeUtils.formatDuration(90), '1h 30m');
      expect(TimeUtils.formatDuration(150), '2h 30m');
      expect(TimeUtils.formatDuration(1440), '24h');
    });

    test('normalizeDate removes time components', () {
      final input = DateTime(2026, 10, 24, 14, 30, 45, 123);
      final normalized = TimeUtils.normalizeDate(input);
      expect(normalized.year, 2026);
      expect(normalized.month, 10);
      expect(normalized.day, 24);
      expect(normalized.hour, 0);
      expect(normalized.minute, 0);
      expect(normalized.second, 0);
    });
  });

  group('TimeUtils - Validation Rules', () {
    test('validateTimeRange accepts valid ranges up to 1440', () {
      expect(TimeUtils.validateTimeRange(0, 60), isNull);
      expect(TimeUtils.validateTimeRange(540, 630), isNull);
      expect(TimeUtils.validateTimeRange(1380, 1440), isNull);
    });

    test('validateTimeRange rejects inverted or equal times', () {
      expect(
        TimeUtils.validateTimeRange(500, 500),
        'End time must be after start time',
      );
      expect(
        TimeUtils.validateTimeRange(600, 500),
        'End time must be after start time',
      );
    });

    test('validateTimeRange rejects out of bounds minutes', () {
      expect(TimeUtils.validateTimeRange(-10, 60), isNotNull);
      expect(TimeUtils.validateTimeRange(1440, 1500), isNotNull);
      expect(
        TimeUtils.validateTimeRange(500, 1441),
        'End time cannot exceed 24:00',
      );
    });
  });

  group('TimeUtils - Overlap Detection', () {
    test('doSpansOverlap correctly identifies overlapping intervals', () {
      // Overlapping in middle
      expect(TimeUtils.doSpansOverlap(100, 200, 150, 250), isTrue);
      // Contained inside
      expect(TimeUtils.doSpansOverlap(100, 300, 120, 180), isTrue);
      // Completely before
      expect(TimeUtils.doSpansOverlap(100, 200, 250, 350), isFalse);
      // Completely after
      expect(TimeUtils.doSpansOverlap(400, 500, 200, 300), isFalse);
    });

    test('consecutive boundaries that meet exactly do NOT overlap', () {
      // a ends exactly when b starts
      expect(TimeUtils.doSpansOverlap(100, 200, 200, 300), isFalse);
      // b ends exactly when a starts
      expect(TimeUtils.doSpansOverlap(200, 300, 100, 200), isFalse);
    });

    test(
      'checkOverlap flags conflicting activity and excludes editing self',
      () {
        final existing = [
          MockTimeSpan(
            id: '1',
            title: 'College Lecture',
            startMinute: 510,
            endMinute: 630,
          ),
          MockTimeSpan(
            id: '2',
            title: 'Lunch',
            startMinute: 720,
            endMinute: 780,
          ),
        ];

        // Overlaps with College Lecture
        final check1 = TimeUtils.checkOverlap(
          startMinute: 600,
          endMinute: 700,
          existingActivities: existing,
        );
        expect(check1.hasOverlap, isTrue);
        expect(check1.conflictingTitle, 'College Lecture');

        // Fits right between them without overlap
        final check2 = TimeUtils.checkOverlap(
          startMinute: 630,
          endMinute: 720,
          existingActivities: existing,
        );
        expect(check2.hasOverlap, isFalse);

        // Editing existing activity itself does not self-conflict
        final check3 = TimeUtils.checkOverlap(
          startMinute: 510,
          endMinute: 630,
          existingActivities: existing,
          excludeActivityId: '1',
        );
        expect(check3.hasOverlap, isFalse);
      },
    );
  });

  group('TimeUtils - Unscheduled Gaps Calculation', () {
    test('computes gaps at start, middle, and end of 1440-minute day', () {
      final activities = [
        MockTimeSpan(
          id: '1',
          title: 'Morning',
          startMinute: 480,
          endMinute: 600,
        ), // 08:00 - 10:00
        MockTimeSpan(
          id: '2',
          title: 'Afternoon',
          startMinute: 720,
          endMinute: 840,
        ), // 12:00 - 14:00
      ];

      final gaps = TimeUtils.calculateUnscheduledGaps(activities);
      expect(gaps.length, 3);

      // Gap 1: 00:00 - 08:00
      expect(gaps[0].startMinute, 0);
      expect(gaps[0].endMinute, 480);
      expect(gaps[0].durationMinutes, 480);

      // Gap 2: 10:00 - 12:00
      expect(gaps[1].startMinute, 600);
      expect(gaps[1].endMinute, 720);
      expect(gaps[1].durationMinutes, 120);

      // Gap 3: 14:00 - 24:00
      expect(gaps[2].startMinute, 840);
      expect(gaps[2].endMinute, 1440);
      expect(gaps[2].durationMinutes, 600);
    });

    test('fully empty day yields a single full-day gap', () {
      final gaps = TimeUtils.calculateUnscheduledGaps(<MockTimeSpan>[]);
      expect(gaps.length, 1);
      expect(gaps[0].startMinute, 0);
      expect(gaps[0].endMinute, 1440);
      expect(gaps[0].durationMinutes, 1440);
    });

    test('fully packed consecutive day yields zero gaps', () {
      final activities = [
        MockTimeSpan(id: '1', title: 'Night', startMinute: 0, endMinute: 480),
        MockTimeSpan(id: '2', title: 'Day', startMinute: 480, endMinute: 1440),
      ];

      final gaps = TimeUtils.calculateUnscheduledGaps(activities);
      expect(gaps.isEmpty, isTrue);
    });
  });
}
