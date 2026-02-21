import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/core/theme/app_theme.dart';
import 'package:remote_kattedon/core/constants/app_constants.dart';
import 'package:remote_kattedon/widgets/common_widgets.dart';
import 'package:remote_kattedon/navigation/route_names.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _launchOrderUrl() async {
    final Uri url = Uri.parse(AppConstants.katteedomOrderUrl);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URLを開けませんでした')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: isMobile ? null : PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: TopNavigationMenu(
          currentRoute: RouteNames.home,
          onHomePressed: () {},
          onGameSelectionPressed: () => context.go(RouteNames.gameSelection),
        ),
      ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: '注文',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.games),
            label: 'ゲーム',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            context.go(RouteNames.gameSelection);
          }
        },
      )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // アプリタイトル
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    AppConstants.appSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.largePadding * 1.5),

                  // 背景画像プレースホルダー
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          size: 80,
                          color: AppTheme.primaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          '[背景画像エリア]',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.largePadding * 1.5),

                  // 注文画面へのリンクボタン
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                      border: Border.all(
                        color: AppTheme.accentColor,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '海鮮丼を注文する',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.accentColor,
                          ),
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        ElevatedButton(
                          onPressed: _launchOrderUrl,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                          ),
                          child: const Text('注文サイトへ'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // または
                  Text(
                    'または',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // ゲームへのリンクボタン
                  ElevatedButton(
                    onPressed: () => context.go(RouteNames.gameSelection),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('ゲームを遊ぶ'),
                  ),
                  const SizedBox(height: AppConstants.largePadding * 2),

                  // サブテキスト
                  Text(
                    '待ち時間をゲームで有効活用しよう！',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
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
