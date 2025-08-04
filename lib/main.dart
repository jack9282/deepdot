import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'common/theme/app_theme.dart';
import 'common/router/app_router.dart';
import 'features/auth/view_models/auth_view_model.dart';

void main() {
  // Edge-to-Edge 활성화
  WidgetsFlutterBinding.ensureInitialized();
  
  // 갤럭시 S10 등 최신 기종을 위한 강력한 전체 화면 설정
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [], // 모든 시스템 UI 오버레이 숨김
  );
  
  // 시스템 바 완전 투명화 (갤럭시 S10 전용)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent, // 구분선도 투명
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const DeepDotApp());
}

class DeepDotApp extends StatelessWidget {
  const DeepDotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel()..checkAuthStatus(),
        ),
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
