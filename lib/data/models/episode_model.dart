/// Represents an episode returned by the Rick and Morty API.
class Episode {
  const Episode({
    required this.id,
    required this.name,
    required this.airDate,
    required this.episodeCode,
  });

  final int id;
  final String name;
  final String airDate;
  final String episodeCode;

  int get seasonNumber {
    final match = RegExp(r'S(\d+)').firstMatch(episodeCode);
    return match != null ? int.tryParse(match.group(1) ?? '') ?? 1 : 1;
  }

  int get episodeNumber {
    final match = RegExp(r'E(\d+)').firstMatch(episodeCode);
    return match != null ? int.tryParse(match.group(1) ?? '') ?? 1 : 1;
  }

  factory Episode.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId = rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return Episode(
      id: parsedId,
      name: json['name']?.toString() ?? 'Unknown Episode',
      airDate: json['air_date']?.toString() ?? 'Unknown date',
      episodeCode: json['episode']?.toString() ?? '',
    );
  }
}
