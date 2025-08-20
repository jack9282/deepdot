import 'package:flutter/material.dart';
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
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );

      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
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
            playSound: true,
            enableVibration: true,
            enableLights: true,
            color: const Color(0xFF2196F3),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            timeoutAfter: 30000,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          );

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
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      print('알람 설정 완료: ID=$id, 시간=${scheduledDate.hour}:${scheduledDate.minute}');
    } catch (e) {
      print('알람 설정 중 오류 발생: $e');
    }
  }

  /// 매일 반복되는 일간 알람을 설정합니다.
  static Future<void> setDailyAlarm({
    required int id,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    try {
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );

      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'daily_alarm_channel',
            'Daily Alarm Channel',
            channelDescription: 'Channel for daily alarm notifications',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            enableLights: true,
            color: const Color(0xFF4CAF50),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            timeoutAfter: 30000,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          );

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
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      print('일간 알람 설정 완료: ID=$id, 시간=${scheduledDate.hour}:${scheduledDate.minute}');
    } catch (e) {
      print('일간 알람 설정 중 오류 발생: $e');
    }
  }

  /// 특정 ID를 가진 알람을 취소합니다.
  static Future<void> cancelAlarm(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      print('알람 취소 완료: ID=$id');
    } catch (e) {
      print('알람 취소 중 오류 발생: $e');
    }
  }

  /// 주간 반복 알람을 설정합니다.
  /// weekdays: 1=월요일, 2=화요일, ..., 7=일요일
  static Future<void> setWeeklyAlarm({
    required int baseId,
    required DateTime scheduledTime,
    required String title,
    required String body,
    required List<int> weekdays,
  }) async {
    try {
      await cancelWeeklyAlarm(baseId, weekdays);
      
      for (int weekday in weekdays) {
        int weeklyAlarmId = AlarmIdGenerator.generateWeeklyId(baseId, weekday);
        
        tz.TZDateTime scheduledDate = _getNextWeekdayTime(scheduledTime, weekday);
        
        if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
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
              playSound: true,
              enableVibration: true,
            );

        const DarwinNotificationDetails iOSPlatformChannelSpecifics =
            DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            );

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
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        
        print('주간 알람 설정 완료: ID=$weeklyAlarmId, 요일=$weekday, 시간=${scheduledDate.hour}:${scheduledDate.minute}');
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

  /// 특정 baseId로 생성된 모든 주간 알람을 취소합니다.
  static Future<void> cancelAllWeeklyAlarmsForBaseId(int baseId) async {
    try {
      for (int weekday = 1; weekday <= 7; weekday++) {
        int weeklyAlarmId = AlarmIdGenerator.generateWeeklyId(baseId, weekday);
        await _notificationsPlugin.cancel(weeklyAlarmId);
      }
    } catch (e) {
      print('주간 알람 전체 취소 중 오류 발생: $e');
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

  /// 예약된 알람 목록을 가져옵니다.
  static Future<List<PendingNotificationRequest>> getPendingAlarms() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      print('예약된 알람 목록 조회 중 오류 발생: $e');
      return [];
    }
  }

  /// 테스트용 알람 설정 (1분 후)
  static Future<void> setTestAlarm() async {
    try {
      final now = DateTime.now();
      final testTime = now.add(const Duration(minutes: 1));
      
      await setAlarm(
        id: 999999,
        scheduledTime: testTime,
        title: '테스트 알람',
        body: '알람이 정상적으로 작동합니다!',
      );
    } catch (e) {
      print('테스트 알람 설정 중 오류: $e');
    }
  }

  /// 즉시 알람 테스트 (5초 후)
  static Future<void> setImmediateAlarm() async {
    try {
      final now = DateTime.now();
      final testTime = now.add(const Duration(seconds: 5));
      
      await _notificationsPlugin.cancel(999998);
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'immediate_test_channel',
            'Immediate Test Channel',
            channelDescription: 'Channel for immediate test notifications',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            enableLights: true,
            color: const Color(0xFFFF9800),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            timeoutAfter: 30000,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(testTime, tz.local);

      await _notificationsPlugin.zonedSchedule(
        999998,
        '즉시 테스트 알람',
        '즉시 알람이 정상적으로 작동합니다!',
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      print('즉시 테스트 알람 설정 중 오류: $e');
    }
  }

  /// 시간대별 복용 알림 메시지 생성
  static String generateTakingMessage(String userName, DateTime time) {
    final hour = time.hour;
    String timeOfDay;
    String message;
    
    if (hour >= 5 && hour < 11) {
      timeOfDay = '아침';
      message = '물과 함께 섭취하세요!';
    } else if (hour >= 11 && hour < 17) {
      timeOfDay = '점심';
      message = '식후 30분 이내에 복용해주세요!';
    } else {
      timeOfDay = '저녁';
      message = '오늘 하루 마무리 잊지 말고 복약하세요!';
    }
    
    return '${userName}님 ${timeOfDay} 복약시간이에요~\n$message';
  }

  /// 루틴 알림 메시지 생성
  static String generateRoutineMessage(String userName, String routineName) {
    return '앗 ${userName}님 혹시..\n${routineName}을(를) 미달성했어요! 달성을 완료해주세요 :)';
  }
}
