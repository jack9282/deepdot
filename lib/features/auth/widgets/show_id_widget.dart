import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../common/theme/app_theme.dart';

class ShowIdWidget extends StatefulWidget {
  final String foundId;

  const ShowIdWidget({super.key, required this.foundId});

  @override
  State<ShowIdWidget> createState() => _ShowIdWidgetState();
}

class _ShowIdWidgetState extends State<ShowIdWidget> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 100),
            Center(
              child: Text(
                "이메일의 정보와 일치하는 아이디입니다",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            const SizedBox(height: 100),
            Center(
              child: Center(
                child: Text(
                  widget.foundId,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '아니오',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/forgot-password?tab=1');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: AppTheme.primaryColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '비밀번호 찾기',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
