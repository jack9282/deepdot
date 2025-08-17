import 'package:permission_handler/permission_handler.dart';

class AppPermission {
  /// 요청할 수 있는 권한 종류
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  /// 여러 권한을 한 번에 요청
  static Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    List<Permission> permissions,
  ) async {
    return await permissions.request();
  }

  /// 권한 상태 확인
  static Future<bool> isPermissionGranted(Permission permission) async {
    return await permission.status.isGranted;
  }

  /// 설정으로 유도 (권한 거부 시)
  static Future<void> openAppSettingsIfNeeded(Permission permission) async {
    final status = await permission.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  static Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      print('알림 권한 상태: $status');
      return status.isGranted;
    } catch (e) {
      print('알림 권한 요청 중 오류: $e');
      return false;
    }
  }

  /// 배터리 최적화 예외 권한 요청
  static Future<bool> requestBatteryOptimizationPermission() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      print('배터리 최적화 예외 권한 상태: $status');
      return status.isGranted;
    } catch (e) {
      print('배터리 최적화 예외 권한 요청 중 오류: $e');
      return false;
    }
  }
}
