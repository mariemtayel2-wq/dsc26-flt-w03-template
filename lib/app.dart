import 'package:flutter/material.dart';

import 'package:dsc26_flt_w03/data/repositories/practice_repository.dart';
import 'package:dsc26_flt_w03/data/services/api_failure.dart' as ApiFailure;
import 'package:dsc26_flt_w03/domain/models/question.dart';
import 'package:dsc26_flt_w03/utils/result.dart';

Widget buildPracticeApp({
  required PracticeRepository repository,
  String studentId = 'demo',
}) {
  return MaterialApp(
    home: PracticeScreen(repository: repository, studentId: studentId),
  );
}

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.repository,
    required this.studentId,
  });

  final PracticeRepository repository;
  final String studentId;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final PracticeState _state;

  @override
  void initState() {
    super.initState();
    _state = PracticeState(widget.repository, widget.studentId)..load();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, child) => Scaffold(
        appBar: AppBar(
          title: const Text('Practice'),
          actions: [
            IconButton(
              key: const Key('practice-refresh'),
              icon: const Icon(Icons.refresh),
              onPressed: _state.isLoading ? null : _state.load,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_state.isLoading &&
        _state.questions == null &&
        _state.failure == null) {
      return const Center(
        key: Key('practice-loading'),
        child: CircularProgressIndicator(),
      );
    }

    final failure = _state.failure;
    if (failure != null) {
      final isUnauthorized = failure is ApiFailure.Unauthorized;
      return Center(
        key: const Key('practice-error'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_friendlyMessage(failure), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                key: Key(
                  isUnauthorized ? 'practice-signin' : 'practice-retry',
                ),
                onPressed: _state.load,
                child: Text(isUnauthorized ? 'Sign In' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final questions = _state.questions;
    if (questions != null) {
      if (questions.isEmpty) {
        return const Center(
          key: Key('practice-empty'),
          child: Text("you have finished today's practice"),
        );
      }

      return ListView.builder(
        key: const Key('practice-list'),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          return ListTile(
            key: Key('question-${question.id}'),
            title: Text(question.stem),
            subtitle: Text('Choices: ${question.choices.join(', ')}'),
          );
        },
      );
    }

    return const Center(
      key: Key('practice-loading'),
      child: CircularProgressIndicator(),
    );
  }

  String _friendlyMessage(ApiFailure.ApiFailure failure) {
    if (failure is ApiFailure.Offline) {
      return 'No internet connection. Please check your network.';
    }
    if (failure is ApiFailure.TimedOut) {
      return 'The request took too long. Please try again.';
    }
    if (failure is ApiFailure.ServerError) {
      return 'A server error occurred. Please try again later.';
    }
    if (failure is ApiFailure.RateLimited) {
      return 'Too many requests. Please try again later.';
    }
    if (failure is ApiFailure.Unauthorized) {
      return 'Your session has expired. Please sign in again.';
    }
    if (failure is ApiFailure.NotFound) {
      return 'Requested resource was not found.';
    }
    if (failure is ApiFailure.BadResponse) {
      return 'Received unexpected data from the server.';
    }
    return 'An unexpected error occurred.';
  }
}

class PracticeState extends ChangeNotifier {
  PracticeState(this._repository, this._studentId);

  final PracticeRepository _repository;
  final String _studentId;

  bool isLoading = false;
  List<Question>? questions;
  ApiFailure.ApiFailure? failure;
  bool _disposed = false;

  Future<void> load() async {
    if (_disposed || isLoading) {
      return;
    }

    isLoading = true;
    failure = null;
    notifyListeners();

    final result = await _repository.nextQuestions(_studentId);
    if (_disposed) {
      return;
    }

    isLoading = false;
    if (result is Ok<List<Question>>) {
      questions = result.value;
      failure = null;
    } else if (result is Err<List<Question>>) {
      questions = null;
      failure = result.failure;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
