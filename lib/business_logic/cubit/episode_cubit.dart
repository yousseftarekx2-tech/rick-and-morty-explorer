import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_bloc/business_logic/cubit/episode_state.dart';
import 'package:learn_bloc/data/models/model.dart';
import 'package:learn_bloc/data/repository/episodes_repository.dart';

class EpisodeCubit extends Cubit<EpisodeState> {
  EpisodeCubit(this._episodesRepository) : super(const EpisodeInitial());

  final EpisodesRepository _episodesRepository;

  /// Loads the episode details for the given character on demand.
  Future<void> loadEpisodes(Character character) async {
    if (state is EpisodeLoading) return;
    emit(const EpisodeLoading());

    try {
      final episodes = await _episodesRepository.getEpisodesForCharacter(character);
      emit(EpisodeSuccess(episodes));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Failed to load episodes: $e\n$st');
      }
      emit(const EpisodeFailure('Unable to load episode details. Tap to retry.'));
    }
  }
}
