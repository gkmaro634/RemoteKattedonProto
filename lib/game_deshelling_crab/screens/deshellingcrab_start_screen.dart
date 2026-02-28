import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/core/theme/app_theme.dart';
import 'package:remote_kattedon/core/constants/app_constants.dart';
import 'package:remote_kattedon/widgets/common_widgets.dart';
import 'package:remote_kattedon/navigation/route_names.dart';

class DeshellingCrabStartScreen extends StatelessWidget {
  const DeshellingCrabStartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('蟹解体チャレンジ'),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/deshelling_crab/top.png',
                      // height: 200,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text(
                        '🦀',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 80,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // ゲームタイトル
                  const GameDescriptionCard(
                    title: '蟹解体チャレンジ',
                    description: '蟹を正しい手順で上手に解体しよう！\n\n'
                        '新鮮な蟹を最高のおいしさで食べるために、\n'
                        'JFいしかわの漁師直伝の解体テクニックを学びます。',
                    accentColor: AppTheme.deshellingCrabColor,
                  ),
                  const SizedBox(height: AppConstants.largePadding * 1.5),

                  // STARTボタン
                  GameStartButton(
                    label: 'START',
                    onPressed: () {
                      // ゲーム画面に遷移
                      context.go(RouteNames.deshellingCrabGame);
                    },
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // 戻るボタン
                  GoBackButton(
                    onPressed: () => context.go(RouteNames.gameSelection),
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
