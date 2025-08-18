import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'common/theme/app_theme.dart';
import 'common/router/app_router.dart';
import 'features/auth/view_models/auth_view_model.dart';
import 'features/taking/view_models/taking_view_model.dart';
import 'features/routine/view_models/routine_view_model.dart';
import 'features/home/view_models/home_view_model.dart';
import 'features/schedule/view_models/schedule_view_model.dart';
import 'features/statistics/view_models/statistics_view_model.dart';
import './utils/permission.dart'; // 권한 유틸 임포트
import './utils/alarm.dart'; // 알람 유틸 임포트

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 전체화면 설정 (엣지 투 엣지)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [], // 모든 시스템 UI 오버레이 숨김
  );

  // 시스템 바 투명화
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 알림 권한 요청
  await AppPermission.requestNotificationPermission();
  await AppPermission.requestBatteryOptimizationPermission();
  await AlarmUtility.initialize();

  runApp(const DeepDotApp());
}

class DeepDotApp extends StatelessWidget {
  const DeepDotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => TakingViewModel()),
        ChangeNotifierProvider(create: (_) => RoutineViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()..loadTasks()),
        ChangeNotifierProvider(create: (_) => ScheduleViewModel()..loadAllSchedules()),
        ChangeNotifierProvider(create: (_) => StatisticsViewModel()),
      ],
      child: MaterialApp.router(
        title: 'DeepDot',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
          Locale('en', 'US'),
        ],
        locale: const Locale('ko', 'KR'),
      ),
    );
  }
}
