import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'alarm_id_generator.dart';

class AlarmUtility {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 알림 플러그인을 초기화합니다.
  /// 앱 시작 시 한 번 호출해야 합니다.
  static Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
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
    } catch (e) {
      print('알람 유틸리티 초기화 중 오류 발생: $e');
    }
  }

  /// 특정 시간에 알람을 예약합니다.
  static Future<void> setAlarm({
    required int id,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    try {
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
            icon: '@mipmap/ic_launcher',
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

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
        androidScheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('알람 설정 중 오류 발생: $e');
    }
  }

  /// 특정 ID를 가진 알람을 취소합니다.
  static Future<void> cancelAlarm(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      print('알람 취소 중 오류 발생: $e');
    }
  }

  /// 주간 반복 알람을 설정합니다.
  static Future<void> setWeeklyAlarm({
    required int baseId,
    required DateTime scheduledTime,
    required String title,
    required String body,
    required List<int> weekdays, // 1=월요일, 2=화요일, ..., 7=일요일
  }) async {
    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      
      for (int weekday in weekdays) {
        int weeklyAlarmId = AlarmIdGenerator.generateWeeklyId(baseId, weekday);
        
        // 해당 요일의 다음 알람 시간을 계산
        tz.TZDateTime scheduledDate = _getNextWeekdayTime(scheduledTime, weekday);
        
        // 현재 시간보다 이전이면 다음 주로 설정
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 7));
        }

        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
              'weekly_alarm_channel',
              'Weekly Alarm Channel',
              channelDescription: 'Channel for weekly alarm notifications',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
              icon: '@mipmap/ic_launcher',
            );

        const DarwinNotificationDetails iOSPlatformChannelSpecifics =
            DarwinNotificationDetails();

        const NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics,
        );

        await _notificationsPlugin.zonedSchedule(
          weeklyAlarmId,
          title,
          body,
          scheduledDate,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.inexact,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (e) {
      print('주간 알람 설정 중 오류 발생: $e');
    }
  }

  /// 주어진 시간과 요일로 다음 알람 시간을 계산합니다.
  static tz.TZDateTime _getNextWeekdayTime(DateTime time, int weekday) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final int currentWeekday = now.weekday;
    
    int daysToAdd = weekday - currentWeekday;
    if (daysToAdd <= 0) {
      daysToAdd += 7;
    }
    
    return tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysToAdd,
      time.hour,
      time.minute,
    );
  }

  /// 주간 반복 알람을 취소합니다.
  static Future<void> cancelWeeklyAlarm(int baseId, List<int> weekdays) async {
    try {
      for (int weekday in weekdays) {
        int weeklyAlarmId = AlarmIdGenerator.generateWeeklyId(baseId, weekday);
        await _notificationsPlugin.cancel(weeklyAlarmId);
      }
    } catch (e) {
      print('주간 알람 취소 중 오류 발생: $e');
    }
  }

  /// 모든 알람을 취소합니다.
  static Future<void> cancelAllAlarms() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      print('모든 알람 취소 중 오류 발생: $e');
    }
  }
}
