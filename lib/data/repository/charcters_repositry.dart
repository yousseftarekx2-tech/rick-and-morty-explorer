import 'package:learn_bloc/data/models/model.dart';
import 'package:learn_bloc/data/web_services/api.dart';

class CharactersRepository {
  final CharacterApi characterApi;

  const CharactersRepository(this.characterApi);

  /// Fetches a single page of characters and pagination metadata.
  Future<CharacterPage> getCharactersPage({int page = 1, String? nextUrl}) async {
    final pageData = await characterApi.getCharactersPage(
      page: page,
      url: nextUrl,
    );

    final rawResults = pageData['results'];
    final characters = (rawResults is List)
        ? rawResults
            .whereType<Map>()
            .map((m) => Character.fromJson(Map<String, dynamic>.from(m)))
            .toList(growable: false)
        : const <Character>[];

    final info = pageData['info'];
    final next = (info is Map) ? info['next']?.toString() : null;
    final totalCount = (info is Map && info['count'] is num)
        ? (info['count'] as num).toInt()
        : characters.length;
    final totalPages = (info is Map && info['pages'] is num)
        ? (info['pages'] as num).toInt()
        : 1;

    return CharacterPage(
      characters: characters,
      nextUrl: next,
      totalCount: totalCount,
      totalPages: totalPages,
    );
  }

  /// Fetches all characters across all pages.
  Future<List<Character>> getAllCharacters() async {
    final characters = await characterApi.getAllCharacters();
    return characters.map(Character.fromJson).toList(growable: false);
  }
}
