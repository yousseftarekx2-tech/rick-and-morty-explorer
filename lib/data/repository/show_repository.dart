import 'package:learn_bloc/data/models/model.dart';
import 'package:learn_bloc/data/models/show_statistics.dart';
import 'package:learn_bloc/data/web_services/show_api.dart';

class ShowRepository {
  ShowRepository(this._showApi);

  final ShowApi _showApi;

  /// Fetches show statistics derived from API metadata.
  Future<ShowStatistics> getStatistics() async {
    final counts = await _showApi.getMetadataCounts();
    return ShowStatistics(
      totalCharacters: counts['characters'] ?? 0,
      totalLocations: counts['locations'] ?? 0,
      totalEpisodes: counts['episodes'] ?? 0,
      totalSeasons: counts['seasons'] ?? 5,
    );
  }

  /// Fetches the featured main characters (Rick, Morty, Summer, Beth, Jerry).
  Future<List<Character>> getFeaturedCharacters() async {
    final rawList = await _showApi.getFeaturedCharacters(ids: [1, 2, 3, 4, 5]);
    return rawList.map(Character.fromJson).toList(growable: false);
  }
}
