import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/theme/app_theme.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../utils/alarm.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/taking_repository.dart';
import '../../../data/repositories/routine_repository.dart';
import '../../../api/token_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 알림 설정 상태
  bool _scheduleNotification = true;
  bool _medicationNotification = true;
  bool _routineNotification = true;

  // 동기화 설정 상태
  bool _deviceSync = true;
  bool _isLoggedIn = false; // 로그인 상태

  // AI 루틴 추천 설정 상태
  bool _aiRoutineRecommendation = false;

  // SharedPreferences 키
  static const String _scheduleNotificationKey = 'schedule_notification';
  static const String _medicationNotificationKey = 'medication_notification';
  static const String _routineNotificationKey = 'routine_notification';
  static const String _deviceSyncKey = 'device_sync';
  static const String _aiRoutineKey = 'ai_routine_recommendation';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkLoginStatus();
  }

  /// 로그인 상태를 확인합니다
  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await TokenManager.instance.hasValidToken();
    setState(() {
      _isLoggedIn = isLoggedIn;
      // 비회원은 무조건 동기화 OFF
      if (!isLoggedIn) {
        _deviceSync = false;
      }
    });

    // 로그인 상태가 변경되면 설정 저장
    final prefs = await SharedPreferences.getInstance();
    if (isLoggedIn) {
      // 로그인 시 자동으로 동기화 ON
      _deviceSync = prefs.getBool(_deviceSyncKey) ?? true;
      await prefs.setBool(_deviceSyncKey, _deviceSync);
    } else {
      // 비회원은 무조건 OFF
      await prefs.setBool(_deviceSyncKey, false);
    }
    setState(() {});
  }

  /// SharedPreferences에서 설정값을 불러옵니다
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = await TokenManager.instance.hasValidToken();

    setState(() {
      _scheduleNotification = prefs.getBool(_scheduleNotificationKey) ?? true;
      _medicationNotification =
          prefs.getBool(_medicationNotificationKey) ?? true;
      _routineNotification = prefs.getBool(_routineNotificationKey) ?? true;
      // 비회원은 무조건 동기화 OFF, 회원은 저장된 값 사용
      _deviceSync = isLoggedIn
          ? (prefs.getBool(_deviceSyncKey) ?? true)
          : false;
      _aiRoutineRecommendation = prefs.getBool(_aiRoutineKey) ?? false;
    });
  }

  /// 알림 설정 상태를 저장하고 알림을 업데이트합니다
  Future<void> _saveNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// 일정 알림 상태를 변경합니다
  Future<void> _toggleScheduleNotification(bool value) async {
    setState(() {
      _scheduleNotification = value;
    });
    await _saveNotificationSetting(_scheduleNotificationKey, value);

    if (!value) {
      // 일정 알림 비활성화 시 모든 일정 알림 취소
      await _cancelScheduleNotifications();
    } else {
      // 일정 알림 활성화 시 기존 일정들의 알림 재설정
      await _rescheduleScheduleNotifications();
    }
  }

  /// 복약 알림 상태를 변경합니다
  Future<void> _toggleMedicationNotification(bool value) async {
    setState(() {
      _medicationNotification = value;
    });
    await _saveNotificationSetting(_medicationNotificationKey, value);

    if (!value) {
      // 복약 알림 비활성화 시 모든 복약 알림 취소
      await _cancelMedicationNotifications();
    } else {
      // 복약 알림 활성화 시 기존 복약들의 알림 재설정
      await _rescheduleMedicationNotifications();
    }
  }

  /// 루틴 알림 상태를 변경합니다
  Future<void> _toggleRoutineNotification(bool value) async {
    setState(() {
      _routineNotification = value;
    });
    await _saveNotificationSetting(_routineNotificationKey, value);

    if (!value) {
      // 루틴 알림 비활성화 시 모든 루틴 알림 취소
      await _cancelRoutineNotifications();
    } else {
      // 루틴 알림 활성화 시 기존 루틴들의 알림 재설정
      await _rescheduleRoutineNotifications();
    }
  }

  /// 일정 알림을 모두 취소합니다
  Future<void> _cancelScheduleNotifications() async {
    try {
      // 실제 예약된 알림 목록 가져오기
      final pendingAlarms = await AlarmUtility.getPendingAlarms();

      // 10000-19999 범위의 일정 알림만 취소
      for (final alarm in pendingAlarms) {
        if (alarm.id >= 10000 && alarm.id < 20000) {
          await AlarmUtility.cancelAlarm(alarm.id);
        }
      }
    } catch (e) {
      print('일정 알림 취소 중 오류: $e');
    }
  }

  /// 복약 알림을 모두 취소합니다
  Future<void> _cancelMedicationNotifications() async {
    try {
      // 실제 예약된 알림 목록 가져오기
      final pendingAlarms = await AlarmUtility.getPendingAlarms();

      // 20000-29999 범위의 복약 알림만 취소
      for (final alarm in pendingAlarms) {
        if (alarm.id >= 20000 && alarm.id < 30000) {
          await AlarmUtility.cancelAlarm(alarm.id);
        }
      }
    } catch (e) {
      print('복약 알림 취소 중 오류: $e');
    }
  }

  /// 루틴 알림을 모두 취소합니다
  Future<void> _cancelRoutineNotifications() async {
    try {
      // 실제 예약된 알림 목록 가져오기
      final pendingAlarms = await AlarmUtility.getPendingAlarms();

      // 30000-49999 범위의 루틴 알림 취소 (범위 확장)
      for (final alarm in pendingAlarms) {
        if (alarm.id >= 30000 && alarm.id < 50000) {
          await AlarmUtility.cancelAlarm(alarm.id);
          print('루틴 알림 취소: ID=${alarm.id}');
        }
      }
      print('루틴 알림 취소 완료');
    } catch (e) {
      print('루틴 알림 취소 중 오류: $e');
    }
  }

  /// 일정 알림을 재설정합니다
  Future<void> _rescheduleScheduleNotifications() async {
    try {
      final scheduleRepository = ScheduleRepository();
      await scheduleRepository.rescheduleAllNotifications();
    } catch (e) {
      print('일정 알림 재설정 실패: $e');
    }
  }

  /// 복약 알림을 재설정합니다
  Future<void> _rescheduleMedicationNotifications() async {
    try {
      final takingRepository = TakingRepository();
      await takingRepository.rescheduleAllNotifications();
    } catch (e) {
      print('복약 알림 재설정 실패: $e');
    }
  }

  /// 루틴 알림을 재설정합니다
  Future<void> _rescheduleRoutineNotifications() async {
    try {
      final routineRepository = RoutineRepository();
      await routineRepository.rescheduleAllNotifications();
    } catch (e) {
      print('루틴 알림 재설정 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700; // 작은 화면 감지
    final scaleFactor = screenHeight / 800; // 기준 높이 800px 대비 비율

    // 반응형 간격 계산
    double getSpacing(double baseSize) {
      if (isSmallScreen) {
        return baseSize * 0.5; // 작은 화면에서는 50%로 줄임
      }
      return baseSize * scaleFactor.clamp(0.7, 1.2); // 0.7 ~ 1.2배 사이로 제한
    }

    // 반응형 폰트 크기 계산
    double getFontSize(double baseSize) {
      if (isSmallScreen) {
        return baseSize * 0.85; // 작은 화면에서는 85%로 줄임
      }
      return baseSize * scaleFactor.clamp(0.85, 1.1); // 0.85 ~ 1.1배 사이로 제한
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: isSmallScreen ? 48 : 56,
        title: Text(
          '설정',
          style: TextStyle(
            fontSize: getFontSize(22),
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: getSpacing(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 스크롤 가능한 메인 컨텐츠
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 계정 정보 섹션
                      _buildSectionHeader('계정 정보', getFontSize(22)),
                      SizedBox(height: getSpacing(12)),

                      // 아이디
                      _buildInfoItem('아이디', _getUserId(), getFontSize(18)),
                      SizedBox(height: getSpacing(8)),

                      // 이메일
                      _buildInfoItem('이메일', _getUserEmail(), getFontSize(18)),

                      SizedBox(height: getSpacing(20)),

                      // 알림 섹션
                      _buildSectionHeader('알림', getFontSize(22)),
                      SizedBox(height: getSpacing(10)),

                      // 알림 항목들을 유연하게 배치
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 일정 알림 받기
                            _buildCompactSettingItem(
                              title: '일정 알림 받기',
                              value: _scheduleNotification,
                              onChanged: (value) {
                                _toggleScheduleNotification(value);
                              },
                              fontSize: getFontSize(18),
                            ),

                            SizedBox(height: getSpacing(8)),

                            // 복약 알림 받기
                            _buildCompactSettingItem(
                              title: '복약 알림 받기',
                              value: _medicationNotification,
                              onChanged: (value) {
                                _toggleMedicationNotification(value);
                              },
                              fontSize: getFontSize(18),
                            ),

                            SizedBox(height: getSpacing(8)),

                            // 루틴 알림 받기
                            _buildCompactSettingItem(
                              title: '루틴 알림 받기',
                              value: _routineNotification,
                              onChanged: (value) {
                                _toggleRoutineNotification(value);
                              },
                              fontSize: getFontSize(18),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: getSpacing(20)),

                      // 동기화 섹션
                      _buildSectionHeader('동기화', getFontSize(22)),
                      SizedBox(height: getSpacing(10)),

                      // 기기간 동기화
                      _buildCompactSettingItem(
                        title: '기기간 동기화',
                        subtitle: _isLoggedIn ? null : '로그인 후 사용 가능',
                        value: _deviceSync,
                        enabled: _isLoggedIn,
                        fontSize: getFontSize(18),
                        onChanged: _isLoggedIn
                            ? (value) async {
                                setState(() {
                                  _deviceSync = value;
                                });
                                await _saveNotificationSetting(
                                  _deviceSyncKey,
                                  value,
                                );

                                if (!value) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('로컬 모드로 전환되었습니다.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  final scheduleRepo = ScheduleRepository();
                                  await scheduleRepo.syncWithServer();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('서버와 동기화를 시작합니다.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            : null,
                      ),

                      SizedBox(height: getSpacing(20)),

                      // 루틴 추천 섹션
                      _buildSectionHeader('루틴 추천', getFontSize(22)),
                      SizedBox(height: getSpacing(6)),

                      // 설명 텍스트
                      if (!isSmallScreen) // 작은 화면에서는 설명 텍스트 숨김
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                          child: Text(
                            '반복되는 일정을 감지해 루틴으로 만들어줘요',
                            style: TextStyle(
                              color: const Color(0xFFB4B5B6),
                              fontSize: getFontSize(14),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      // 루틴 추천 기능 켜기
                      _buildCompactSettingItem(
                        title: '루틴 추천 기능 켜기',
                        value: _aiRoutineRecommendation,
                        fontSize: getFontSize(18),
                        onChanged: (value) async {
                          setState(() {
                            _aiRoutineRecommendation = value;
                          });
                          await _saveNotificationSetting(_aiRoutineKey, value);
                        },
                      ),
                    ],
                  ),
                ),

                // 하단 액션 버튼들 (항상 표시)
                SizedBox(height: getSpacing(20)),

                // 로그아웃
                _buildCompactActionItem(
                  title: '로그아웃',
                  fontSize: getFontSize(18),
                  onTap: () {
                    _showLogoutDialog();
                  },
                ),

                SizedBox(height: getSpacing(12)),

                // 회원 탈퇴
                _buildCompactActionItem(
                  title: '회원탈퇴',
                  fontSize: getFontSize(18),
                  onTap: () {
                    _showDeleteAccountDialog();
                  },
                ),

                SizedBox(height: getSpacing(10)),
              ],
            ),
          );
        },
      ),
    );
  }

  // 섹션 헤더 위젯
  Widget _buildSectionHeader(String title, [double fontSize = 22]) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        title,
        style: TextStyle(
          color: Color(0xFFD6D8D9),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // 정보 아이템 위젯 (아이디, 이메일)
  Widget _buildInfoItem(String label, String value, [double fontSize = 18]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(height: 1, color: const Color(0xFFEFEFEF)),
        ],
      ),
    );
  }

  // 설정 아이템 위젯 (스위치 포함)
  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: enabled ? Colors.black : Colors.grey,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: enabled && onChanged != null
                ? () => onChanged(!value)
                : null,
            child: Container(
              width: 65,
              height: 31,
              decoration: BoxDecoration(
                color: enabled
                    ? (value ? const Color(0xFF3A71FF) : Colors.grey[300])
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(15.5),
              ),
              child: AnimatedAlign(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 27,
                  height: 27,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: enabled ? Colors.white : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 컴팩트 설정 아이템 위젯 (반응형 크기)
  Widget _buildCompactSettingItem({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool enabled = true,
    double fontSize = 18,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: enabled ? Colors.black : Colors.grey,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: fontSize * 0.75,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: enabled && onChanged != null
                ? () => onChanged(!value)
                : null,
            child: Container(
              width: isSmallScreen ? 55 : 65,
              height: isSmallScreen ? 26 : 31,
              decoration: BoxDecoration(
                color: enabled
                    ? (value ? const Color(0xFF3A71FF) : Colors.grey[300])
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(15.5),
              ),
              child: AnimatedAlign(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: isSmallScreen ? 22 : 27,
                  height: isSmallScreen ? 22 : 27,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: enabled ? Colors.white : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 액션 아이템 위젯 (로그아웃, 회원탈퇴)
  Widget _buildActionItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 컴팩트 액션 아이템 위젯 (반응형 크기)
  Widget _buildCompactActionItem({
    required String title,
    required VoidCallback onTap,
    double fontSize = 18,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 사용자 ID 가져오기
  String _getUserId() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (authViewModel.isLoggedIn && authViewModel.currentUser != null) {
      return authViewModel.currentUser!.username;
    }
    return '비회원 전용';
  }

  // 사용자 이메일 가져오기
  String _getUserEmail() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (authViewModel.isLoggedIn && authViewModel.currentUser != null) {
      return authViewModel.currentUser!.email;
    }
    return '비회원 전용';
  }

  // 로그아웃 확인 다이얼로그
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        '로그아웃',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '로그아웃 하시겠습니까?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFB4B5B6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            final authViewModel = Provider.of<AuthViewModel>(
                              context,
                              listen: false,
                            );
                            await authViewModel.logout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF799EFF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                          ),
                          child: const Text(
                            '확인',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 회원탈퇴 확인 다이얼로그
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        '회원탈퇴',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '회원탈퇴 하시겠습니까?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFB4B5B6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // 회원탈퇴 로직 구현
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('회원탈퇴가 완료되었습니다.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4C4C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                          ),
                          child: const Text(
                            '확인',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
