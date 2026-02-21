import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_kattedon/core/theme/app_theme.dart';
import 'package:remote_kattedon/navigation/app_router.dart';
import 'package:remote_kattedon/core/constants/app_constants.dart';

void main() {
  runApp(const ProviderScope(child: RemoteKatteedomApp()));
}

class RemoteKatteedomApp extends StatelessWidget {
  const RemoteKatteedomApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
