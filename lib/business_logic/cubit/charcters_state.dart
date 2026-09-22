part of 'charcters_cubit.dart';

/// Defines filtering criteria for characters.
@immutable
class CharacterFilter {
  const CharacterFilter({
    this.status,
    this.species,
    this.location,
  });

  final String? status;
  final String? species;
  final String? location;

  bool get isActive =>
      (status != null && status != 'All') ||
      (species != null && species != 'All') ||
      (location != null && location!.isNotEmpty && location != 'All');

  int get activeCount {
    var count = 0;
    if (status != null && status != 'All') count++;
    if (species != null && species != 'All') count++;
    if (location != null && location!.isNotEmpty && location != 'All') count++;
    return count;
  }

  CharacterFilter copyWith({
    String? status,
    bool clearStatus = false,
    String? species,
    bool clearSpecies = false,
    String? location,
    bool clearLocation = false,
  }) {
    return CharacterFilter(
      status: clearStatus ? null : (status ?? this.status),
      species: clearSpecies ? null : (species ?? this.species),
      location: clearLocation ? null : (location ?? this.location),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterFilter &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          species == other.species &&
          location == other.location;

  @override
  int get hashCode => Object.hash(status, species, location);
}

@immutable
sealed class CharctersState {
  const CharctersState();
}

final class CharctersInitial extends CharctersState {
  const CharctersInitial();
}

final class CharctersLoading extends CharctersState {
  const CharctersLoading();
}

final class CharctersSuccess extends CharctersState {
  const CharctersSuccess(
    this.allCharacters, {
    List<Character>? displayedCharacters,
    this.searchQuery = '',
    this.filter = const CharacterFilter(),
    this.hasMore = false,
    this.isLoadingMore = false,
    this.paginationError,
  }) : displayedCharacters = displayedCharacters ?? allCharacters;

  /// The master catalog of all characters loaded across all pages so far.
  final List<Character> allCharacters;

  /// The filtered and ranked subset displayed in the grid.
  final List<Character> displayedCharacters;

  /// Active search query (case-insensitive local search).
  final String searchQuery;

  /// Active filter criteria.
  final CharacterFilter filter;

  final bool hasMore;
  final bool isLoadingMore;
  final String? paginationError;

  bool get isSearchActive => searchQuery.trim().isNotEmpty;
  bool get isFilterActive => filter.isActive;
  bool get hasFiltersOrSearch => isSearchActive || isFilterActive;

  /// Available locations dynamically extracted and sorted from currently loaded characters.
  List<String> get availableLocations {
    final names = allCharacters
        .map((c) => c.location.name.trim())
        .where((name) => name.isNotEmpty && name.toLowerCase() != 'unknown')
        .toSet()
        .toList();
    names.sort();
    return names;
  }

  CharctersSuccess copyWith({
    List<Character>? allCharacters,
    List<Character>? displayedCharacters,
    String? searchQuery,
    CharacterFilter? filter,
    bool? hasMore,
    bool? isLoadingMore,
    String? paginationError,
    bool clearPaginationError = false,
  }) {
    return CharctersSuccess(
      allCharacters ?? this.allCharacters,
      displayedCharacters: displayedCharacters ?? this.displayedCharacters,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      paginationError: clearPaginationError ? null : (paginationError ?? this.paginationError),
    );
  }
}

final class CharctersEmpty extends CharctersState {
  const CharctersEmpty();
}

final class CharctersFailure extends CharctersState {
  const CharctersFailure(this.message);
  final String message;
}
