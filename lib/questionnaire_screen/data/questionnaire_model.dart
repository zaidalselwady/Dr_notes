class QuestionnaireModel {
  final String question;
  bool? answer; // Nullable boolean to represent Yes/No (null means not answered)
  String? note; // Optional note for additional information

  // Factory constructor to create from database response
  factory QuestionnaireModel.fromDb(String question, int? answer, String? note) {
    return QuestionnaireModel(
        question: question,
        answer: answer == null
            ? null
            : answer == 1
                ? true
                : false,
         note: note  // Convert 1/0 to true/false

        );
  }

  QuestionnaireModel({required this.question, this.answer, this.note});
  @override
  String toString() {
    return 'QuestionnaireModel(question: $question, answer: $answer)';
  }
}
