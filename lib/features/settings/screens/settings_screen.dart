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
  }
  
  /// SharedPreferences에서 설정값을 불러옵니다
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _scheduleNotification = prefs.getBool(_scheduleNotificationKey) ?? true;
      _medicationNotification = prefs.getBool(_medicationNotificationKey) ?? true;
      _routineNotification = prefs.getBool(_routineNotificationKey) ?? true;
      _deviceSync = prefs.getBool(_deviceSyncKey) ?? true;
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
      
      // 30000-39999 범위의 루틴 알림만 취소
      for (final alarm in pendingAlarms) {
        if (alarm.id >= 30000 && alarm.id < 40000) {
          await AlarmUtility.cancelAlarm(alarm.id);
        }
      }
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 계정 정보 섹션
            _buildSectionHeader('계정 정보'),
            const SizedBox(height: 24),

            // 아이디
            _buildInfoItem('아이디', _getUserId()),
            const SizedBox(height: 12),

            // 이메일
            _buildInfoItem('이메일', _getUserEmail()),

            const SizedBox(height: 32),

            // 알림 섹션
            _buildSectionHeader('알림'),
            const SizedBox(height: 16),

            // 일정 알림 받기
            _buildSettingItem(
              title: '일정 알림 받기',
              value: _scheduleNotification,
              onChanged: _toggleScheduleNotification,
            ),

            const SizedBox(height: 16),

            // 복약 알림 받기
            _buildSettingItem(
              title: '복약 알림 받기',
              value: _medicationNotification,
              onChanged: _toggleMedicationNotification,
            ),

            const SizedBox(height: 16),

            // 루틴 알림 받기
            _buildSettingItem(
              title: '루틴 알림 받기',
              value: _routineNotification,
              onChanged: _toggleRoutineNotification,
            ),

            const SizedBox(height: 32),

            // 동기화 섹션
            _buildSectionHeader('동기화'),
            const SizedBox(height: 16),

            // 기기간 동기화
            _buildSettingItem(
              title: '기기간 동기화',
              value: _deviceSync,
              onChanged: (value) async {
                setState(() {
                  _deviceSync = value;
                });
                await _saveNotificationSetting(_deviceSyncKey, value);
              },
            ),

            const SizedBox(height: 40),

            // 루틴 추천 섹션
            _buildSectionHeader('루틴 추천'),
            const SizedBox(height: 8),

            // 설명 텍스트
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 16),
              child: Text(
                '반복되는 일정을 감지해 루틴으로 만들어줘요',
                style: TextStyle(
                  color: const Color(0xFFB4B5B6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // 루틴 추천 기능 켜기
            _buildSettingItem(
              title: '루틴 추천 기능 켜기',
              value: _aiRoutineRecommendation,
              onChanged: (value) async {
                setState(() {
                  _aiRoutineRecommendation = value;
                });
                await _saveNotificationSetting(_aiRoutineKey, value);
              },
            ),

            const SizedBox(height: 80),

            // 로그아웃
            _buildActionItem(
              title: '로그아웃',
              onTap: () {
                _showLogoutDialog();
              },
            ),

            const SizedBox(height: 24),

            // 회원 탈퇴
            _buildActionItem(
              title: '회원탈퇴',
              onTap: () {
                _showDeleteAccountDialog();
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 섹션 헤더 위젯
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFD6D8D9),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // 정보 아이템 위젯 (아이디, 이메일)
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: const Color(0xFFEFEFEF)),
        ],
      ),
    );
  }

  // 설정 아이템 위젯 (스위치 포함)
  Widget _buildSettingItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 65,
              height: 31,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF3A71FF) : Colors.grey[300],
                borderRadius: BorderRadius.circular(15.5),
              ),
              child: AnimatedAlign(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 27,
                  height: 27,
                  margin: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
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
