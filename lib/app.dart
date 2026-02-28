import 'package:flutter/material.dart';
import 'package:gnosis_chat/core/router/app_router.dart';
import 'package:gnosis_chat/core/theme/app_theme.dart';

class GnosisApp extends StatelessWidget {
  const GnosisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gnosis Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
