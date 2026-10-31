/// One practice question chosen for a student by the Masaraat backend.
final class Question {
  const Question({
    required this.id,
    required this.skillId,
    required this.stem,
    required this.choices,
  });

  final String id;
  final String skillId;
  final String stem;
  final List<String> choices;

  /// Reads one question from the API. Unknown fields are ignored.
  ///
  /// TODO(W3): throw a FormatException for a missing or wrongly typed field,
  /// or when `choices` is not a list of 2 to 6 non-empty strings.
  factory Question.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final skillId = json['skillId'];
    final stem = json['stem'];
    final choices = json['choices'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Missing or empty id');
    }
    if (skillId is! String || skillId.isEmpty) {
      throw const FormatException('Missing or empty skillId');
    }
    if (stem is! String || stem.isEmpty) {
      throw const FormatException('Missing or empty stem');
    }
    if (choices is! List || choices.length < 2 || choices.length > 6) {
      throw const FormatException('Missing or empty choices');
    }

    final List<String> parsedChoices = [];
    for (final choice in choices) {
      if (choice is! String || choice.isEmpty) {
        throw const FormatException('Invalid choice item');
      }
      parsedChoices.add(choice);
    }

    return Question(
      id: id,
      skillId: skillId,
      stem: stem,
      choices: parsedChoices,
    );
  }

  
}
