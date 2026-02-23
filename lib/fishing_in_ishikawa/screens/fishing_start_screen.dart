import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/core/theme/app_theme.dart';
import 'package:remote_kattedon/core/constants/app_constants.dart';
import 'package:remote_kattedon/widgets/common_widgets.dart';
import 'package:remote_kattedon/navigation/route_names.dart';

class FishingInIshikawaStartScreen extends StatelessWidget {
  const FishingInIshikawaStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('石川釣りゲーム'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ゲームアイコン
                  Text(
                    '🎣',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 80,
                    ),
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // ゲームタイトル
                  GameDescriptionCard(
                    title: '石川釣りゲーム',
                    description: '石川県の色んな漁場を巡りながら、釣りを楽しむゲームです。\n\n',
                    accentColor: AppTheme.fishingInIshikawaColor,
                  ),
                  const SizedBox(height: AppConstants.largePadding * 1.5),

                  // STARTボタン
                  GameStartButton(
                    label: 'START',
                    onPressed: () {
                      context.go(RouteNames.fishingInIshikawaGame);
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // 戻るボタン
                  GoBackButton(
                    onPressed: () => context.go(RouteNames.gameSelection),
                    label: 'ゲーム一覧に戻る',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
