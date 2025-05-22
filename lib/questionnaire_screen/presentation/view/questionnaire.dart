import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hand_write_notes/information_screen/data/child_info_model.dart';
import 'package:hand_write_notes/information_screen/presentation/view/widgets/colorful_background.dart';
import 'package:hand_write_notes/signature_screen/presentation/view/signature_screen.dart';
import '../../../update_patient_state_cubit/cubit/update_patient_state_cubit.dart';
import '../../data/questionnaire_model.dart';
import 'widgets/question_item.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen(
      {super.key,
      required this.patientInfo,
      required this.isNavigateFromVisitScreen,
      required this.answers});
  final PatientInfo patientInfo;
  final bool isNavigateFromVisitScreen;
  final List<QuestionnaireModel> answers;

  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  late List<QuestionnaireModel> copyQuestionnaireList;
  @override
  void initState() {
    if (widget.isNavigateFromVisitScreen) {
      // questionnaire = copyQuestionnaireList = List.generate(
      //   questionnaire.length,
      //   (index) {
      //     // Use the question from questionnaire and the answer from answers list
      //     index < widget.answers.length ? widget.answers[index] : null;
      //     return QuestionnaireModel(
      //       question: questionnaire[index].question,
      //       answer: widget.answers[index].answer,
      //     );
      //   },
      // );

      questionnaire = List.generate(
        questionnaire.length,
        (index) => QuestionnaireModel(
          question: questionnaire[index].question,
          answer: widget.answers.isNotEmpty && index < widget.answers.length
              ? widget.answers[index].answer
              : null,
        ),
      );

      copyQuestionnaireList = List.generate(
        questionnaire.length,
        (index) => QuestionnaireModel(
          question: questionnaire[index].question,
          answer: questionnaire[index].answer,
        ),
      );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var updateCubit = BlocProvider.of<UpdatePatientStateCubit>(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        clipBehavior: Clip.none,
        title: const Text('Health Questionnaire'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(padding: const EdgeInsets.all(20),
              shrinkWrap: true,
              itemCount: questionnaire.length,
              itemBuilder: (context, index) {
                return QuestionItem(
                  questionModel: questionnaire[index],
                  onChanged: (bool? value) {
                    setState(() {
                      questionnaire[index].answer = value;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          BlocListener<UpdatePatientStateCubit, UpdatePatientStateState>(
        listener: (context, state) {
          if (state is UpdatePatientStateSuccess) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Updated Successfully'),
              ),
            );
          } else if (state is UpdatePatientStateFaild) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update patient data'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please wait....'),
              ),
            );
          }
        },
        child: FloatingActionButton(
          onPressed: () async {

            if (!widget.isNavigateFromVisitScreen) {
              bool allAnswered = questionnaire.every((q) => q.answer != null);
              //if (allAnswered) {
                Map<String, bool?> questionAnswerMap = {
                  for (var q in questionnaire) q.question: q.answer
                };
                // Create a new list of QuestionnaireModel with updated data
                List<QuestionnaireModel> updatedQuestionnaire =
                    questionAnswerMap.entries.map((entry) {
                  return QuestionnaireModel(
                      question: entry.key, answer: entry.value);
                }).toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignatureScreen(
                      childInfo: widget.patientInfo,
                      questionnaireModel: updatedQuestionnaire,
                    ),
                  ),
                );
              //} 
              // else {
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     const SnackBar(
              //       content: Text(
              //         'Please answer all questions',
              //       ),
              //     ),
              //   );
              // }
            } else {
              if (areAnswersDifferent()) {
                String qAndA = questionnaire.asMap().entries.map((entry) {
                  int index = entry.key + 1; // Index for Q1, Q2, etc.
                  int answer = entry.value.answer.toString() == "true"
                      ? 1
                      : 0; // Handle null answers
                  return 'Q$index = $answer';
                }).join(', ');
                // Update the questionnaire list with the latest answers
                await updateCubit.updatePatient(
                  "UPDATE Patients_Questionnaire SET $qAndA WHERE Patient_Id=${widget.patientInfo.patientId}",
                );
              } else {
                Navigator.pop(context);
              }
            }
          },
          child: const Icon(Icons.navigate_next_outlined),
        ),
      ),
    );
  }

  bool areAnswersDifferent() {
    if (questionnaire.length != copyQuestionnaireList.length) return true;

    for (int i = 0; i < questionnaire.length; i++) {
      if (questionnaire[i].answer != copyQuestionnaireList[i].answer) {
        return true;
      }
    }
    return false;
  }

  List<QuestionnaireModel> questionnaire = [
    QuestionnaireModel(question: 'Is your child in good health?'),
    QuestionnaireModel(
        question: 'Has your child ever had any operations or illnesses?'),
    QuestionnaireModel(
        question: 'Has your child ever had a general anaesthetic?'),
    QuestionnaireModel(
        question:
            'Is your child allergic to any antibiotics or any other drugs/medicines/foods?'),
    QuestionnaireModel(
        question:
            'Has your child ever had excessive bleeding requiring special treatment?'),
    QuestionnaireModel(
        question: 'Is there any family history of excessive bleeding?'),
    QuestionnaireModel(question: 'Heart problems/murmur/high blood pressure?'),
    QuestionnaireModel(question: 'Asthma/hay fever/eczema or other allergies?'),
    QuestionnaireModel(question: 'Chest problems/shortness of breath?'),
    QuestionnaireModel(question: 'Anaemia/sickle cell or thalassaemia?'),
    QuestionnaireModel(question: 'Epilepsy/fits/fainting attacks?'),
    QuestionnaireModel(question: 'Diabetes/thyroid problems?'),
    QuestionnaireModel(question: 'Jaundice/hepatitis or liver problems?'),
    QuestionnaireModel(
        question:
            'Is your child taking any medicines, tablets, drugs, or using any skin creams?'),
  ];
}

class DecoratedQuestionnaireScreen extends StatefulWidget {
  const DecoratedQuestionnaireScreen({
    super.key,
    required this.childInfo,
    required this.isNavigateFromVisitScreen,
    required this.answers,
  });
  final PatientInfo childInfo;
  final bool isNavigateFromVisitScreen;
  final List<QuestionnaireModel> answers;

  @override
  State<DecoratedQuestionnaireScreen> createState() =>
      _QuestionnaireScreen1State();
}

class _QuestionnaireScreen1State extends State<DecoratedQuestionnaireScreen> {
  @override
  Widget build(BuildContext context) {
    return ColorfulBackground(
      child: QuestionnaireScreen(
        patientInfo: widget.childInfo,
        isNavigateFromVisitScreen:
            widget.isNavigateFromVisitScreen ? true : false,
        answers: widget.isNavigateFromVisitScreen ? widget.answers : const [],
      ),
    );
  }
}
