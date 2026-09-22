import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:learn_bloc/consteins/strings.dart';

class CharacterApi {
  CharacterApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
              ),
            ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('Rick & Morty request: ${options.method} ${options.uri}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('Rick & Morty response: ${response.statusCode} ${response.requestOptions.uri}');
            handler.next(response);
          },
          onError: (error, handler) {
            debugPrint('Rick & Morty Dio error: ${error.type} - ${error.message}');
            debugPrint('Rick & Morty error URL: ${error.requestOptions.uri}');
            debugPrint('Rick & Morty error status: ${error.response?.statusCode}');
            handler.next(error);
          },
        ),
      );
    }
  }

  final Dio _dio;

  /// Fetches a single page of characters.
  /// If [url] is provided (e.g. from `info.next`), it is requested directly.
  /// Otherwise, it fetches 'character' with query parameter `page: page`.
  Future<Map<String, dynamic>> getCharactersPage({int page = 1, String? url}) async {
    final Response<dynamic> response;
    if (url != null && url.isNotEmpty) {
      response = await _dio.get<dynamic>(url);
    } else {
      response = await _dio.get<dynamic>(
        'character',
        queryParameters: {'page': page},
      );
    }

    final data = response.data;
    if (data == null) {
      throw const FormatException('The API returned an empty response.');
    }
    if (data is! Map) {
      throw const FormatException('The API returned an unexpected response format.');
    }
    return Map<String, dynamic>.from(data);
  }

  /// Fetches every page. Note: for UI, prefer [getCharactersPage] to paginate incrementally.
  Future<List<Map<String, dynamic>>> getAllCharacters() async {
    final characters = <Map<String, dynamic>>[];
    String? nextUrl;
    var isFirst = true;

    while (isFirst || nextUrl != null) {
      final pageData = await getCharactersPage(
        url: isFirst ? null : nextUrl,
      );
      isFirst = false;

      final results = pageData['results'];
      if (results is List) {
        for (final item in results) {
          if (item is Map) {
            characters.add(Map<String, dynamic>.from(item));
          }
        }
      }
      final info = pageData['info'];
      nextUrl = info is Map ? info['next']?.toString() : null;
    }
    return characters;
  }
}
