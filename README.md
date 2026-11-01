# Dayweaver

Dayweaver is an offline-first 24-hour personal schedule planner, routine manager, and goal tracking application built with Flutter. Designed with a calm, warm Material 3 aesthetic, it helps students and professionals organize college schedules, assignments, coding projects, career milestones, habits, rest, and sleep across all 24 hours of the day.

---

## ✨ Features

### 📅 1. Today & 24-Hour Timeline
- **Continuous 24-Hour Timeline**: View every hour from 00:00 to 24:00 with scheduled activity blocks and visual gaps for unscheduled time.
- **Real-Time Marker**: Live position indicator showing the current minute of the day.
- **Activity Lifecycle**: Create, edit, complete, duplicate, or reschedule activities.
- **Smart Overlap Detection**: Instant conflict validation preventing conflicting bookings, with automatic next-fit gap detection on duplicate.
- **Category-Coordinated Design**: Visual differentiation for Academics/College, Coding, Personal Work, Meals, Rest, and Sleep.

### 🗓️ 2. Planner & Reusable Routines
- **Monthly Interactive Calendar**: Navigate across any past or future day with daily schedule previews and completion status indicators.
- **Routine Templates**: Save and curate daily templates (e.g. "Exam Prep Day", "Standard Weekday", "Weekend Grind").
- **Conflict Handling Strategies**: Apply routine templates to dates using Skip Conflicts, Overwrite, or Safe Abort.
- **Schedule Copying**: Transaction-safe duplication of an entire day's schedule to another date.

### 🔔 3. Android Notifications & Daily Reviews
- **Reliable Local Notifications**: Android notification scheduling using `flutter_local_notifications` with timezone awareness.
- **Stable Notification IDs**: 31-bit collision-resistant identifier hashing linked to persistent activity records.
- **Configurable Reminder Offsets**: Notify at start or $X$ minutes prior. Automatically skips past-due tasks.
- **Recurring Activities**: Daily, weekday, and custom day recurrence rules with idempotent generation and exclusion tracking.
- **Daily Reflection & Reviews**: End-of-day review notes, planned vs. actual completion stats, and productivity journaling.

### 🎯 4. Goals, Milestones & Productivity Tracking
- **Measurable Goals**: Define numerical targets (e.g., "50 LeetCode Problems", "20 Book Chapters", "40 Study Hours") with clamped progress accounting ($0\% \dots 100\%$).
- **Goal Categories**: Academics, Coding & Skills, Projects, Career & Placements, Health & Wellbeing, Personal Development, and Custom.
- **Progress Tracking**: Record progress with dual modes: incremental (`+amount`) or absolute (`=amount`) with reflection notes and update history.
- **Milestone Breakdown**: Break goals into structured checklists with independent milestone progress.
- **Schedule Integration**: Link schedule activities directly to goals. Linked goals surface in activity sheets, and activities surface in goal details.
- **Approaching Deadlines**: Automatic deadline countdowns and urgent reminder tags.

### 📊 5. Weekly Analytics & Insights
- **Weekly Completion Metrics**: Track planned vs. completed hours, daily trends, and task completion percentages.
- **Category Allocation Breakdown**: Visual distribution of hours dedicated to college, deep work, coding, rest, and leisure.
- **Goal Progress Analytics**: Weekly active goal tallies, goals completed in the week, total progress updates logged, and upcoming deadlines.

---

## 🎨 Visual Identity & Theme

Dayweaver uses an intentional, calm, non-distracting palette:
- **Background**: Warm Cream (`#FAF6EF`)
- **Secondary Surfaces**: Paper Beige (`#F0E6D8`)
- **Primary Accent**: Muted Terracotta (`#B96F52`)
- **Secondary Accent**: Sage Green (`#8A9B83`)
- **Main Text**: Deep Warm Charcoal (`#39332F`)
- **Typography**: Editorial serif headings (*Newsreader*) paired with clean, readable sans-serif body (*Plus Jakarta Sans*).

---

## 🏗️ Architecture & Technology Stack

- **Framework**: Flutter (Dart stable SDK)
- **State Management**: [Flutter Riverpod](https://pub.dev/packages/flutter_riverpod)
- **Local Persistence**: [Drift](https://pub.dev/packages/drift) (SQLite) with typed SQL tables and transactional migrations
- **Local Notifications**: `flutter_local_notifications` & `timezone`
- **Architecture Pattern**: Feature-first modular structure:
  ```
  lib/
  ├── core/
  │   ├── database/          # Drift database, schema v4, and table definitions
  │   ├── navigation/        # App shell and bottom navigation
  │   ├── notifications/     # Android notification service & channel setup
  │   └── theme/             # Material 3 colors and typography
  ├── features/
  │   ├── today/             # 24-hour timeline, day summary, daily review
  │   ├── planner/           # Monthly calendar, routine template management
  │   ├── goals/             # Goals, milestones, progress updates, and activity linking
  │   ├── insights/          # Weekly time distribution, analytics, and goals insight
  │   ├── schedule/          # Activity repository, recurrence engine, and time utilities
  │   └── settings/          # Notification permissions and app preferences
  └── shared/                # Common reusable sheets, dialogs, and widgets
  ```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.11+ compatible)
- [Android Studio](https://developer.android.com/studio) or VS Code with Flutter extension
- An Android device or emulator running API 26+ (Android 8.0+)

### Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone https://github.com/<your-username>/dayweaver.git
   cd dayweaver
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Drift SQLite code** (if modifying tables):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run static analysis and tests**:
   ```bash
   flutter analyze
   flutter test
   ```

5. **Run the application**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing

The test suite covers domain logic, SQLite persistence, recurrence generation, notification scheduling, and widget interactions:

```bash
# Run all unit and widget tests
flutter test

# Run specific feature tests
flutter test test/unit/goals_and_milestones_test.dart
flutter test test/unit/drift_goal_repository_test.dart
flutter test test/widget/goals_screen_test.dart
```

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
