import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_bloc/business_logic/cubit/charcters_cubit.dart';
import 'package:learn_bloc/business_logic/cubit/episode_cubit.dart';
import 'package:learn_bloc/business_logic/cubit/home_cubit.dart';
import 'package:learn_bloc/consteins/strings.dart';
import 'package:learn_bloc/data/models/model.dart';
import 'package:learn_bloc/data/repository/charcters_repositry.dart';
import 'package:learn_bloc/data/repository/episodes_repository.dart';
import 'package:learn_bloc/data/repository/show_repository.dart';
import 'package:learn_bloc/data/web_services/api.dart';
import 'package:learn_bloc/data/web_services/show_api.dart';
import 'package:learn_bloc/presentation/screens/character_screen.dart';
import 'package:learn_bloc/presentation/screens/characters_details.dart';
import 'package:learn_bloc/presentation/screens/home_screen.dart';

class AppRouter {
  AppRouter({
    CharacterApi? characterApi,
    ShowApi? showApi,
    CharactersRepository? charactersRepository,
    ShowRepository? showRepository,
    EpisodesRepository? episodesRepository,
  })  : _characterApi = characterApi ?? CharacterApi(),
        _showApi = showApi ?? ShowApi() {
    _charactersRepository = charactersRepository ?? CharactersRepository(_characterApi);
    _showRepository = showRepository ?? ShowRepository(_showApi);
    _episodesRepository = episodesRepository ?? EpisodesRepository(_showApi);
  }

  final CharacterApi _characterApi;
  final ShowApi _showApi;
  late final CharactersRepository _charactersRepository;
  late final ShowRepository _showRepository;
  late final EpisodesRepository _episodesRepository;

  Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case homeScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => HomeCubit(_showRepository)..loadHomeData(),
            child: const HomeScreen(),
          ),
        );

      case charactersScreen:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => CharctersCubit(_charactersRepository)..loadCharacters(),
            child: const CharacterScreen(),
          ),
        );

      case charactersDetails:
        final character = settings.arguments as Character;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => EpisodeCubit(_episodesRepository),
            child: CharacterDetails(character: character),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
