import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AlarmUtility {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 알림 플러그인을 초기화합니다.
  /// 앱 시작 시 한 번 호출해야 합니다.
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    // 로컬 시간대를 설정합니다.
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  /// 특정 시간에 알람을 예약합니다.
  static Future<void> setAlarm({
    required int id,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'alarm_channel',
          'Alarm Channel',
          channelDescription: 'Channel for alarm notifications',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          sound: RawResourceAndroidNotificationSound('alarm_sound'),
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(sound: 'alarm_sound.aiff');

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // uiLocalNotificationDateInterpretation 파라미터를 삭제합니다.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 특정 ID를 가진 알람을 취소합니다.
  static Future<void> cancelAlarm(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// 주간 반복 알람을 설정합니다.
  static Future<void> setWeeklyAlarm({
    required int id,
    required DateTime scheduledTime,
    required String title,
    required String body,
    required List<int> weekdays, // 1=월요일, 2=화요일, ..., 7=일요일
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    
    // 각 요일별로 알람을 설정합니다
    for (int weekday in weekdays) {
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );

      // 현재 날짜가 설정된 시간보다 이전이면 다음 주로 설정
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // 요일에 맞게 날짜를 조정합니다
      int currentWeekday = scheduledDate.weekday;
      int daysToAdd = weekday - currentWeekday;
      if (daysToAdd <= 0) {
        daysToAdd += 7;
      }
      scheduledDate = scheduledDate.add(Duration(days: daysToAdd));

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'weekly_alarm_channel',
            'Weekly Alarm Channel',
            channelDescription: 'Channel for weekly alarm notifications',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            sound: RawResourceAndroidNotificationSound('alarm_sound'),
            icon: '@mipmap/ic_launcher',
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(sound: 'alarm_sound.aiff');

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // 각 요일별로 고유한 ID를 생성합니다
      int weeklyAlarmId = id * 10 + weekday;

      await _notificationsPlugin.zonedSchedule(
        weeklyAlarmId,
        title,
        body,
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// 주간 반복 알람을 취소합니다.
  static Future<void> cancelWeeklyAlarm(int baseId, List<int> weekdays) async {
    for (int weekday in weekdays) {
      int weeklyAlarmId = baseId * 10 + weekday;
      await _notificationsPlugin.cancel(weeklyAlarmId);
    }
  }

  /// 모든 알람을 취소합니다.
  static Future<void> cancelAllAlarms() async {
    await _notificationsPlugin.cancelAll();
  }
}
