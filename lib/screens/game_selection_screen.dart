import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/core/theme/app_theme.dart';
import 'package:remote_kattedon/core/constants/app_constants.dart';
import 'package:remote_kattedon/widgets/common_widgets.dart';
import 'package:remote_kattedon/navigation/route_names.dart';

class GameSelectionScreen extends StatefulWidget {
  const GameSelectionScreen({Key? key}) : super(key: key);

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen> {
  late final Map<String, String> _gameRoutes = {
    'deshellingCrab': RouteNames.deshellingCrabStart,
    'fishingInIshikawa': RouteNames.fishingInIshikawaStart,
  };

  void _navigateToGame(String gameId) {
    final route = _gameRoutes[gameId];
    if (route != null) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: isMobile ? null : PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: TopNavigationMenu(
          currentRoute: RouteNames.gameSelection,
          onHomePressed: () => context.go(RouteNames.home),
          onGameSelectionPressed: () {},
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
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            context.go(RouteNames.home);
          }
        },
      )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Column(
                children: [
                  Text(
                    'ゲームを選ぶ',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    '待ち時間を活用して、海の知識を学ぼう！',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppConstants.largePadding * 1.5),

                  // ゲーム一覧グリッド
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : 3,
                      crossAxisSpacing: AppConstants.defaultPadding,
                      mainAxisSpacing: AppConstants.defaultPadding,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: AppConstants.availableGames.length,
                    itemBuilder: (context, index) {
                      final game = AppConstants.availableGames[index];
                      final gameColors = {
                        'deshellingCrab': AppTheme.deshellingCrabColor,
                        'fishingInIshikawa': AppTheme.fishingInIshikawaColor,
                      };

                      return GameCard(
                        title: game.title,
                        description: game.description,
                        icon: game.icon,
                        colorScheme: gameColors[game.id],
                        onTap: () => _navigateToGame(game.id),
                      );
                    },
                  ),
                  const SizedBox(height: AppConstants.largePadding * 2),

                  // 戻るボタン
                  GoBackButton(
                    onPressed: () => context.go(RouteNames.home),
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
