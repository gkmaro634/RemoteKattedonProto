import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_kattedon/screens/home_screen.dart';
import 'package:remote_kattedon/screens/game_selection_screen.dart';
import 'package:remote_kattedon/kattedon/screens/kattedon_start_screen.dart';
import 'package:remote_kattedon/game1/screens/game1_start_screen.dart';
import 'package:remote_kattedon/game2/screens/game2_start_screen.dart';
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
      // 勝手丼ゲーム開始画面
      GoRoute(
        path: RouteNames.katteedomStart,
        builder: (context, state) => const KatteedomStartScreen(),
      ),
      // ゲーム1開始画面
      GoRoute(
        path: RouteNames.game1Start,
        builder: (context, state) => const Game1StartScreen(),
      ),
      // ゲーム2開始画面
      GoRoute(
        path: RouteNames.game2Start,
        builder: (context, state) => const Game2StartScreen(),
      ),
    ],
  );
}
