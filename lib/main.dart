import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'common/theme/app_theme.dart';
import 'common/router/app_router.dart';
import 'features/auth/view_models/auth_view_model.dart';

void main() {
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
