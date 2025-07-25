import 'package:flutter/material.dart';
import '../../../common/theme/app_theme.dart';

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
  bool _aiRoutineRecommendation = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            height: 1.10,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사용자 정보
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 30),
              child: Text(
                '아이디(123@naver.com)',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  height: 1.10,
                ),
              ),
            ),
            
            // 알림 섹션
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 16),
              child: Text(
                '알림',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.10,
                ),
              ),
            ),
            
            // 일정 알림 받기
            _buildSettingItem(
              title: '일정 알림 받기',
              value: _scheduleNotification,
              onChanged: (value) {
                setState(() {
                  _scheduleNotification = value;
                });
              },
            ),
            
            const SizedBox(height: 28),
            
            // 복약 알림 받기
            _buildSettingItem(
              title: '복약 알림 받기',
              value: _medicationNotification,
              onChanged: (value) {
                setState(() {
                  _medicationNotification = value;
                });
              },
            ),
            
            const SizedBox(height: 28),
            
            // 루틴 알림 받기
            _buildSettingItem(
              title: '루틴 알림 받기',
              value: _routineNotification,
              onChanged: (value) {
                setState(() {
                  _routineNotification = value;
                });
              },
            ),
            
            const SizedBox(height: 45),
            
            // 동기화 섹션
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 16),
              child: Text(
                '동기화',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.10,
                ),
              ),
            ),
            
            // 기기간 동기화
            _buildSettingItem(
              title: '기기간 동기화',
              value: _deviceSync,
              onChanged: (value) {
                setState(() {
                  _deviceSync = value;
                });
              },
            ),
            
            const SizedBox(height: 45),
            
            // AI 루틴 추천 섹션
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 4),
              child: Text(
                'AI 루틴 추천',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.10,
                ),
              ),
            ),
            
            // AI 설명 텍스트
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 16),
              child: Text(
                'AI가 반복되는 일정을 감지해 루틴으로 만들어줘요',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  height: 2.20,
                ),
              ),
            ),
            
            // AI 루틴 추천 기능 켜기
            _buildSettingItem(
              title: 'AI 루틴 추천 기능 켜기',
              value: _aiRoutineRecommendation,
              onChanged: (value) {
                setState(() {
                  _aiRoutineRecommendation = value;
                });
              },
            ),
            
            const SizedBox(height: 30),
            
            // 로그아웃
            _buildActionItem(
              title: '로그아웃',
              onTap: () {
                _showLogoutDialog();
              },
            ),
            
            const SizedBox(height: 26),
            
            // 회원 탈퇴
            _buildActionItem(
              title: '회원 탈퇴',
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

  // 설정 아이템 위젯 (스위치 포함)
  Widget _buildSettingItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w400,
              height: 1.10,
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppTheme.primaryColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 1.10,
          ),
        ),
      ),
    );
  }

  // 로그아웃 확인 다이얼로그
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 로그아웃 로직 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('로그아웃되었습니다.'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );
  }

  // 회원탈퇴 확인 다이얼로그
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('회원 탈퇴'),
          content: const Text('정말 회원탈퇴하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('탈퇴'),
            ),
          ],
        );
      },
    );
  }
} 