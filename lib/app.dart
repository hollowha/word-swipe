import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';
import 'screens/swipe_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/mode_hub_screen.dart';
import 'screens/placement_screen.dart';
import 'screens/study_mode_screen.dart';
import 'screens/word_library_screen.dart';
import 'models/study_mode.dart';

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SwipeScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/modes', builder: (_, __) => const ModeHubScreen()),
    GoRoute(path: '/library', builder: (_, __) => const WordLibraryScreen()),
    GoRoute(path: '/placement', builder: (_, __) => const PlacementScreen()),
    GoRoute(
      path: '/study/:mode',
      builder: (_, state) => StudyModeScreen(
        mode: StudyModeInfo.fromRouteName(
          state.pathParameters['mode'] ?? StudyMode.flashcards.routeName,
        ),
      ),
    ),
  ],
);

class WordSwipeApp extends StatelessWidget {
  const WordSwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WordSwipe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
