/// A character returned by the Rick and Morty API.
class Character {
  const Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.type,
    required this.gender,
    required this.origin,
    required this.location,
    required this.image,
    required this.episode,
    required this.created,
  });

  final int id;
  final String name;
  final String status;
  final String species;
  final String type;
  final String gender;
  final CharacterPlace origin;
  final CharacterPlace location;
  final String image;
  final List<String> episode;
  final String created;

  factory Character.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId = rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final rawOrigin = json['origin'];
    final originMap = rawOrigin is Map
        ? Map<String, dynamic>.from(rawOrigin)
        : const <String, dynamic>{};

    final rawLocation = json['location'];
    final locationMap = rawLocation is Map
        ? Map<String, dynamic>.from(rawLocation)
        : const <String, dynamic>{};

    final rawEpisode = json['episode'];
    final episodeList = rawEpisode is List
        ? rawEpisode.map((e) => e.toString()).toList()
        : const <String>[];

    return Character(
      id: parsedId,
      name: json['name']?.toString() ?? 'Unknown',
      status: json['status']?.toString() ?? 'Unknown',
      species: json['species']?.toString() ?? 'Unknown',
      type: json['type']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'Unknown',
      origin: CharacterPlace.fromJson(originMap),
      location: CharacterPlace.fromJson(locationMap),
      image: json['image']?.toString() ?? '',
      episode: episodeList,
      created: json['created']?.toString() ?? '',
    );
  }
}

class CharacterPlace {
  const CharacterPlace({required this.name, required this.url});

  final String name;
  final String url;

  factory CharacterPlace.fromJson(Map<String, dynamic> json) => CharacterPlace(
        name: json['name']?.toString() ?? 'Unknown',
        url: json['url']?.toString() ?? '',
      );
}

/// Represents a single paginated response from the Rick and Morty API.
class CharacterPage {
  const CharacterPage({
    required this.characters,
    this.nextUrl,
    required this.totalCount,
    required this.totalPages,
  });

  final List<Character> characters;
  final String? nextUrl;
  final int totalCount;
  final int totalPages;
}
