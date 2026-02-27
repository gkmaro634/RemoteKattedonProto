import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/screens/home_screen.dart';
import 'package:remote_kattedon/screens/game_selection_screen.dart';
import 'package:remote_kattedon/game_deshelling_crab/screens/deshellingcrab_start_screen.dart';
import 'package:remote_kattedon/game_deshelling_crab/presentation/screens/game_screen.dart';
<<<<<<< HEAD
import 'package:remote_kattedon/fishing_in_ishikawa/screens/fishing_start_screen.dart';
import 'package:remote_kattedon/fishing_in_ishikawa/screens/fishing_game_screen.dart';
=======
import 'package:remote_kattedon/game_genge/screens/genge_start_screen.dart';
import 'package:remote_kattedon/game_genge/screens/genge_game_screen.dart';
import 'package:remote_kattedon/game2/screens/game2_start_screen.dart';
>>>>>>> origin/main
import 'route_names.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.home,
    routes: [
      // ホーム画面
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      // ゲーム選択画面
      GoRoute(
        path: RouteNames.gameSelection,
        builder: (context, state) => const GameSelectionScreen(),
      ),
      // 蟹解体ゲーム開始画面
      GoRoute(
        path: RouteNames.deshellingCrabStart,
        builder: (context, state) => const DeshellingCrabStartScreen(),
      ),
      // 蟹解体ゲーム画面
      GoRoute(
        path: RouteNames.deshellingCrabGame,
        builder: (context, state) => const GameScreen(),
      ),
<<<<<<< HEAD
      // 石川釣りゲーム開始画面
=======
      // ぷるぷるゲンゲ開始画面
      GoRoute(
        path: RouteNames.gengeStart,
        builder: (context, state) => const GengeStartScreen(),
      ),
      // ぷるぷるゲンゲ画面
      GoRoute(
        path: RouteNames.gengeGame,
        builder: (context, state) => const GengeGameScreen(),
      ),
      // ゲーム2開始画面
>>>>>>> origin/main
      GoRoute(
        path: RouteNames.fishingInIshikawaStart,
        builder: (context, state) => const FishingInIshikawaStartScreen(),
      ),
      // 石川釣りゲーム画面
      GoRoute(
        path: RouteNames.fishingInIshikawaGame,
        builder: (context, state) => const FishingInIshikawaGameScreen(),
      ),
    ],
  );
}
