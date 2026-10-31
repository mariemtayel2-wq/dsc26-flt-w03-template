// ignore_for_file: prefer_initializing_formals

import 'package:dsc26_flt_w03/data/services/api_failure.dart' as ApiFailure;
import 'package:dsc26_flt_w03/utils/result.dart' as Result show Ok, Result, Err;

import '../../domain/models/question.dart';
import '../services/question_api.dart';

/// The source of truth for practice questions. Owns the retry policy.
///
/// Keep the constructor and the signature of [nextQuestions] exactly.
class PracticeRepository {
  PracticeRepository({
    required QuestionApi api,
    required Future<void> Function(Duration) sleep,
    int maxRetries = 2,
  })  : _api = api,
        _sleep = sleep,
        _maxRetries = maxRetries;

  final QuestionApi _api;
  final Future<void> Function(Duration) _sleep;
  final int _maxRetries;

  /// Retry transient failures at most maxRetries times, waiting
  /// 1 s, 2 s, ... (Retry-After for 429, capped at 30 s). Return permanent
  /// failures after one call.
  Future<Result.Result<List<Question>>> nextQuestions(String studentId) async {
    int attempts = 0;

    while (true) {
      final result = await _api.fetchNext(studentId: studentId);

      if (result is Result.Ok<List<Question>>) {
        return result;
      }

      if (result is Result.Err<List<Question>>) {
        final failure = result.failure;

        if (!failure.isTransient || attempts >= _maxRetries) {
          return result;
        }

        Duration sleepDuration;
        if (failure is ApiFailure.RateLimited) {
          sleepDuration = failure.retryAfter > const Duration(seconds: 30)
              ? const Duration(seconds: 30)
              : failure.retryAfter;
        } else {
          sleepDuration = Duration(seconds: 1 << attempts);
        }

        await _sleep(sleepDuration);
        attempts++;
      } else {
        return result;
      }
    }
  }
}