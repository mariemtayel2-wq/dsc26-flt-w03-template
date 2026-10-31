// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:dsc26_flt_w03/data/services/api_failure.dart' as ApiFailure;
import 'package:dsc26_flt_w03/utils/result.dart' as Result;
import 'package:http/http.dart' as http;

import '../../domain/models/question.dart';

/// One call to the Masaraat questions API. Holds no state and never retries.
///
/// Keep the constructor and the signature of [fetchNext] exactly.
class QuestionApi {
  QuestionApi({
    required http.Client client,
    required Uri baseUrl,
    Duration timeout = const Duration(seconds: 10),
  })  : _client = client,
        _baseUrl = baseUrl,
        _timeout = timeout;

  final http.Client _client;
  final Uri _baseUrl;
  final Duration _timeout;

  /// `GET {baseUrl}/v1/students/{studentId}/next-questions?limit={limit}`.
  Future<Result.Result<List<Question>>> fetchNext({
    required String studentId,
    int limit = 10,
  }) async {
    // 1. Validate limit before any request is sent (Programming error -> throws ArgumentError)
    if (limit < 1 || limit > 50) {
      throw ArgumentError.value(limit, 'limit', 'Limit must be between 1 and 50');
    }

    // 2. Build URL safely using replace and keeping base path/segments
    final segments = List<String>.from(_baseUrl.pathSegments)
      ..removeWhere((s) => s.isEmpty);
    segments.addAll(['v1', 'students', studentId, 'next-questions']);

    final url = _baseUrl.replace(
      pathSegments: segments,
      queryParameters: {'limit': limit.toString()},
    );

    try {
      final response = await _client.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);

      // 3. Status mapping
      if (response.statusCode == 200) {
        try {
          // Decode bytes as UTF-8 ignoring incorrect headers
          final jsonString = utf8.decode(response.bodyBytes);
          final data = jsonDecode(jsonString);

          if (data is! Map<String, dynamic> || data['questions'] is! List) {
            return Result.Err(ApiFailure.BadResponse('Top-level object or questions list missing'));
          }

          final questionsList = data['questions'] as List;
          final List<Question> parsedQuestions = [];

          for (var item in questionsList) {
            if (item is! Map<String, dynamic>) {
              return Result.Err(ApiFailure.BadResponse('Question item is not a valid map'));
            }

            // استخدام Question.fromJson للتحليل والتحقق من الشروط
            parsedQuestions.add(Question.fromJson(item));
          }

          return Result.Ok(parsedQuestions);
        } on FormatException catch (e) {
          return Result.Err(ApiFailure.BadResponse(e.message));
        } catch (e) {
          return Result.Err(ApiFailure.BadResponse(e.toString()));
        }
      } else if (response.statusCode == 401) {
        return const Result.Err(ApiFailure.Unauthorized()); 
      } else if (response.statusCode == 404) {
        return const Result.Err(ApiFailure.NotFound());
      } else if (response.statusCode == 429) {
        final retryHeader = response.headers['retry-after'];
        final retryAfterSeconds = _parseRetryAfter(retryHeader);
        return Result.Err(ApiFailure.RateLimited(Duration(seconds: retryAfterSeconds)));
      } else if (response.statusCode >= 500 && response.statusCode <= 599) {
        return Result.Err(ApiFailure.ServerError(response.statusCode));
      } else {
        return Result.Err(ApiFailure.UnexpectedStatus(response.statusCode));
      }
    } on http.ClientException {
      return const Result.Err(ApiFailure.Offline());
    } on TimeoutException {
      return const Result.Err(ApiFailure.TimedOut());
    } catch (_) {
      return const Result.Err(ApiFailure.Offline());
    }
  }

  int _parseRetryAfter(String? value) {
    if (value == null || !RegExp(r'^(0|[1-9]\d*)$').hasMatch(value)) {
      return 5;
    }
    return int.tryParse(value) ?? 5;
  }
}