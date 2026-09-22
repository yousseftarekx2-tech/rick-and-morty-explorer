import 'package:learn_bloc/data/models/episode_model.dart';
import 'package:learn_bloc/data/models/model.dart';
import 'package:learn_bloc/data/web_services/show_api.dart';

class EpisodesRepository {
  EpisodesRepository(this._showApi);

  final ShowApi _showApi;

  /// Fetches episode details for the given character on demand.
  Future<List<Episode>> getEpisodesForCharacter(Character character) async {
    final ids = character.episode.map((url) {
      final segments = url.split('/').where((s) => s.isNotEmpty).toList();
      return segments.isNotEmpty ? int.tryParse(segments.last) : null;
    }).whereType<int>().toList();

    if (ids.isEmpty) return const [];

    final rawList = await _showApi.getEpisodesByIds(ids);
    return rawList.map(Episode.fromJson).toList(growable: false);
  }
}
