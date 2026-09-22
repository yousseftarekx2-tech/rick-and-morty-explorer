import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_bloc/business_logic/cubit/charcters_cubit.dart';
import 'package:learn_bloc/business_logic/cubit/episode_cubit.dart';
import 'package:learn_bloc/business_logic/cubit/episode_state.dart';
import 'package:learn_bloc/business_logic/cubit/home_cubit.dart';
import 'package:learn_bloc/business_logic/cubit/home_state.dart';
import 'package:learn_bloc/data/models/model.dart';
import 'package:learn_bloc/data/models/show_statistics.dart';
import 'package:learn_bloc/presentation/screens/character_screen.dart';
import 'package:learn_bloc/presentation/screens/characters_details.dart';
import 'package:learn_bloc/presentation/screens/home_screen.dart';

void main() {
  group('HomeScreen Widget', () {
    testWidgets('displays About card, Statistics, Featured Characters, and Explore button', (tester) async {
      final homeCubit = _FakeHomeCubit(
        const HomeState(
          statistics: ShowStatistics(
            totalCharacters: 826,
            totalLocations: 126,
            totalEpisodes: 51,
            totalSeasons: 5,
          ),
          featuredCharacters: [
            Character(
              id: 1,
              name: 'Rick Sanchez',
              status: 'Alive',
              species: 'Human',
              type: '',
              gender: 'Male',
              origin: CharacterPlace(name: 'Earth', url: ''),
              location: CharacterPlace(name: 'Earth', url: ''),
              image: '',
              episode: [],
              created: '',
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<HomeCubit>.value(
            value: homeCubit,
            child: const HomeScreen(),
          ),
        ),
      );

      expect(find.text('About Rick & Morty'), findsOneWidget);
      expect(find.text('Show Overview'), findsOneWidget);
      expect(find.text('826'), findsOneWidget);
      expect(find.text('Characters'), findsOneWidget);
      expect(find.text('Featured Characters'), findsOneWidget);
      expect(find.text('Explore Characters'), findsOneWidget);
    });
  });

  group('CharacterDetails Widget', () {
    testWidgets('displays selected character information, Origin, Location, and appearance count', (tester) async {
      const character = Character(
        id: 1,
        name: 'Rick Sanchez',
        status: 'Alive',
        species: 'Human',
        type: '',
        gender: 'Male',
        origin: CharacterPlace(name: 'Earth (C-137)', url: ''),
        location: CharacterPlace(name: 'Citadel of Ricks', url: ''),
        image: '',
        episode: [
          'https://rickandmortyapi.com/api/episode/1',
          'https://rickandmortyapi.com/api/episode/2',
        ],
        created: '',
      );

      final episodeCubit = _FakeEpisodeCubit(const EpisodeInitial());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<EpisodeCubit>.value(
            value: episodeCubit,
            child: const CharacterDetails(character: character),
          ),
        ),
      );

      expect(find.text('Rick Sanchez'), findsNWidgets(2));
      expect(find.text('Alive • Human'), findsOneWidget);
      expect(find.text('Origin'), findsOneWidget);
      expect(find.text('Earth (C-137)'), findsOneWidget);
      expect(find.text('Current Location'), findsOneWidget);
      expect(find.text('Citadel of Ricks'), findsOneWidget);
      expect(find.text('Appears in 2 episodes'), findsOneWidget);
    });
  });

  group('CharacterScreen Widget States', () {
    testWidgets('displays search input and filter button', (tester) async {
      final cubit = _FakeCharctersCubit(
        const CharctersSuccess([
          Character(
            id: 1,
            name: 'Rick Sanchez',
            status: 'Alive',
            species: 'Human',
            type: '',
            gender: 'Male',
            origin: CharacterPlace(name: 'Earth', url: ''),
            location: CharacterPlace(name: 'Earth', url: ''),
            image: '',
            episode: [],
            created: '',
          ),
        ]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<CharctersCubit>.value(
            value: cubit,
            child: const CharacterScreen(),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);
      expect(find.text('Rick Sanchez'), findsOneWidget);
    });

    testWidgets('displays empty state with Load More button when hasMore is true', (tester) async {
      final cubit = _FakeCharctersCubit(
        const CharctersSuccess(
          [
            Character(
              id: 1,
              name: 'Rick Sanchez',
              status: 'Alive',
              species: 'Human',
              type: '',
              gender: 'Male',
              origin: CharacterPlace(name: 'Earth', url: ''),
              location: CharacterPlace(name: 'Earth', url: ''),
              image: '',
              episode: [],
              created: '',
            ),
          ],
          displayedCharacters: [],
          hasMore: true,
          searchQuery: 'NonExistent',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<CharctersCubit>.value(
            value: cubit,
            child: const CharacterScreen(),
          ),
        ),
      );

      expect(find.text('No matches in loaded characters'), findsOneWidget);
      expect(find.text('Load More Pages'), findsOneWidget);
      expect(find.text('Clear Filters & Search'), findsOneWidget);
    });
  });
}

class _FakeHomeCubit extends Cubit<HomeState> implements HomeCubit {
  _FakeHomeCubit(super.initialState);

  @override
  Future<void> loadHomeData() async {}

  @override
  Future<void> loadStatistics() async {}

  @override
  Future<void> loadFeaturedCharacters() async {}

  @override
  Character? getRandomCharacter() => state.featuredCharacters.isNotEmpty ? state.featuredCharacters.first : null;
}

class _FakeCharctersCubit extends Cubit<CharctersState> implements CharctersCubit {
  _FakeCharctersCubit(super.initialState);

  @override
  Future<void> loadCharacters() async {}

  @override
  Future<void> loadNextPage() async {}

  @override
  void updateSearchQuery(String query) {}

  @override
  void clearSearch() {}

  @override
  void updateFilter(CharacterFilter filter) {}

  @override
  void clearFilters() {}

  @override
  Character? getRandomLoadedCharacter() => null;
}

class _FakeEpisodeCubit extends Cubit<EpisodeState> implements EpisodeCubit {
  _FakeEpisodeCubit(super.initialState);

  @override
  Future<void> loadEpisodes(Character character) async {}
}
