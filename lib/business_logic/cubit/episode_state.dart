import 'package:flutter/foundation.dart';
import 'package:learn_bloc/data/models/episode_model.dart';

@immutable
sealed class EpisodeState {
  const EpisodeState();
}

final class EpisodeInitial extends EpisodeState {
  const EpisodeInitial();
}

final class EpisodeLoading extends EpisodeState {
  const EpisodeLoading();
}

final class EpisodeSuccess extends EpisodeState {
  const EpisodeSuccess(this.episodes);
  final List<Episode> episodes;
}

final class EpisodeFailure extends EpisodeState {
  const EpisodeFailure(this.message);
  final String message;
}
