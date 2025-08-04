import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../common/theme/app_theme.dart';
import '../widgets/email_verify_widget.dart';
import '../widgets/forgot_password_widget.dart';
import '../widgets/show_id_widget.dart';

class ForgotAccountScreen extends StatefulWidget {
  final int initialTabIndex;
  
  const ForgotAccountScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<ForgotAccountScreen> createState() => _ForgotAccountScreenState();
}

class _ForgotAccountScreenState extends State<ForgotAccountScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isVerified = false;
  String _foundId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onVerificationSuccess(String id) {
    setState(() {
      _isVerified = true;
      _foundId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/welcome');
            }
          },
        ),
        centerTitle: true,
        title: const Text(
          '아이디 / 비밀번호 찾기',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: '아이디 찾기'),
            Tab(text: '비밀번호 찾기'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 아이디 찾기 탭
          _isVerified
              ? ShowIdWidget(foundId: _foundId)
              : EmailVerifyWidget(
                  onVerificationSuccess: _onVerificationSuccess,
                ),
          // 비밀번호 찾기 탭
          const ForgotPasswordWidget(),
        ],
      ),
    );
  }
}
