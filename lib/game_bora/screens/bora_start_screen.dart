import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/core/theme/app_theme.dart';
import 'package:remote_kattedon/core/constants/app_constants.dart';
import 'package:remote_kattedon/widgets/common_widgets.dart';
import 'package:remote_kattedon/navigation/route_names.dart';

class BoraStartScreen extends StatelessWidget {
  const BoraStartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ボラ待ちやぐら'),
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
                    width: double.infinity,
                    // height: 200,
                    child: Image.asset(
                      'assets/images/bora/bora.png',
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
                  const GameDescriptionCard(
                    title: 'ボラ待ちやぐら',
                    description: 'ボラの群れを見張り、網を引き上げて捕獲しましょう！\n\n'
                        'キャラクターを選び、人徳ゲージを使って応援を呼び、\n'
                        '120秒以内にできるだけ多く捕まえよう。',
                    accentColor: AppTheme.boraColor,
                  ),
                  const SizedBox(height: AppConstants.largePadding * 1.5),

                  // STARTボタン
                  GameStartButton(
                    label: 'START',
                    onPressed: () {
                      // キャラクター選択画面に遷移
                      context.go(RouteNames.boraCharacter);
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
