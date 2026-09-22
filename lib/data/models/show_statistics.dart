/// Aggregated high-level show statistics derived from API metadata.
class ShowStatistics {
  const ShowStatistics({
    required this.totalCharacters,
    required this.totalLocations,
    required this.totalEpisodes,
    required this.totalSeasons,
  });

  final int totalCharacters;
  final int totalLocations;
  final int totalEpisodes;
  final int totalSeasons;
}
