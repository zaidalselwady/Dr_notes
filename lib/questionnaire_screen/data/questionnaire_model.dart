class QuestionnaireModel {
  final String question;
  bool?
      answer; // Nullable boolean to represent Yes/No (null means not answered)

  // Factory constructor to create from database response
  factory QuestionnaireModel.fromDb(String question, int answer) {
    return QuestionnaireModel(
      question: question,
      answer: answer == 1 ? true : false, // Convert 1/0 to true/false
    );
  }

  QuestionnaireModel({required this.question, this.answer});
  @override
  String toString() {
    return 'QuestionnaireModel(question: $question, answer: $answer)';
  }
}
