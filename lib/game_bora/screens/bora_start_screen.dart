import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/core/theme/app_theme.dart';
import 'package:remote_kattedon/core/constants/app_constants.dart';
import 'package:remote_kattedon/widgets/common_widgets.dart';
import 'package:remote_kattedon/navigation/route_names.dart';

class GengeStartScreen extends StatelessWidget {
  const GengeStartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ぷるぷるゲンゲ'),
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
                  // ゲームアイコン（アセット化されたアイコンを表示、なければ絵文字でフォールバック）
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Image.asset(
                      'assets/images/genge/genge_icon.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            '🐟️',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 80,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // ゲームタイトル
                  GameDescriptionCard(
                    title: 'ぷるぷるゲンゲ',
                    description: '15秒間で新鮮なゲンゲを連打してスコアを稼ごう！\n\n'
                        'クリックでゲンゲを刺激して、\n'
                        'スコアを競い合いましょう。',
                    accentColor: AppTheme.gengeColor,
                  ),
                  const SizedBox(height: AppConstants.largePadding * 1.5),

                  // STARTボタン
                  GameStartButton(
                    label: 'START',
                    onPressed: () {
                      // ゲーム画面に遷移
                      context.go(RouteNames.gengeGame);
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
