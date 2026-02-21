import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/core/theme/app_theme.dart';
import 'package:remote_kattedon/core/constants/app_constants.dart';
import 'package:remote_kattedon/widgets/common_widgets.dart';
import 'package:remote_kattedon/navigation/route_names.dart';

class KatteedomStartScreen extends StatelessWidget {
  const KatteedomStartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('勝手丼マスター'),
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
                    '🍣',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 80,
                    ),
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // ゲームタイトル
                  GameDescriptionCard(
                    title: '勝手丼マスター',
                    description: '近江町市場の新鮮な魚介類を使って、あなた好みの海鮮丼を作ろう！\n\n'
                        'ゲームを通じて、各魚介類の特徴や漁業の知識を自然に学べます。\n\n'
                        '様々な組み合わせを試して、最高の勝手丼を完成させてください！',
                    accentColor: AppTheme.katteedomColor,
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
