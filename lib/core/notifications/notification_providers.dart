import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_notification_service.dart';
import 'notification_service.dart';

/// Provider for the app-wide [NotificationService] instance.
final Provider<NotificationService> notificationServiceProvider =
    Provider<NotificationService>((Ref ref) {
      return LocalNotificationService();
    });

/// StateNotifier or FutureProvider to observe permission status.
final FutureProvider<bool> notificationPermissionStatusProvider =
    FutureProvider<bool>((Ref ref) async {
      final NotificationService service = ref.watch(
        notificationServiceProvider,
      );
      return service.areNotificationsEnabled();
    });
