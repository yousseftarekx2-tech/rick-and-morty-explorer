import 'package:flutter/foundation.dart';
import 'package:learn_bloc/data/models/model.dart';
import 'package:learn_bloc/data/models/show_statistics.dart';

@immutable
class HomeState {
  const HomeState({
    this.isLoadingStats = false,
    this.isLoadingFeatured = false,
    this.statistics,
    this.featuredCharacters = const [],
    this.statsError,
    this.featuredError,
  });

  final bool isLoadingStats;
  final bool isLoadingFeatured;
  final ShowStatistics? statistics;
  final List<Character> featuredCharacters;
  final String? statsError;
  final String? featuredError;

  HomeState copyWith({
    bool? isLoadingStats,
    bool? isLoadingFeatured,
    ShowStatistics? statistics,
    List<Character>? featuredCharacters,
    String? statsError,
    String? featuredError,
    bool clearStatsError = false,
    bool clearFeaturedError = false,
  }) {
    return HomeState(
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      isLoadingFeatured: isLoadingFeatured ?? this.isLoadingFeatured,
      statistics: statistics ?? this.statistics,
      featuredCharacters: featuredCharacters ?? this.featuredCharacters,
      statsError: clearStatsError ? null : (statsError ?? this.statsError),
      featuredError: clearFeaturedError ? null : (featuredError ?? this.featuredError),
    );
  }
}
