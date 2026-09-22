import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_bloc/business_logic/cubit/home_state.dart';
import 'package:learn_bloc/data/models/model.dart';
import 'package:learn_bloc/data/repository/show_repository.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._showRepository) : super(const HomeState());

  final ShowRepository _showRepository;
  final Random _random = Random();

  /// Loads statistics and featured characters concurrently.
  Future<void> loadHomeData() async {
    await Future.wait([
      loadStatistics(),
      loadFeaturedCharacters(),
    ]);
  }

  /// Loads show statistics independently.
  Future<void> loadStatistics() async {
    emit(state.copyWith(isLoadingStats: true, clearStatsError: true));
    try {
      final stats = await _showRepository.getStatistics();
      emit(state.copyWith(isLoadingStats: false, statistics: stats));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Home stats load error: $e\n$st');
      }
      emit(
        state.copyWith(
          isLoadingStats: false,
          statsError: 'Unable to load show stats',
        ),
      );
    }
  }

  /// Loads featured characters independently.
  Future<void> loadFeaturedCharacters() async {
    emit(state.copyWith(isLoadingFeatured: true, clearFeaturedError: true));
    try {
      final characters = await _showRepository.getFeaturedCharacters();
      emit(
        state.copyWith(
          isLoadingFeatured: false,
          featuredCharacters: characters,
        ),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Featured characters load error: $e\n$st');
      }
      emit(
        state.copyWith(
          isLoadingFeatured: false,
          featuredError: 'Unable to load featured characters',
        ),
      );
    }
  }

  /// Picks a random character from the available featured characters.
  Character? getRandomCharacter() {
    if (state.featuredCharacters.isEmpty) return null;
    final index = _random.nextInt(state.featuredCharacters.length);
    return state.featuredCharacters[index];
  }
}
