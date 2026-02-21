import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/core/theme/app_theme.dart';
import 'package:remote_kattedon/core/constants/app_constants.dart';
import 'package:remote_kattedon/widgets/common_widgets.dart';
import 'package:remote_kattedon/navigation/route_names.dart';

class Game1StartScreen extends StatelessWidget {
  const Game1StartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ゲーム1'),
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
                    '🎮',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 80,
                    ),
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // ゲームタイトル
                  GameDescriptionCard(
                    title: 'ゲーム1',
                    description: 'このゲームのプレースホルダー説明です。\n\n'
                        '実装時に適切なゲーム説明に置き換えてください。\n\n'
                        '複数のゲームを並行開発できるように設計されています。',
                    accentColor: AppTheme.game1Color,
                  ),
                  const SizedBox(height: AppConstants.largePadding * 1.5),

                  // STARTボタン
                  GameStartButton(
                    label: 'START',
                    onPressed: () {
                      // TODO: 実装時にゲーム画面に遷移
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ゲーム画面に遷移します')),
                      );
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
