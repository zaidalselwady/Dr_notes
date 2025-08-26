import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hand_write_notes/information_screen/data/child_info_model.dart';
import 'package:hand_write_notes/information_screen/presentation/view/widgets/colorful_background.dart';
import 'package:hand_write_notes/signature_screen/presentation/view/signature_screen.dart';
import '../../../update_patient_state_cubit/cubit/update_patient_state_cubit.dart';
import '../../data/questionnaire_model.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({
    super.key,
    required this.patientInfo,
    required this.isNavigateFromVisitScreen,
    required this.answers,
  });
  
  final PatientInfo patientInfo;
  final bool isNavigateFromVisitScreen;
  final List<QuestionnaireModel> answers;

  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  late List<QuestionnaireModel> copyQuestionnaireList;
  final List<TextEditingController> _noteControllers = [];

  // Define the default questions
  final List<String> _defaultQuestions = [
    'Is your child in good health?',
    'Has your child ever had any operations or illnesses?',
    'Has your child ever had a general anaesthetic?',
    'Is your child allergic to any antibiotics or any other drugs/medicines/foods?',
    'Has your child ever had excessive bleeding requiring special treatment?',
    'Is there any family history of excessive bleeding?',
    'Heart problems/murmur/high blood pressure?',
    'Asthma/hay fever/eczema or other allergies?',
    'Chest problems/shortness of breath?',
    'Anaemia/sickle cell or thalassaemia?',
    'Epilepsy/fits/fainting attacks?',
    'Diabetes/thyroid problems?',
    'Jaundice/hepatitis or liver problems?',
    'Is your child taking any medicines, tablets, drugs, or using any skin creams?',
  ];

  late List<QuestionnaireModel> questionnaire;

  @override
  void initState() {
    super.initState();
    _initializeQuestionnaire();
    _initializeNoteControllers();
  }

  void _initializeQuestionnaire() {
    if (widget.isNavigateFromVisitScreen && widget.answers.isNotEmpty) {
      // SCENARIO 2: Coming from visit screen with existing data
      questionnaire = widget.answers.map((answer) => 
        QuestionnaireModel(
          question: answer.question,
          answer: answer.answer,
          note: answer.note,
        )
      ).toList();
      
      // Create copy for comparison
      copyQuestionnaireList = widget.answers.map((answer) => 
        QuestionnaireModel(
          question: answer.question,
          answer: answer.answer,
          note: answer.note,
        )
      ).toList();
    } else {
      // SCENARIO 1: New patient - empty questionnaire with default questions
      questionnaire = _defaultQuestions.map((question) => 
        QuestionnaireModel(
          question: question,
          answer: null,
          note: null,
        )
      ).toList();
      
      // Create empty copy for comparison
      copyQuestionnaireList = _defaultQuestions.map((question) => 
        QuestionnaireModel(
          question: question,
          answer: null,
          note: null,
        )
      ).toList();
    }
  }

  void _initializeNoteControllers() {
    // Initialize controllers for each question
    for (int i = 0; i < questionnaire.length; i++) {
      final controller = TextEditingController();
      
      // If there's an existing note, set it in the controller
      if (questionnaire[i].note != null && questionnaire[i].note!.isNotEmpty) {
        controller.text = questionnaire[i].note!;
      }
      
      _noteControllers.add(controller);
    }
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    for (final controller in _noteControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showNoteDialog(int questionIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Note for Question ${questionIndex + 1}'),
          content: TextField(
            controller: _noteControllers[questionIndex],
            decoration: const InputDecoration(
              hintText: 'Enter your note here...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final noteText = _noteControllers[questionIndex].text.trim();
                  questionnaire[questionIndex].note = noteText.isEmpty ? null : noteText;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionItem(int index) {
    final question = questionnaire[index];
    final hasNote = question.note != null && question.note!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q${index + 1}: ${question.question}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Yes/No options
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool?>(
                    title: const Text('Yes'),
                    value: true,
                    groupValue: question.answer,
                    onChanged: (value) {
                      setState(() {
                        questionnaire[index].answer = value;
                        // Don't clear existing note when selecting Yes
                      });
                    },
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool?>(
                    title: const Text('No'),
                    value: false,
                    groupValue: question.answer,
                    onChanged: (value) {
                      setState(() {
                        questionnaire[index].answer = value;
                        // Clear note when selecting No
                        if (value == false) {
                          questionnaire[index].note = null;
                          _noteControllers[index].clear();
                        }
                      });
                    },
                    dense: true,
                  ),
                ),
              ],
            ),

            // Note section - only show if Yes is selected
            if (question.answer == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showNoteDialog(index),
                      icon: Icon(
                        hasNote ? Icons.edit_note : Icons.add_circle_outline,
                        color: hasNote ? Colors.green : Colors.blue,
                      ),
                      label: Text(
                        hasNote ? 'Edit Note' : 'Add Note',
                        style: TextStyle(
                          color: hasNote ? Colors.green : Colors.blue,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: hasNote ? Colors.green : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  if (hasNote) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          questionnaire[index].note = null;
                          _noteControllers[index].clear();
                        });
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Remove Note',
                    ),
                  ],
                ],
              ),

              // Show preview of note if exists
              if (hasNote) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    question.note!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var updateCubit = BlocProvider.of<UpdatePatientStateCubit>(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        clipBehavior: Clip.none,
        title: Text(
          widget.isNavigateFromVisitScreen 
            ? 'Update Health Questionnaire' 
            : 'New Health Questionnaire'
        ),
      ),
      body: Column(
        children: [
          // Show helpful text based on scenario
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isNavigateFromVisitScreen ? Colors.blue[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isNavigateFromVisitScreen ? Colors.blue[200]! : Colors.green[200]!,
              ),
            ),
            child: Text(
              widget.isNavigateFromVisitScreen
                ? 'Review and update the existing questionnaire responses and notes.'
                : 'Please answer all questions. Add notes for any "Yes" responses if needed.',
              style: TextStyle(
                color: widget.isNavigateFromVisitScreen ? Colors.blue[700] : Colors.green[700],
                fontSize: 14,
              ),
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // Space for FAB
              itemCount: questionnaire.length,
              itemBuilder: (context, index) {
                return _buildQuestionItem(index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: BlocListener<UpdatePatientStateCubit, UpdatePatientStateState>(
        listener: (context, state) {
          if (state is UpdatePatientStateSuccess) {
            Navigator.pop(context, true); // Return true to indicate success
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Updated Successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is UpdatePatientStateFaild) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update patient data'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is UpdatingPatientState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Updating questionnaire...'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
        child: FloatingActionButton.extended(
          onPressed: () async {
            if (!widget.isNavigateFromVisitScreen) {
              // SCENARIO 1: New patient - navigate to signature screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SignatureScreen(
                    childInfo: widget.patientInfo,
                    questionnaireModel: questionnaire,
                  ),
                ),
              );
            } else {
              // SCENARIO 2: Existing patient - update questionnaire
              if (_hasChanges()) {
                String updateQuery = _buildUpdateQuery();
                await updateCubit.updatePatient(updateQuery,true);
              } else {
                // No changes, just go back
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No changes to save'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          },
          icon: Icon(
            widget.isNavigateFromVisitScreen ? Icons.save : Icons.navigate_next_outlined
          ),
          label: Text(
            widget.isNavigateFromVisitScreen ? 'Save Changes' : 'Continue'
          ),
        ),
      ),
    );
  }

  String _buildUpdateQuery() {
    List<String> updates = [];

    for (int i = 0; i < questionnaire.length; i++) {
      final questionNum = i + 1;
      final question = questionnaire[i];
      
      // Add answer update
      final answer = question.answer == null
          ? "NULL"
          : question.answer! ? "1" : "0";
      updates.add('Q$questionNum = $answer');

      // Add note update
      String noteValue;
      if (question.answer == true && question.note != null && question.note!.isNotEmpty) {
        final escapedNote = question.note!.replaceAll("'", "''");
        noteValue = "'$escapedNote'";
      } else {
        noteValue = "NULL";
      }
      updates.add('Q${questionNum}_Note = $noteValue');
    }

    return "UPDATE Patients_Questionnaire SET ${updates.join(', ')} WHERE Patient_Id=${widget.patientInfo.patientId}";
  }

  bool _hasChanges() {
    if (questionnaire.length != copyQuestionnaireList.length) return true;

    for (int i = 0; i < questionnaire.length; i++) {
      // Check if answer changed
      if (questionnaire[i].answer != copyQuestionnaireList[i].answer) {
        return true;
      }
      
      // Check if note changed
      if (questionnaire[i].note != copyQuestionnaireList[i].note) {
        return true;
      }
    }
    
    return false;
  }
}












// class QuestionnaireScreen extends StatefulWidget {
//   const QuestionnaireScreen(
//       {super.key,
//       required this.patientInfo,
//       required this.isNavigateFromVisitScreen,
//       required this.answers});
//   final PatientInfo patientInfo;
//   final bool isNavigateFromVisitScreen;
//   final List<QuestionnaireModel> answers;

//   @override
//   _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
// }

// class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
//   late List<QuestionnaireModel> copyQuestionnaireList;
//   final List<TextEditingController> _noteControllers = [];
//   final List<String?> _notes = [];

//   @override
//   void initState() {
//     super.initState();
//     widget.answers;
//     // Initialize note controllers and notes list
//     for (int i = 0; i < questionnaire.length; i++) {
//       _noteControllers.add(TextEditingController());
//       _notes.add(widget.answers[i].note);
//     }

//     if (widget.isNavigateFromVisitScreen) {
//       questionnaire = List.generate(
//         widget.answers.length,
//         (index) => QuestionnaireModel(
//           question: widget.answers[index].question,
//           answer: widget.answers.isNotEmpty && index < widget.answers.length
//               ? widget.answers[index].answer
//               : null,
//           note: widget.answers.isNotEmpty && index < widget.answers.length
//               ? widget.answers[index].note
//               : null,
//         ),
//       );

//       copyQuestionnaireList = List.generate(
//         widget.answers.length,
//         (index) => QuestionnaireModel(
//           question: widget.answers[index].question,
//           answer: widget.answers[index].answer,
//           note: widget.answers[index].note,
//         ),
//       );

//       // Initialize notes from existing data if available
//       // You might need to load existing notes from your API here
//       _loadExistingNotes();
//     }
//   }

//   @override
//   void dispose() {
//     // Dispose all controllers to prevent memory leaks
//     for (final controller in _noteControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }

//   Future<void> _loadExistingNotes() async {
//     // TODO: Load existing notes from your database
//     // This would be a new API call to fetch Q1_Note, Q2_Note, etc.
//     // For now, initialize with empty notes
//   }

//   void _showNoteDialog(int questionIndex) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Note for Question ${questionIndex + 1}'),
//           content: TextField(
//             controller: _noteControllers[questionIndex],
//             decoration: const InputDecoration(
//               hintText: 'Enter your note here...',
//               border: OutlineInputBorder(),
//             ),
//             maxLines: 4,
//             onChanged: (value) {
//               _notes[questionIndex] = value.isEmpty ? null : value;
//             },
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 setState(() {
//                   _notes[questionIndex] =
//                       _noteControllers[questionIndex].text.isEmpty
//                           ? null
//                           : _noteControllers[questionIndex].text;
//                 });
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Save'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildQuestionItem(int index) {
//     final question = questionnaire[index];
//     final hasNote =_notes.isNotEmpty && _notes[index] != null && _notes[index]!.isNotEmpty;

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Q${index + 1}: ${question.question}',
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 12),

//             // Yes/No/Not Answered options
//             Row(
//               children: [
//                 Expanded(
//                   child: RadioListTile<bool?>(
//                     title: const Text('Yes'),
//                     value: true,
//                     groupValue: question.answer,
//                     onChanged: (value) {
//                       setState(() {
//                         questionnaire[index].answer = value;
//                         // Clear note if answer is changed to No or null
//                         if (value != true) {
//                           _notes[index] = null;
//                           _noteControllers[index].clear();
//                         }
//                       });
//                     },
//                     dense: true,
//                   ),
//                 ),
//                 Expanded(
//                   child: RadioListTile<bool?>(
//                     title: const Text('No'),
//                     value: false,
//                     groupValue: question.answer,
//                     onChanged: (value) {
//                       setState(() {
//                         questionnaire[index].answer = value;
//                         // Clear note if answer is No
//                         _notes[index] = null;
//                         _noteControllers[index].clear();
//                       });
//                     },
//                     dense: true,
//                   ),
//                 ),
//               ],
//             ),

//             // Note section - only show if Yes is selected
//             if (question.answer == true) ...[
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () => _showNoteDialog(index),
//                       icon: Icon(
//                         hasNote ? Icons.edit_note : Icons.add_circle_outline,
//                         color: hasNote ? Colors.green : Colors.blue,
//                       ),
//                       label: Text(
//                         hasNote ? 'Edit Note' : 'Add Note',
//                         style: TextStyle(
//                           color: hasNote ? Colors.green : Colors.blue,
//                         ),
//                       ),
//                       style: OutlinedButton.styleFrom(
//                         side: BorderSide(
//                           color: hasNote ? Colors.green : Colors.blue,
//                         ),
//                       ),
//                     ),
//                   ),
//                   if (hasNote) ...[
//                     const SizedBox(width: 8),
//                     IconButton(
//                       onPressed: () {
//                         setState(() {
//                           _notes[index] = null;
//                           _noteControllers[index].clear();
//                         });
//                       },
//                       icon: const Icon(Icons.delete, color: Colors.red),
//                       tooltip: 'Remove Note',
//                     ),
//                   ],
//                 ],
//               ),

//               // Show preview of note if exists
//               if (hasNote) ...[
//                 const SizedBox(height: 8),
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.grey[300]!),
//                   ),
//                   child: Text(
//                     _notes[index]!,
//                     style: TextStyle(
//                       color: Colors.grey[700],
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     var updateCubit = BlocProvider.of<UpdatePatientStateCubit>(context);
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         clipBehavior: Clip.none,
//         title: const Text('Health Questionnaire'),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.symmetric(vertical: 20),
//               shrinkWrap: true,
//               itemCount: questionnaire.length,
//               itemBuilder: (context, index) {
//                 return _buildQuestionItem(index);
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton:
//           BlocListener<UpdatePatientStateCubit, UpdatePatientStateState>(
//         listener: (context, state) {
//           if (state is UpdatePatientStateSuccess) {
//             Navigator.pop(context);
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Updated Successfully'),
//                 backgroundColor: Colors.green,
//               ),
//             );
//           } else if (state is UpdatePatientStateFaild) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Failed to update patient data'),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Please wait....'),
//               ),
//             );
//           }
//         },
//         child: FloatingActionButton(
//           onPressed: () async {
//             if (!widget.isNavigateFromVisitScreen) {
//               // For new questionnaire
//               Map<String, bool?> questionAnswerMap = {
//                 for (var q in questionnaire) q.question: q.answer
//               };

//               List<QuestionnaireModel> updatedQuestionnaire =
//                   questionAnswerMap.entries.map((entry) {
//                 return QuestionnaireModel(
//                     question: entry.key, answer: entry.value);
//               }).toList();

//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => SignatureScreen(
//                     childInfo: widget.patientInfo,
//                     questionnaireModel: updatedQuestionnaire,
//                   ),
//                 ),
//               );
//             } else {
//               // For updating existing questionnaire
//               if (areAnswersDifferent() || areNotesDifferent()) {
//                 String updateQuery = _buildUpdateQuery();
//                 await updateCubit.updatePatient(
//                   updateQuery,
//                 );
//               } else {
//                 Navigator.pop(context);
//               }
//             }
//           },
//           child: const Icon(Icons.navigate_next_outlined),
//         ),
//       ),
//     );
//   }

//   String _buildUpdateQuery() {
//     List<String> updates = [];

//     // Build answer updates
//     for (int i = 0; i < questionnaire.length; i++) {
//       final questionNum = i + 1;
//       final answer = questionnaire[i].answer == null
//           ? "NULL"
//           : questionnaire[i].answer == true
//               ? "1"
//               : "0";
//       updates.add('Q$questionNum = $answer');

//       // Build note updates
//       final note = questionnaire[i].answer == true &&
//               _notes[i] != null &&
//               _notes[i]!.isNotEmpty
//           ? "'${_notes[i]!.replaceAll("'", "''")}'" // Escape single quotes
//           : "NULL";
//       updates.add('Q${questionNum}_Note = $note');
//     }

//     return "UPDATE Patients_Questionnaire SET ${updates.join(', ')} WHERE Patient_Id=${widget.patientInfo.patientId}";
//   }

//   bool areAnswersDifferent() {
//     if (questionnaire.length != copyQuestionnaireList.length) return true;

//     for (int i = 0; i < questionnaire.length; i++) {
//       if (questionnaire[i].answer != copyQuestionnaireList[i].answer) {
//         return true;
//       }
//     }
//     return false;
//   }

//   bool areNotesDifferent() {
//     // This would need to compare with original notes from database
//     // For now, assume any note changes require update
//     return _notes.any((note) => note != null && note.isNotEmpty);
//   }

//   List<QuestionnaireModel> questionnaire = [
//     QuestionnaireModel(question: 'Is your child in good health?'),
//     QuestionnaireModel(
//         question: 'Has your child ever had any operations or illnesses?'),
//     QuestionnaireModel(
//         question: 'Has your child ever had a general anaesthetic?'),
//     QuestionnaireModel(
//         question:
//             'Is your child allergic to any antibiotics or any other drugs/medicines/foods?'),
//     QuestionnaireModel(
//         question:
//             'Has your child ever had excessive bleeding requiring special treatment?'),
//     QuestionnaireModel(
//         question: 'Is there any family history of excessive bleeding?'),
//     QuestionnaireModel(question: 'Heart problems/murmur/high blood pressure?'),
//     QuestionnaireModel(question: 'Asthma/hay fever/eczema or other allergies?'),
//     QuestionnaireModel(question: 'Chest problems/shortness of breath?'),
//     QuestionnaireModel(question: 'Anaemia/sickle cell or thalassaemia?'),
//     QuestionnaireModel(question: 'Epilepsy/fits/fainting attacks?'),
//     QuestionnaireModel(question: 'Diabetes/thyroid problems?'),
//     QuestionnaireModel(question: 'Jaundice/hepatitis or liver problems?'),
//     QuestionnaireModel(
//         question:
//             'Is your child taking any medicines, tablets, drugs, or using any skin creams?'),
//   ];
// }

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

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import 'package:hand_write_notes/information_screen/data/child_info_model.dart';
// import 'package:hand_write_notes/information_screen/presentation/view/widgets/colorful_background.dart';
// import 'package:hand_write_notes/signature_screen/presentation/view/signature_screen.dart';
// import '../../../update_patient_state_cubit/cubit/update_patient_state_cubit.dart';
// import '../../data/questionnaire_model.dart';
// import 'widgets/question_item.dart';

// class QuestionnaireScreen extends StatefulWidget {
//   const QuestionnaireScreen(
//       {super.key,
//       required this.patientInfo,
//       required this.isNavigateFromVisitScreen,
//       required this.answers});
//   final PatientInfo patientInfo;
//   final bool isNavigateFromVisitScreen;
//   final List<QuestionnaireModel> answers;

//   @override
//   _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
// }

// class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
//   late List<QuestionnaireModel> copyQuestionnaireList;
//   @override
//   void initState() {
//     if (widget.isNavigateFromVisitScreen) {
//       // questionnaire = copyQuestionnaireList = List.generate(
//       //   questionnaire.length,
//       //   (index) {
//       //     // Use the question from questionnaire and the answer from answers list
//       //     index < widget.answers.length ? widget.answers[index] : null;
//       //     return QuestionnaireModel(
//       //       question: questionnaire[index].question,
//       //       answer: widget.answers[index].answer,
//       //     );
//       //   },
//       // );

//       questionnaire = List.generate(
//         questionnaire.length,
//         (index) => QuestionnaireModel(
//           question: questionnaire[index].question,
//           answer: widget.answers.isNotEmpty && index < widget.answers.length
//               ? widget.answers[index].answer
//               : null,
//         ),
//       );

//       copyQuestionnaireList = List.generate(
//         questionnaire.length,
//         (index) => QuestionnaireModel(
//           question: questionnaire[index].question,
//           answer: questionnaire[index].answer,
//         ),
//       );
//     }
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     var updateCubit = BlocProvider.of<UpdatePatientStateCubit>(context);
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         clipBehavior: Clip.none,
//         title: const Text('Health Questionnaire'),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(20),
//               shrinkWrap: true,
//               itemCount: questionnaire.length,
//               itemBuilder: (context, index) {
//                 return QuestionItem(
//                   questionModel: questionnaire[index],
//                   onChanged: (bool? value) {
//                     setState(() {
//                       questionnaire[index].answer = value;
//                     });
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton:
//           BlocListener<UpdatePatientStateCubit, UpdatePatientStateState>(
//         listener: (context, state) {
//           if (state is UpdatePatientStateSuccess) {
//             Navigator.pop(context);
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Updated Successfully'),
//               ),
//             );
//           } else if (state is UpdatePatientStateFaild) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Failed to update patient data'),
//               ),
//             );
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Please wait....'),
//               ),
//             );
//           }
//         },
//         child: FloatingActionButton(
//           onPressed: () async {
//             if (!widget.isNavigateFromVisitScreen) {
//               bool allAnswered = questionnaire.every((q) => q.answer != null);
//               //if (allAnswered) {
//               Map<String, bool?> questionAnswerMap = {
//                 for (var q in questionnaire) q.question: q.answer
//               };
//               // Create a new list of QuestionnaireModel with updated data
//               List<QuestionnaireModel> updatedQuestionnaire =
//                   questionAnswerMap.entries.map((entry) {
//                 return QuestionnaireModel(
//                     question: entry.key, answer: entry.value);
//               }).toList();

//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => SignatureScreen(
//                     childInfo: widget.patientInfo,
//                     questionnaireModel: updatedQuestionnaire,
//                   ),
//                 ),
//               );
//               //}
//               // else {
//               //   ScaffoldMessenger.of(context).showSnackBar(
//               //     const SnackBar(
//               //       content: Text(
//               //         'Please answer all questions',
//               //       ),
//               //     ),
//               //   );
//               // }
//             } else {
//               if (areAnswersDifferent()) {
//                 String qAndA = questionnaire.asMap().entries.map((entry) {
//                   int index = entry.key + 1; // Index for Q1, Q2, etc.
//                   final answer = entry.value.answer == null
//                       ? "NULL"
//                       : entry.value.answer == true
//                           ? 1
//                           : 0; // Handle null answers
//                   return 'Q$index = $answer';
//                 }).join(', ');
//                 // Update the questionnaire list with the latest answers
//                 await updateCubit.updatePatient(
//                   "UPDATE Patients_Questionnaire SET $qAndA WHERE Patient_Id=${widget.patientInfo.patientId}",
//                 );
//               } else {
//                 Navigator.pop(context);
//               }
//             }
//           },
//           child: const Icon(Icons.navigate_next_outlined),
//         ),
//       ),
//     );
//   }

//   bool areAnswersDifferent() {
//     if (questionnaire.length != copyQuestionnaireList.length) return true;

//     for (int i = 0; i < questionnaire.length; i++) {
//       if (questionnaire[i].answer != copyQuestionnaireList[i].answer) {
//         return true;
//       }
//     }
//     return false;
//   }

//   List<QuestionnaireModel> questionnaire = [
//     QuestionnaireModel(question: 'Is your child in good health?'),
//     QuestionnaireModel(
//         question: 'Has your child ever had any operations or illnesses?'),
//     QuestionnaireModel(
//         question: 'Has your child ever had a general anaesthetic?'),
//     QuestionnaireModel(
//         question:
//             'Is your child allergic to any antibiotics or any other drugs/medicines/foods?'),
//     QuestionnaireModel(
//         question:
//             'Has your child ever had excessive bleeding requiring special treatment?'),
//     QuestionnaireModel(
//         question: 'Is there any family history of excessive bleeding?'),
//     QuestionnaireModel(question: 'Heart problems/murmur/high blood pressure?'),
//     QuestionnaireModel(question: 'Asthma/hay fever/eczema or other allergies?'),
//     QuestionnaireModel(question: 'Chest problems/shortness of breath?'),
//     QuestionnaireModel(question: 'Anaemia/sickle cell or thalassaemia?'),
//     QuestionnaireModel(question: 'Epilepsy/fits/fainting attacks?'),
//     QuestionnaireModel(question: 'Diabetes/thyroid problems?'),
//     QuestionnaireModel(question: 'Jaundice/hepatitis or liver problems?'),
//     QuestionnaireModel(
//         question:
//             'Is your child taking any medicines, tablets, drugs, or using any skin creams?'),
//   ];
// }

// class DecoratedQuestionnaireScreen extends StatefulWidget {
//   const DecoratedQuestionnaireScreen({
//     super.key,
//     required this.childInfo,
//     required this.isNavigateFromVisitScreen,
//     required this.answers,
//   });
//   final PatientInfo childInfo;
//   final bool isNavigateFromVisitScreen;
//   final List<QuestionnaireModel> answers;

//   @override
//   State<DecoratedQuestionnaireScreen> createState() =>
//       _QuestionnaireScreen1State();
// }

// class _QuestionnaireScreen1State extends State<DecoratedQuestionnaireScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return ColorfulBackground(
//       child: QuestionnaireScreen(
//         patientInfo: widget.childInfo,
//         isNavigateFromVisitScreen:
//             widget.isNavigateFromVisitScreen ? true : false,
//         answers: widget.isNavigateFromVisitScreen ? widget.answers : const [],
//       ),
//     );
//   }
// }
