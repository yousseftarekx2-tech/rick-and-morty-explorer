import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:learn_bloc/consteins/strings.dart';

class ShowApi {
  ShowApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  final Dio _dio;

  /// Fetches metadata counts for characters, locations, and episodes concurrently.
  /// Derives season count from the last cataloged episode without downloading all episodes.
  Future<Map<String, int>> getMetadataCounts() async {
    try {
      final results = await Future.wait([
        _dio.get<Map<String, dynamic>>('character'),
        _dio.get<Map<String, dynamic>>('location'),
        _dio.get<Map<String, dynamic>>('episode'),
      ]);

      final charCount = (results[0].data?['info']?['count'] as num?)?.toInt() ?? 0;
      final locCount = (results[1].data?['info']?['count'] as num?)?.toInt() ?? 0;
      final epCount = (results[2].data?['info']?['count'] as num?)?.toInt() ?? 0;

      var seasons = 5; // default fallback
      if (epCount > 0) {
        try {
          final lastEpRes = await _dio.get<Map<String, dynamic>>('episode/$epCount');
          final epCode = lastEpRes.data?['episode']?.toString() ?? '';
          final match = RegExp(r'S(\d+)').firstMatch(epCode);
          if (match != null) {
            seasons = int.tryParse(match.group(1) ?? '') ?? seasons;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Failed to derive last season, using fallback: $e');
          }
        }
      }

      return {
        'characters': charCount,
        'locations': locCount,
        'episodes': epCount,
        'seasons': seasons,
      };
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Failed to fetch show metadata counts: $e\n$st');
      }
      rethrow;
    }
  }

  /// Fetches multiple characters by their IDs in a single request (e.g. /character/1,2,3,4,5).
  Future<List<Map<String, dynamic>>> getFeaturedCharacters({
    List<int> ids = const [1, 2, 3, 4, 5],
  }) async {
    if (ids.isEmpty) return const [];
    try {
      final response = await _dio.get<dynamic>('character/${ids.join(',')}');
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList(growable: false);
      }
      if (data is Map) {
        return [Map<String, dynamic>.from(data)];
      }
      return const [];
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Failed to fetch featured characters: $e\n$st');
      }
      rethrow;
    }
  }

  /// Fetches episodes by IDs in a single request (e.g. /episode/1,2,3).
  Future<List<Map<String, dynamic>>> getEpisodesByIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    try {
      final endpoint = ids.length == 1 ? 'episode/${ids.first}' : 'episode/${ids.join(',')}';
      final response = await _dio.get<dynamic>(endpoint);
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList(growable: false);
      }
      if (data is Map) {
        return [Map<String, dynamic>.from(data)];
      }
      return const [];
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Failed to fetch episodes by IDs: $e\n$st');
      }
      rethrow;
    }
  }
}
