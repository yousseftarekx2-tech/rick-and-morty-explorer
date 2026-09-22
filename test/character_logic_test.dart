import 'package:flutter_test/flutter_test.dart';
import 'package:learn_bloc/business_logic/cubit/charcters_cubit.dart';
import 'package:learn_bloc/business_logic/cubit/episode_cubit.dart';
import 'package:learn_bloc/business_logic/cubit/episode_state.dart';
import 'package:learn_bloc/business_logic/cubit/home_cubit.dart';
import 'package:learn_bloc/data/models/episode_model.dart';
import 'package:learn_bloc/data/models/model.dart';
import 'package:learn_bloc/data/repository/charcters_repositry.dart';
import 'package:learn_bloc/data/repository/episodes_repository.dart';
import 'package:learn_bloc/data/repository/show_repository.dart';
import 'package:learn_bloc/data/web_services/api.dart';
import 'package:learn_bloc/data/web_services/show_api.dart';

void main() {
  group('Character Model Parsing', () {
    test('Character.fromJson parses complete API payload', () {
      final json = <String, dynamic>{
        'id': 1,
        'name': 'Rick Sanchez',
        'status': 'Alive',
        'species': 'Human',
        'type': '',
        'gender': 'Male',
        'origin': {'name': 'Earth (C-137)', 'url': 'https://rickandmortyapi.com/api/location/1'},
        'location': {'name': 'Citadel of Ricks', 'url': 'https://rickandmortyapi.com/api/location/3'},
        'image': 'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
        'episode': [
          'https://rickandmortyapi.com/api/episode/1',
          'https://rickandmortyapi.com/api/episode/2',
        ],
        'created': '2017-11-04T18:48:46.250Z',
      };

      final character = Character.fromJson(json);

      expect(character.id, 1);
      expect(character.name, 'Rick Sanchez');
      expect(character.status, 'Alive');
      expect(character.origin.name, 'Earth (C-137)');
      expect(character.location.name, 'Citadel of Ricks');
      expect(character.episode.length, 2);
    });

    test('Character.fromJson handles null, untyped, and missing fields safely', () {
      final character = Character.fromJson({
        'id': '42',
        'name': null,
        'origin': <dynamic, dynamic>{},
        'location': null,
        'episode': null,
      });

      expect(character.id, 42);
      expect(character.name, 'Unknown');
      expect(character.status, 'Unknown');
      expect(character.origin.name, 'Unknown');
      expect(character.location.name, 'Unknown');
      expect(character.episode, isEmpty);
    });
  });

  group('Episode Model Parsing', () {
    test('Episode.fromJson parses fields and extracts season/episode numbers', () {
      final episode = Episode.fromJson({
        'id': 28,
        'name': 'The Ricklantis Mixup',
        'air_date': 'September 10, 2017',
        'episode': 'S03E07',
      });

      expect(episode.id, 28);
      expect(episode.name, 'The Ricklantis Mixup');
      expect(episode.episodeCode, 'S03E07');
      expect(episode.seasonNumber, 3);
      expect(episode.episodeNumber, 7);
    });
  });

  group('Search & Ranking Logic', () {
    final characters = [
      const Character(
        id: 1,
        name: 'Toxic Rick',
        status: 'Dead',
        species: 'Alien',
        type: '',
        gender: 'Male',
        origin: CharacterPlace(name: 'Earth', url: ''),
        location: CharacterPlace(name: 'Citadel of Ricks', url: ''),
        image: '',
        episode: [],
        created: '',
      ),
      const Character(
        id: 2,
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
      const Character(
        id: 3,
        name: 'Morty Smith',
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
    ];

    test('search ranks starts-with before contains', () async {
      final cubit = CharctersCubit(CharactersRepository(_SimpleListApi(characters)));
      await cubit.loadCharacters();

      cubit.updateSearchQuery('rick');
      final state = cubit.state as CharctersSuccess;

      expect(state.displayedCharacters.length, 2);
      expect(state.displayedCharacters[0].name, 'Rick Sanchez'); // starts with "rick"
      expect(state.displayedCharacters[1].name, 'Toxic Rick'); // contains "rick"
      await cubit.close();
    });

    test('filters by status, species, and location correctly', () async {
      final cubit = CharctersCubit(CharactersRepository(_SimpleListApi(characters)));
      await cubit.loadCharacters();

      cubit.updateFilter(const CharacterFilter(
        status: 'Alive',
        species: 'Human',
        location: 'Earth',
      ));

      final state = cubit.state as CharctersSuccess;
      expect(state.displayedCharacters.length, 2);
      expect(state.displayedCharacters.map((c) => c.name), containsAll(['Rick Sanchez', 'Morty Smith']));

      // Filter for Alien
      cubit.updateFilter(const CharacterFilter(species: 'Alien'));
      final stateAlien = cubit.state as CharctersSuccess;
      expect(stateAlien.displayedCharacters.length, 1);
      expect(stateAlien.displayedCharacters.first.name, 'Toxic Rick');

      await cubit.close();
    });

    test('clearing filters restores all loaded characters', () async {
      final cubit = CharctersCubit(CharactersRepository(_SimpleListApi(characters)));
      await cubit.loadCharacters();

      cubit.updateFilter(const CharacterFilter(status: 'Dead'));
      expect((cubit.state as CharctersSuccess).displayedCharacters.length, 1);

      cubit.clearFilters();
      expect((cubit.state as CharctersSuccess).displayedCharacters.length, 3);
      await cubit.close();
    });
  });

  group('CharctersCubit Pagination & Filters', () {
    test('loadNextPage appends characters and re-applies active filter', () async {
      final cubit = CharctersCubit(CharactersRepository(_MockPaginatedApi()));
      await cubit.loadCharacters();

      // Set filter for Human
      cubit.updateFilter(const CharacterFilter(species: 'Human'));
      expect((cubit.state as CharctersSuccess).displayedCharacters.length, 1);

      // Load next page
      await cubit.loadNextPage();
      final state = cubit.state as CharctersSuccess;

      // Master catalog has 2 items, both are Human, so displayed has 2
      expect(state.allCharacters.length, 2);
      expect(state.displayedCharacters.length, 2);
      expect(state.filter.species, 'Human'); // Filter was preserved
      await cubit.close();
    });

    test('loadNextPage prevents concurrent duplicate requests', () async {
      final cubit = CharctersCubit(CharactersRepository(_SlowPaginatedApi()));
      await cubit.loadCharacters();

      final f1 = cubit.loadNextPage();
      final f2 = cubit.loadNextPage();

      await Future.wait([f1, f2]);

      final state = cubit.state as CharctersSuccess;
      expect(state.allCharacters.length, 2);
      await cubit.close();
    });
  });

  group('HomeCubit & Repositories', () {
    test('loads statistics and featured characters independently', () async {
      final homeCubit = HomeCubit(ShowRepository(_MockShowApi()));
      await homeCubit.loadHomeData();

      final state = homeCubit.state;
      expect(state.statistics?.totalCharacters, 826);
      expect(state.statistics?.totalLocations, 126);
      expect(state.statistics?.totalEpisodes, 51);
      expect(state.statistics?.totalSeasons, 5);
      expect(state.featuredCharacters.length, 2);

      final randomChar = homeCubit.getRandomCharacter();
      expect(randomChar, isNotNull);
      await homeCubit.close();
    });
  });

  group('EpisodeCubit', () {
    test('loads episodes on demand for a character', () async {
      final episodeCubit = EpisodeCubit(EpisodesRepository(_MockShowApi()));
      const char = Character(
        id: 1,
        name: 'Rick Sanchez',
        status: 'Alive',
        species: 'Human',
        type: '',
        gender: 'Male',
        origin: CharacterPlace(name: 'Earth', url: ''),
        location: CharacterPlace(name: 'Earth', url: ''),
        image: '',
        episode: ['https://rickandmortyapi.com/api/episode/1'],
        created: '',
      );

      final expectation = expectLater(
        episodeCubit.stream,
        emitsInOrder([
          isA<EpisodeLoading>(),
          predicate<EpisodeSuccess>((s) => s.episodes.length == 1 && s.episodes.first.name == 'Pilot'),
        ]),
      );

      await episodeCubit.loadEpisodes(char);
      await expectation;
      await episodeCubit.close();
    });
  });
}

class _SimpleListApi extends CharacterApi {
  _SimpleListApi(this._characters);
  final List<Character> _characters;

  @override
  Future<Map<String, dynamic>> getCharactersPage({int page = 1, String? url}) async {
    return {
      'info': {'count': _characters.length, 'pages': 1, 'next': null, 'prev': null},
      'results': _characters.map((c) => {
        'id': c.id,
        'name': c.name,
        'status': c.status,
        'species': c.species,
        'type': c.type,
        'gender': c.gender,
        'origin': {'name': c.origin.name, 'url': c.origin.url},
        'location': {'name': c.location.name, 'url': c.location.url},
        'image': c.image,
        'episode': c.episode,
        'created': c.created,
      }).toList(),
    };
  }
}

class _MockPaginatedApi extends CharacterApi {
  @override
  Future<Map<String, dynamic>> getCharactersPage({int page = 1, String? url}) async {
    if (url != null && url.contains('page=2')) {
      return {
        'info': {'count': 826, 'pages': 42, 'next': null, 'prev': 'page=1'},
        'results': [
          {
            'id': 2,
            'name': 'Morty Smith',
            'status': 'Alive',
            'species': 'Human',
            'type': '',
            'gender': 'Male',
            'origin': {'name': 'Earth', 'url': ''},
            'location': {'name': 'Earth', 'url': ''},
            'image': '',
            'episode': [],
            'created': '',
          }
        ],
      };
    }

    return {
      'info': {'count': 826, 'pages': 42, 'next': 'https://rickandmortyapi.com/api/character?page=2'},
      'results': [
        {
          'id': 1,
          'name': 'Rick Sanchez',
          'status': 'Alive',
          'species': 'Human',
          'type': '',
          'gender': 'Male',
          'origin': {'name': 'Earth', 'url': ''},
          'location': {'name': 'Earth', 'url': ''},
          'image': '',
          'episode': [],
          'created': '',
        }
      ],
    };
  }
}

class _SlowPaginatedApi extends CharacterApi {
  @override
  Future<Map<String, dynamic>> getCharactersPage({int page = 1, String? url}) async {
    if (url != null) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return {
        'info': {'count': 826, 'pages': 42, 'next': null},
        'results': [
          {
            'id': 2,
            'name': 'Morty Smith',
            'status': 'Alive',
            'species': 'Human',
            'type': '',
            'gender': 'Male',
            'origin': {},
            'location': {},
            'image': '',
            'episode': [],
            'created': '',
          }
        ],
      };
    }
    return {
      'info': {'count': 826, 'pages': 42, 'next': 'https://rickandmortyapi.com/api/character?page=2'},
      'results': [
        {
          'id': 1,
          'name': 'Rick Sanchez',
          'status': 'Alive',
          'species': 'Human',
          'type': '',
          'gender': 'Male',
          'origin': {},
          'location': {},
          'image': '',
          'episode': [],
          'created': '',
        }
      ],
    };
  }
}

class _MockShowApi extends ShowApi {
  @override
  Future<Map<String, int>> getMetadataCounts() async {
    return {
      'characters': 826,
      'locations': 126,
      'episodes': 51,
      'seasons': 5,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getFeaturedCharacters({List<int> ids = const [1, 2, 3, 4, 5]}) async {
    return [
      {
        'id': 1,
        'name': 'Rick Sanchez',
        'status': 'Alive',
        'species': 'Human',
        'type': '',
        'gender': 'Male',
        'origin': {'name': 'Earth', 'url': ''},
        'location': {'name': 'Earth', 'url': ''},
        'image': '',
        'episode': ['https://rickandmortyapi.com/api/episode/1'],
        'created': '',
      },
      {
        'id': 2,
        'name': 'Morty Smith',
        'status': 'Alive',
        'species': 'Human',
        'type': '',
        'gender': 'Male',
        'origin': {'name': 'Earth', 'url': ''},
        'location': {'name': 'Earth', 'url': ''},
        'image': '',
        'episode': ['https://rickandmortyapi.com/api/episode/1'],
        'created': '',
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getEpisodesByIds(List<int> ids) async {
    return [
      {
        'id': 1,
        'name': 'Pilot',
        'air_date': 'December 2, 2013',
        'episode': 'S01E01',
      }
    ];
  }
}
