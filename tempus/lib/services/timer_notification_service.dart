import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level callback — must be a top-level or static function.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TimerTaskHandler());
}

/// Runs inside the foreground-service isolate.
/// Reads the persisted timer state every second and updates the notification.
class TimerTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Nothing special to initialise.
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();

    final isRunning = prefs.getBool('tempus_timer_running') ?? false;
    if (!isRunning) {
      FlutterForegroundTask.stopService();
      return;
    }

    final accumulated = prefs.getInt('tempus_timer_accumulated_secs') ?? 0;
    final segmentStr = prefs.getString('tempus_timer_segment_start');
    final sessionNum = prefs.getInt('tempus_notification_session') ?? 0;

    int totalSeconds = accumulated;
    if (segmentStr != null) {
      final segmentStart = DateTime.parse(segmentStr);
      totalSeconds += DateTime.now().difference(segmentStart).inSeconds;
    }

    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');

    final sessionLabel = sessionNum > 0 ? 'Session #$sessionNum' : 'Session';

    FlutterForegroundTask.updateService(
      notificationTitle: '⏱ Tempus — $sessionLabel',
      notificationText: '$h:$m:$s',
    );

    FlutterForegroundTask.sendDataToMain(<String, dynamic>{
      'totalSeconds': totalSeconds,
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // Nothing to clean up.
  }

  @override
  void onReceiveData(Object data) {
    if (data is String && data == 'pause') {
      // Pause requested from notification button — let the main isolate
      // handle the actual pause logic. We just stop the service here.
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'btn_pause') {
      // Tell the main isolate to pause.
      FlutterForegroundTask.sendDataToMain(<String, dynamic>{
        'action': 'pause',
      });
    }
  }

  @override
  void onNotificationPressed() {
    // Bring the app to the foreground when the notification is tapped.
    FlutterForegroundTask.launchApp('/');
  }

  @override
  void onNotificationDismissed() {
    // Ongoing notifications can't be dismissed, so this is a no-op.
  }
}

/// Utility class used from the UI layer to start / stop the foreground service.
class TimerNotificationService {
  TimerNotificationService._();

  /// Call once at app startup.
  static void init() {
    FlutterForegroundTask.initCommunicationPort();

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tempus_timer_channel',
        channelName: 'Tempus Timer',
        channelDescription:
            'Shows the running timer while the app is in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.HIGH,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000), // every 1s
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// Request notification permission (Android 13+).
  static Future<void> requestPermissions() async {
    final perm = await FlutterForegroundTask.checkNotificationPermission();
    if (perm != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  /// Start the foreground service with the timer notification.
  static Future<void> startNotification({required int sessionNumber}) async {
    // Persist session number for the task handler to read.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tempus_notification_session', sessionNumber);

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        serviceId: 888,
        notificationTitle: '⏱ Tempus — Session #$sessionNumber',
        notificationText: '00:00:00',
        notificationButtons: [
          const NotificationButton(id: 'btn_pause', text: 'Pause'),
        ],
        callback: startCallback,
      );
    }
  }

  /// Stop the foreground service (timer paused / saved).
  static Future<void> stopNotification() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}
