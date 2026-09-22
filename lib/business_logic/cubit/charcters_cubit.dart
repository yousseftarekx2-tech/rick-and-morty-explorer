import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_bloc/data/models/model.dart';
import 'package:learn_bloc/data/repository/charcters_repositry.dart';

part 'charcters_state.dart';

class CharctersCubit extends Cubit<CharctersState> {
  CharctersCubit(this._repository) : super(const CharctersInitial());

  final CharactersRepository _repository;
  final Random _random = Random();
  String? _nextUrl;
  bool _isFetchingNextPage = false;

  /// Loads the first page of characters and resets pagination.
  Future<void> loadCharacters() async {
    _nextUrl = null;
    _isFetchingNextPage = false;
    emit(const CharctersLoading());

    try {
      final page = await _repository.getCharactersPage(page: 1);
      _nextUrl = page.nextUrl;

      if (page.characters.isEmpty) {
        emit(const CharctersEmpty());
      } else {
        emit(
          CharctersSuccess(
            page.characters,
            displayedCharacters: page.characters,
            hasMore: page.nextUrl != null,
          ),
        );
      }
    } catch (error, stackTrace) {
      _logError('Initial character loading failed', error, stackTrace);
      emit(CharctersFailure(_mapErrorMessage(error)));
    }
  }

  /// Loads the next page of characters incrementally and re-applies active search/filters.
  Future<void> loadNextPage() async {
    final currentState = state;
    if (currentState is! CharctersSuccess) return;
    if (!currentState.hasMore || currentState.isLoadingMore || _isFetchingNextPage || _nextUrl == null) {
      return;
    }

    _isFetchingNextPage = true;
    emit(
      currentState.copyWith(
        isLoadingMore: true,
        clearPaginationError: true,
      ),
    );

    try {
      final page = await _repository.getCharactersPage(nextUrl: _nextUrl);
      _nextUrl = page.nextUrl;

      final updatedAll = List<Character>.unmodifiable([
        ...currentState.allCharacters,
        ...page.characters,
      ]);

      final updatedDisplayed = _filterAndRank(
        characters: updatedAll,
        query: currentState.searchQuery,
        filter: currentState.filter,
      );

      emit(
        currentState.copyWith(
          allCharacters: updatedAll,
          displayedCharacters: updatedDisplayed,
          hasMore: page.nextUrl != null,
          isLoadingMore: false,
        ),
      );
    } catch (error, stackTrace) {
      _logError('Pagination loading failed', error, stackTrace);
      emit(
        currentState.copyWith(
          isLoadingMore: false,
          paginationError: 'Failed to load more characters. Tap to retry.',
        ),
      );
    } finally {
      _isFetchingNextPage = false;
    }
  }

  /// Updates search query with ranking: starts-with names rank ahead of contains names.
  void updateSearchQuery(String query) {
    final currentState = state;
    if (currentState is! CharctersSuccess) return;

    final trimmed = query.trim();
    final updatedDisplayed = _filterAndRank(
      characters: currentState.allCharacters,
      query: trimmed,
      filter: currentState.filter,
    );

    emit(
      currentState.copyWith(
        searchQuery: query,
        displayedCharacters: updatedDisplayed,
      ),
    );
  }

  /// Clears active search query.
  void clearSearch() {
    updateSearchQuery('');
  }

  /// Updates filter criteria (status, species, location).
  void updateFilter(CharacterFilter filter) {
    final currentState = state;
    if (currentState is! CharctersSuccess) return;

    final updatedDisplayed = _filterAndRank(
      characters: currentState.allCharacters,
      query: currentState.searchQuery,
      filter: filter,
    );

    emit(
      currentState.copyWith(
        filter: filter,
        displayedCharacters: updatedDisplayed,
      ),
    );
  }

  /// Clears all active filters.
  void clearFilters() {
    updateFilter(const CharacterFilter());
  }

  /// Picks a random character from loaded characters.
  Character? getRandomLoadedCharacter() {
    final currentState = state;
    if (currentState is! CharctersSuccess || currentState.allCharacters.isEmpty) {
      return null;
    }
    final index = _random.nextInt(currentState.allCharacters.length);
    return currentState.allCharacters[index];
  }

  /// Pure filtering and ranking algorithm.
  List<Character> _filterAndRank({
    required List<Character> characters,
    required String query,
    required CharacterFilter filter,
  }) {
    final cleanQuery = query.trim().toLowerCase();

    // 1. Filter characters by criteria
    final matches = characters.where((character) {
      // Status filter
      if (filter.status != null && filter.status != 'All') {
        if (character.status.toLowerCase() != filter.status!.toLowerCase()) {
          return false;
        }
      }

      // Species filter
      if (filter.species != null && filter.species != 'All') {
        final speciesLower = character.species.toLowerCase();
        if (filter.species == 'Other') {
          if (speciesLower == 'human' || speciesLower == 'alien') {
            return false;
          }
        } else if (speciesLower != filter.species!.toLowerCase()) {
          return false;
        }
      }

      // Location filter
      if (filter.location != null && filter.location!.isNotEmpty && filter.location != 'All') {
        if (character.location.name.toLowerCase() != filter.location!.toLowerCase()) {
          return false;
        }
      }

      // Name query filter
      if (cleanQuery.isNotEmpty) {
        if (!character.name.toLowerCase().contains(cleanQuery)) {
          return false;
        }
      }

      return true;
    }).toList();

    // 2. If no search query, preserve current order
    if (cleanQuery.isEmpty) {
      return matches;
    }

    // 3. Search ranking: names that START with query first, then names that CONTAIN query
    final startsWithMatches = <Character>[];
    final containsMatches = <Character>[];

    for (final char in matches) {
      if (char.name.toLowerCase().startsWith(cleanQuery)) {
        startsWithMatches.add(char);
      } else {
        containsMatches.add(char);
      }
    }

    return [...startsWithMatches, ...containsMatches];
  }

  String _mapErrorMessage(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Check your internet connection and try again.';
        case DioExceptionType.connectionError:
          return 'Unable to connect to the server. Check your connection and try again.';
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode;
          return code == 429
              ? 'Too many requests. Please wait a moment and try again.'
              : 'Server returned error ($code). Please try again later.';
        default:
          return 'Network request failed. Please check your connection and try again.';
      }
    }
    if (error is FormatException) {
      return 'Received invalid character data format from server.';
    }
    return 'Unable to load characters. Check your connection and try again.';
  }

  void _logError(String label, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('$label: $error');
      debugPrint(stackTrace.toString());
    }
  }
}
