import 'package:flutter/material.dart';
import 'package:learn_bloc/app_routing.dart';
import 'package:learn_bloc/consteins/strings.dart';

void main() {
  runApp(RickAndMortyApp(appRouter: AppRouter()));
}

class RickAndMortyApp extends StatelessWidget {
  final AppRouter appRouter;

  const RickAndMortyApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF42B883);

    return MaterialApp(
      title: 'Rick & Morty',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system,
      initialRoute: homeScreen,
      onGenerateRoute: appRouter.generateRoute,
    );
  }
}
